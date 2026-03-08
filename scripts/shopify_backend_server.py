#!/usr/bin/env python3
"""
Gemini-first discovery backend for local product alternatives.

Design goals:
- No local HTML parsing.
- URL and locale metadata are forwarded to Gemini for grounded understanding.
- Strict stage prioritizes local alternatives and category relevance.
- Relaxed stage broadens locality/type constraints when strict results are sparse.
- Safety filter only enforces policy and contract validity.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
import threading
import time
from dataclasses import dataclass
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any
from urllib import error, request
from urllib.parse import unquote, urlparse

DISCOVERY_PATH = "/discover-shopify-alternatives"
HEALTH_PATH = "/health"

CACHE_TTL_SECONDS = 10 * 60
MAX_RESULTS = 4
MIN_CONFIDENCE = 0.62
RATE_LIMIT_COOLDOWN_DEFAULT_SECONDS = 45.0
RATE_LIMIT_COOLDOWN_MIN_SECONDS = 10.0
RATE_LIMIT_COOLDOWN_MAX_SECONDS = 90.0

BLOCKED_MARKETPLACE_DOMAINS = {
    "amazon.com",
    "amazon.ca",
    "walmart.com",
    "walmart.ca",
    "target.com",
    "bestbuy.com",
    "bestbuy.ca",
    "ebay.com",
    "ebay.ca",
    "temu.com",
    "aliexpress.com",
    "alibaba.com",
}

BLOCKED_MARKETPLACE_KEYWORDS = {
    "amazon",
    "walmart",
    "target",
    "bestbuy",
    "best-buy",
    "ebay",
    "temu",
    "aliexpress",
    "alibaba",
}

# Explicitly blocked big-box retailers. Local/regional chains are allowed.
BLOCKED_BIGBOX_DOMAINS = {
    "bestbuy.com",
    "bestbuy.ca",
    "walmart.com",
    "walmart.ca",
    "target.com",
    "costco.com",
    "costco.ca",
    "homedepot.com",
    "homedepot.ca",
    "lowes.com",
    "lowes.ca",
}

BLOCKED_BIGBOX_NAME_KEYWORDS = {
    "best buy",
    "bestbuy",
    "walmart",
    "target",
    "costco",
    "home depot",
    "lowe",
}

# Known local/regional stores to boost over obscure shops.
PREFERRED_MERCHANTS_BY_COUNTRY: dict[str, dict[str, set[str]]] = {
    "CA": {
        "domains": {
            "canadacomputers.com",
            "memoryexpress.com",
            "mec.ca",
            "altitude-sports.com",
            "staples.ca",
            "newegg.ca",
        },
        "keywords": {
            "canada computers",
            "memory express",
            "mec",
            "altitude sports",
            "staples",
            "newegg",
        },
    },
    "US": {
        "domains": {
            "microcenter.com",
            "bhphotovideo.com",
            "adorama.com",
            "rei.com",
            "staples.com",
            "newegg.com",
        },
        "keywords": {
            "micro center",
            "b&h",
            "adorama",
            "rei",
            "staples",
            "newegg",
        },
    },
}

MERCHANT_TIER_SCORES = {
    "indie": 26.0,
    "local": 26.0,
    "regional": 16.0,
    "chain": 8.0,
    "national": -10.0,
    "unknown": 0.0,
}

NEARBY_COUNTRIES: dict[str, set[str]] = {
    "CA": {"US"},
    "US": {"CA"},
    "GB": {"IE", "FR", "DE", "NL"},
    "AU": {"NZ"},
    "NZ": {"AU"},
}

COUNTRY_BY_TLD = {
    "ca": "CA",
    "us": "US",
    "uk": "GB",
    "de": "DE",
    "fr": "FR",
    "it": "IT",
    "es": "ES",
    "au": "AU",
    "nz": "NZ",
    "jp": "JP",
}

CATEGORY_SIGNAL_TERMS: dict[str, set[str]] = {
    "audio": {"audio", "earbud", "earbuds", "headphone", "headphones", "speaker", "speakers", "soundbar"},
    "electronics": {
        "laptop",
        "laptops",
        "notebook",
        "notebooks",
        "ultrabook",
        "macbook",
        "chromebook",
        "pc",
        "computer",
        "computers",
        "workstation",
        "desktop",
    },
    "apparel": {"shirt", "hoodie", "jacket", "dress", "pant", "pants", "sneaker", "shoe", "shoes"},
    "beauty": {"makeup", "cosmetic", "cosmetics", "serum", "cleanser", "skincare", "lip"},
    "home": {"cookware", "kitchen", "furniture", "blanket", "bedding", "sheet", "mattress", "home"},
    "outdoors": {"backpack", "backpacks", "hiking", "camp", "camping", "trail", "daypack", "rucksack"},
}

MISMATCH_TERMS_FOR_ELECTRONICS = {
    "shirt",
    "hoodie",
    "jacket",
    "dress",
    "legging",
    "makeup",
    "serum",
    "cleanser",
    "sofa",
    "blanket",
    "backpack",
    "wallet",
}

STOPWORDS = {
    "the",
    "and",
    "for",
    "with",
    "from",
    "that",
    "this",
    "your",
    "our",
    "shop",
    "store",
    "product",
    "products",
    "new",
    "best",
    "sale",
    "official",
    "www",
    "com",
    "online",
    "collection",
    "collections",
    "localclip",
    "http",
    "https",
}


@dataclass
class CacheEntry:
    expires_at: float
    alternatives: list[dict[str, str]]
    meta: dict[str, Any]


@dataclass
class ContextEnvelope:
    product_url: str
    normalized_url: str
    source_host: str
    locale_identifier: str
    region_code: str
    currency_code: str
    country_hint: str
    target_country: str
    exclusion_policy: dict[str, Any]


class GeminiRequestError(RuntimeError):
    def __init__(self, code: int, message: str, attempts: int = 1) -> None:
        self.code = code
        self.message = message
        self.attempts = attempts
        super().__init__(f"Gemini request failed ({code}): {message}")


def parse_timeout_seconds(raw: str | None, default: float) -> float:
    if raw is None:
        return default
    try:
        value = float(str(raw).strip())
    except ValueError:
        return default
    if value < 2.0:
        return 2.0
    if value > 20.0:
        return 20.0
    return value


def parse_cooldown_seconds(raw: str | None, default: float) -> float:
    if raw is None:
        return default
    try:
        value = float(str(raw).strip())
    except ValueError:
        return default
    if value < RATE_LIMIT_COOLDOWN_MIN_SECONDS:
        return RATE_LIMIT_COOLDOWN_MIN_SECONDS
    if value > RATE_LIMIT_COOLDOWN_MAX_SECONDS:
        return RATE_LIMIT_COOLDOWN_MAX_SECONDS
    return value


def parse_retry_after_seconds(message: str) -> float | None:
    if not message:
        return None
    match = re.search(r"retry in\s+([0-9]+(?:\.[0-9]+)?)s", message, flags=re.IGNORECASE)
    if not match:
        return None
    try:
        seconds = float(match.group(1))
    except ValueError:
        return None
    if seconds < RATE_LIMIT_COOLDOWN_MIN_SECONDS:
        return RATE_LIMIT_COOLDOWN_MIN_SECONDS
    if seconds > RATE_LIMIT_COOLDOWN_MAX_SECONDS:
        return RATE_LIMIT_COOLDOWN_MAX_SECONDS
    return seconds


class DiscoveryEngine:
    def __init__(self) -> None:
        self.mode = os.getenv("SHOPIFY_BACKEND_MODE", "auto").strip().lower() or "auto"
        self.gemini_api_key = os.getenv("GEMINI_API_KEY", "").strip()
        self.gemini_model = os.getenv("GEMINI_MODEL", "").strip()
        self.gemini_enable_search = os.getenv("GEMINI_ENABLE_SEARCH", "1").strip() != "0"
        self.gemini_timeout_seconds = parse_timeout_seconds(os.getenv("GEMINI_TIMEOUT_SECONDS"), default=10.0)
        self.rate_limit_cooldown_seconds = parse_cooldown_seconds(
            os.getenv("GEMINI_RATE_LIMIT_COOLDOWN_SECONDS"),
            default=RATE_LIMIT_COOLDOWN_DEFAULT_SECONDS,
        )

        self.cache_lock = threading.Lock()
        self.query_cache: dict[str, CacheEntry] = {}
        self.intent_cache: dict[str, CacheEntry] = {}
        self.provider_lock = threading.Lock()
        self.provider_rate_limited_until = 0.0

    def discover(self, request_payload: dict[str, Any]) -> tuple[list[dict[str, str]], dict[str, Any]]:
        context = build_context_envelope(request_payload)
        cached = self._get_cache(context)
        if cached:
            return cached.alternatives, cached.meta

        remaining_cooldown = self._global_rate_limit_remaining_seconds()
        if remaining_cooldown > 0:
            meta = build_meta(
                source_stage="none",
                locality_used=context.target_country or "global",
                result_quality="low",
                reason="gemini_rate_limited",
                pipeline="single_call",
                gemini_calls=0,
            )
            meta["retryAfterSeconds"] = int(math.ceil(remaining_cooldown))
            self._set_cache_with_ttl(context, [], meta, remaining_cooldown)
            return [], meta

        if not self.gemini_api_key:
            meta = build_meta(
                source_stage="none",
                locality_used=context.target_country or "global",
                result_quality="low",
                reason="gemini_not_configured",
                pipeline="single_call",
                gemini_calls=0,
            )
            self._cache_if_eligible(context, [], meta)
            return [], meta

        started_at = time.time()
        source_stage = "single"
        used_intent_fallback = False
        try:
            candidates, gemini_calls = self._discover_single_call(context)
        except GeminiRequestError as exc:
            reason = classify_gemini_reason(exc.code)
            meta = build_meta(
                source_stage="none",
                locality_used=context.target_country or "global",
                result_quality="low",
                reason=reason,
                pipeline="single_call",
                gemini_calls=exc.attempts,
                latency_ms=int((time.time() - started_at) * 1000),
            )
            if reason == "gemini_rate_limited":
                cooldown = parse_retry_after_seconds(exc.message) or self.rate_limit_cooldown_seconds
                self._set_global_rate_limit(cooldown)
                meta["retryAfterSeconds"] = int(math.ceil(cooldown))
                self._set_cache_with_ttl(context, [], meta, cooldown)
                return [], meta
            self._cache_if_eligible(context, [], meta)
            return [], meta
        except Exception:
            meta = build_meta(
                source_stage="none",
                locality_used=context.target_country or "global",
                result_quality="low",
                reason="gemini_unavailable",
                pipeline="single_call",
                gemini_calls=1,
                latency_ms=int((time.time() - started_at) * 1000),
            )
            self._cache_if_eligible(context, [], meta)
            return [], meta

        final_candidates = candidates
        results, stats = filter_and_rank_candidates(final_candidates, context)

        # If the first grounded response is empty after filtering, run one short rescue call
        # with a simpler prompt to avoid returning empty for clearly valid product URLs.
        if not results:
            source_stage = "single_rescue"
            try:
                rescue_candidates, rescue_calls = self._discover_rescue_call(context)
                gemini_calls += rescue_calls
                final_candidates = rescue_candidates
                if rescue_candidates:
                    results, stats = filter_and_rank_candidates(final_candidates, context)
            except GeminiRequestError:
                # Keep the original empty-result path if rescue fails.
                pass
            except Exception:
                pass

        results = results[:MAX_RESULTS]
        reason = derive_result_reason(final_candidates, results, stats)

        if not results:
            intent_fallback = self._get_intent_cache(context)
            if intent_fallback:
                used_intent_fallback = True
                source_stage = "single_rescue"
                results = intent_fallback[:MAX_RESULTS]
                reason = "fallback_recent_category_matches"

        quality = classify_quality(len(results), reason)

        meta = build_meta(
            source_stage=source_stage,
            locality_used=context.target_country or "global",
            result_quality=quality,
            reason=reason,
            pipeline="single_call",
            gemini_calls=gemini_calls,
            latency_ms=int((time.time() - started_at) * 1000),
        )
        self._cache_if_eligible(context, results, meta)
        if results and not used_intent_fallback:
            self._set_intent_cache(context, results, meta)
        return results, meta

    def _discover_single_call(self, context: ContextEnvelope) -> tuple[list[dict[str, Any]], int]:
        prompt = build_single_call_prompt(context)
        payload, gemini_calls = self._gemini_generate_json(prompt)
        parsed = parse_first_json_array(payload)
        if not parsed:
            return [], gemini_calls

        validated: list[dict[str, Any]] = []
        for item in parsed:
            normalized = validate_candidate_contract(item)
            if normalized:
                validated.append(normalized)

        return validated, gemini_calls

    def _discover_rescue_call(self, context: ContextEnvelope) -> tuple[list[dict[str, Any]], int]:
        prompt = build_single_call_rescue_prompt(context)
        payload, gemini_calls = self._gemini_generate_json(prompt)
        parsed = parse_first_json_array(payload)
        if not parsed and self.gemini_enable_search:
            # Grounded retrieval can occasionally return no structured candidates.
            # Run one best-effort no-search fallback before giving up.
            payload_no_search, no_search_calls = self._gemini_generate_json_without_search(prompt)
            gemini_calls += no_search_calls
            parsed = parse_first_json_array(payload_no_search)
        if not parsed:
            return [], gemini_calls

        validated: list[dict[str, Any]] = []
        for item in parsed:
            normalized = validate_candidate_contract(item)
            if normalized:
                validated.append(normalized)

        return validated, gemini_calls

    def _gemini_generate_json(self, prompt: str) -> tuple[dict[str, Any], int]:
        model = self.gemini_model or "gemini-2.5-flash-lite"
        return self._call_gemini(model, prompt, use_search=self.gemini_enable_search)

    def _gemini_generate_json_without_search(self, prompt: str) -> tuple[dict[str, Any], int]:
        model = self.gemini_model or "gemini-2.5-flash-lite"
        return self._call_gemini(model, prompt, use_search=False)

    def _call_gemini(self, model: str, prompt: str, use_search: bool) -> tuple[dict[str, Any], int]:
        endpoint = (
            f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
            f"?key={self.gemini_api_key}"
        )

        generation_config: dict[str, Any] = {
            "temperature": 0.05,
            "maxOutputTokens": 700,
        }
        # Gemini currently rejects responseMimeType JSON when tool use is enabled.
        # Keep JSON mime only for no-tool calls; for grounded calls, enforce JSON via prompt.
        if not use_search:
            generation_config["responseMimeType"] = "application/json"

        body: dict[str, Any] = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": generation_config,
        }
        if use_search:
            body["tools"] = [{"googleSearch": {}}]

        def send(payload: dict[str, Any]) -> dict[str, Any]:
            req = request.Request(
                endpoint,
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with request.urlopen(req, timeout=self.gemini_timeout_seconds) as resp:
                return json.loads(resp.read().decode("utf-8"))

        attempts = 1
        try:
            return send(body), attempts
        except TimeoutError:
            raise GeminiRequestError(408, "timeout", attempts=attempts)
        except error.HTTPError as exc:
            raw_error = exc.read().decode("utf-8", errors="ignore")
            raise GeminiRequestError(exc.code, extract_http_error_message(raw_error), attempts=attempts)
        except error.URLError as exc:
            text = str(exc)
            if "timed out" in text.lower():
                raise GeminiRequestError(408, "timeout", attempts=attempts)
            hinted_status = parse_http_status_from_text(text)
            if hinted_status is not None:
                raise GeminiRequestError(hinted_status, text, attempts=attempts)
            raise GeminiRequestError(503, text, attempts=attempts)

    def _get_cache(self, context: ContextEnvelope) -> CacheEntry | None:
        key = cache_key(context)
        now = time.time()
        with self.cache_lock:
            entry = self.query_cache.get(key)
            if not entry:
                return None
            if entry.expires_at <= now:
                self.query_cache.pop(key, None)
                return None
            return entry

    def _set_cache(self, context: ContextEnvelope, alternatives: list[dict[str, str]], meta: dict[str, Any]) -> None:
        self._set_cache_with_ttl(context, alternatives, meta, CACHE_TTL_SECONDS)

    def _set_cache_with_ttl(
        self,
        context: ContextEnvelope,
        alternatives: list[dict[str, str]],
        meta: dict[str, Any],
        ttl_seconds: float,
    ) -> None:
        key = cache_key(context)
        ttl = max(1.0, float(ttl_seconds))
        with self.cache_lock:
            self.query_cache[key] = CacheEntry(
                expires_at=time.time() + ttl,
                alternatives=alternatives,
                meta=meta,
            )

    def _cache_if_eligible(self, context: ContextEnvelope, alternatives: list[dict[str, str]], meta: dict[str, Any]) -> None:
        # Cache successful payloads only. Empty responses can change between calls,
        # so retries should always hit Gemini again.
        if alternatives:
            self._set_cache(context, alternatives, meta)

    def _intent_cache_key(self, context: ContextEnvelope) -> str:
        tokens = set(fallback_keywords_from_url(context.normalized_url))
        category = infer_category_from_keywords(tokens) or "default"
        country = context.target_country or "global"
        return f"{country}:{category}"

    def _get_intent_cache(self, context: ContextEnvelope) -> list[dict[str, str]] | None:
        key = self._intent_cache_key(context)
        now = time.time()
        with self.cache_lock:
            entry = self.intent_cache.get(key)
            if not entry:
                return None
            if entry.expires_at <= now:
                self.intent_cache.pop(key, None)
                return None
            if not entry.alternatives:
                return None
            return entry.alternatives

    def _set_intent_cache(self, context: ContextEnvelope, alternatives: list[dict[str, str]], meta: dict[str, Any]) -> None:
        if not alternatives:
            return
        key = self._intent_cache_key(context)
        with self.cache_lock:
            self.intent_cache[key] = CacheEntry(
                expires_at=time.time() + CACHE_TTL_SECONDS,
                alternatives=alternatives,
                meta=meta,
            )

    def _set_global_rate_limit(self, cooldown_seconds: float) -> None:
        until = time.time() + max(1.0, cooldown_seconds)
        with self.provider_lock:
            self.provider_rate_limited_until = max(self.provider_rate_limited_until, until)

    def _global_rate_limit_remaining_seconds(self) -> float:
        with self.provider_lock:
            remaining = self.provider_rate_limited_until - time.time()
        return max(0.0, remaining)


ENGINE = DiscoveryEngine()


def build_meta(
    source_stage: str,
    locality_used: str,
    result_quality: str,
    reason: str | None,
    pipeline: str = "single_call",
    gemini_calls: int | None = None,
    latency_ms: int | None = None,
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "sourceStage": source_stage,
        "pipeline": pipeline,
        "localityUsed": locality_used or "global",
        "resultQuality": result_quality,
        "cacheTTLSeconds": CACHE_TTL_SECONDS,
    }
    if gemini_calls is not None:
        payload["geminiCalls"] = gemini_calls
    if latency_ms is not None:
        payload["latencyMs"] = latency_ms
    if reason:
        payload["reason"] = reason
    return payload


def classify_gemini_reason(code: int) -> str:
    if code == 429:
        return "gemini_rate_limited"
    if code in {401, 403}:
        return "gemini_auth_error"
    if code == 400:
        return "gemini_bad_request"
    if code in {408, 504}:
        return "gemini_timeout"
    if code in {500, 502, 503}:
        return "gemini_unavailable"
    return f"gemini_http_{code}"


def extract_http_error_message(raw_error: str) -> str:
    if not raw_error:
        return "http_error"

    try:
        parsed = json.loads(raw_error)
        if isinstance(parsed, dict):
            error_obj = parsed.get("error")
            if isinstance(error_obj, dict):
                message = error_obj.get("message")
                if isinstance(message, str) and message.strip():
                    return message.strip()
    except json.JSONDecodeError:
        pass

    clean = raw_error.strip()
    return clean[:240] if clean else "http_error"


def parse_http_status_from_text(text: str) -> int | None:
    match = re.search(r"HTTP Error\s+(\d{3})", text)
    if not match:
        return None
    try:
        status = int(match.group(1))
    except ValueError:
        return None
    return status if 100 <= status <= 599 else None


def classify_quality(count: int, reason: str | None) -> str:
    if count >= 4 and not reason:
        return "high"
    if count >= 2:
        return "medium"
    return "low"


def derive_result_reason(candidates: list[dict[str, Any]], results: list[dict[str, str]], stats: dict[str, int]) -> str | None:
    if results:
        if len(results) < MAX_RESULTS:
            if stats.get("dropped_low_confidence", 0) > 0 or stats.get("dropped_non_local", 0) > 0:
                return "sparse_local_matches"
            return "sparse_matches"
        return None

    if not candidates:
        return "no_candidates_from_gemini"
    if stats.get("dropped_low_confidence", 0) > 0:
        return "filtered_low_confidence"
    if stats.get("dropped_non_local", 0) > 0:
        return "filtered_non_local"
    return "no_valid_candidates"


def build_context_envelope(payload: dict[str, Any]) -> ContextEnvelope:
    raw_url = str(payload.get("productURL", "")).strip()
    normalized_url = normalize_source_url(raw_url)
    parsed = urlparse(normalized_url)
    source_host = parsed.netloc.lower().replace("www.", "")

    locale_identifier = normalize_opt_text(payload.get("localeIdentifier"))
    region_code = normalize_country_code(payload.get("regionCode"))
    currency_code = normalize_currency_code(payload.get("currencyCode"))
    country_hint = normalize_country_code(payload.get("countryHint"))

    if not region_code and locale_identifier and "_" in locale_identifier:
        region_code = normalize_country_code(locale_identifier.split("_")[-1])

    if not country_hint:
        country_hint = infer_country_from_url(normalized_url)

    target_country = region_code or country_hint
    exclusion_policy = {
        "blockedMarketplaceDomains": sorted(BLOCKED_MARKETPLACE_DOMAINS),
        "blockedBigBoxDomains": sorted(BLOCKED_BIGBOX_DOMAINS),
        "allowLocalRegionalChains": True,
    }

    return ContextEnvelope(
        product_url=raw_url,
        normalized_url=normalized_url,
        source_host=source_host,
        locale_identifier=locale_identifier,
        region_code=region_code,
        currency_code=currency_code,
        country_hint=country_hint,
        target_country=target_country,
        exclusion_policy=exclusion_policy,
    )


def cache_key(context: ContextEnvelope) -> str:
    blob = {
        "url": context.normalized_url,
        "locale": context.locale_identifier,
        "region": context.region_code,
        "currency": context.currency_code,
        "countryHint": context.country_hint,
    }
    return hashlib.sha256(json.dumps(blob, sort_keys=True).encode("utf-8")).hexdigest()


def normalize_source_url(value: str) -> str:
    if not value:
        return ""
    text = value.strip()
    if "://" not in text:
        text = f"https://{text}"
    parsed = urlparse(text)
    if parsed.scheme not in {"http", "https"}:
        raise ValueError("Unsupported productURL scheme")
    if not parsed.netloc:
        raise ValueError("Invalid productURL")
    return text


def normalize_opt_text(value: Any) -> str:
    return str(value).strip() if isinstance(value, str) else ""


def normalize_country_code(value: Any) -> str:
    text = normalize_opt_text(value).upper()
    if re.fullmatch(r"[A-Z]{2}", text):
        return text
    return ""


def normalize_currency_code(value: Any) -> str:
    text = normalize_opt_text(value).upper()
    if re.fullmatch(r"[A-Z]{3}", text):
        return text
    return ""


def infer_country_from_url(url: str) -> str:
    parsed = urlparse(url)
    host = parsed.netloc.lower().replace("www.", "")
    if not host:
        return ""

    parts = host.split(".")
    tld = parts[-1]
    if tld in COUNTRY_BY_TLD:
        return COUNTRY_BY_TLD[tld]

    lower_path = parsed.path.lower()
    if lower_path.startswith("/en-ca") or lower_path.startswith("/ca"):
        return "CA"
    if lower_path.startswith("/en-us") or lower_path.startswith("/us"):
        return "US"
    return ""


def build_single_call_prompt(context: ContextEnvelope) -> str:
    target_country = context.target_country or ""
    keyword_hint = ", ".join(fallback_keywords_from_url(context.normalized_url)[:12]) or "none"
    location_line = (
        f"Prefer stores in {target_country} or nearby regions, but locality is a soft preference only."
        if target_country
        else "Location is unknown, so ignore locality and focus on relevant non-big-retailer alternatives."
    )

    return f"""
Use grounded web search and reply quickly.

Source product URL: {context.normalized_url}
Keyword hints from URL slug: {keyword_hint}
{location_line}

Find up to {MAX_RESULTS} comparable products in the same category and use-case with a roughly similar price range.
Prefer independent, specialty, refurb, regional, and medium-sized retailers. Shopify storefronts are great when relevant but are not required.
Similarity does NOT require the same brand, exact model, or exact SKU.
Exclude only these large retailers and marketplaces: Amazon, Walmart, Target, BestBuy, eBay, Temu, AliExpress, Costco, Home Depot, Lowes.
Return only real product pages (not home/search/category pages).
If fewer than {MAX_RESULTS} good matches exist, return fewer.
When searching, use plain product keywords and avoid advanced query operators.
If locality produces weak results, ignore locality and return the best relevant non-big-retailer options instead.
Do not return an empty array for valid product URLs unless web grounding yields no usable product evidence at all.
If exact model matches are sparse, return closest same-category alternatives (especially for laptops, headphones, backpacks).

Return ONLY a JSON array with objects containing exactly:
storeName, productName, price, productURL, imageURL

Prefer visible prices. If price is unknown, set price to "Price unavailable".
For imageURL: prefer the retailer product image first, then a manufacturer/public product image for the same item, otherwise return null.
Keep imageURL concise and direct.
""".strip()


def build_single_call_rescue_prompt(context: ContextEnvelope) -> str:
    target_country = context.target_country or ""
    source_host = context.source_host or ""
    keyword_hint = ", ".join(fallback_keywords_from_url(context.normalized_url)[:16]) or "none"
    preferred_hint = preferred_merchants_hint(target_country)
    location_line = (
        f"Prefer {target_country} and nearby-region merchants first, but do not fail if locality is weak."
        if target_country
        else "Location is unknown. Ignore locality and focus on strong non-big-retailer relevance."
    )

    return f"""
Grounded product alternative lookup.

Source product URL: {context.normalized_url}
Source domain to avoid: {source_host}
Query terms: {keyword_hint}
{location_line}
Preferred merchant examples: {preferred_hint}

Return up to {MAX_RESULTS} alternatives that are in the same category/use-case and similar price range.
Exact brand/model/SKU matching is not required.
Never return: Amazon, Walmart, Target, BestBuy, eBay, Temu, AliExpress, Costco, Home Depot, Lowes.
Never return the same source domain.
Return product detail pages only.
If exact close matches are sparse, return closest relevant alternatives rather than empty.
For valid product URLs, return best-effort same-category alternatives even when confidence is moderate.
Avoid cross-category drift (for example: laptops should not return apparel; audio should not return home decor).

Return ONLY a JSON array of objects with:
storeName, productName, price, productURL, imageURL

Set price to "Price unavailable" if unknown.
Set imageURL to null if unavailable.
""".strip()


def parse_first_json_array(payload: dict[str, Any]) -> list[dict[str, Any]]:
    parts = extract_text_parts(payload)
    for text in parts:
        parsed = parse_json_like_array(text)
        if parsed:
            return parsed
    if parts:
        parsed = parse_json_like_array("\n".join(parts))
        if parsed:
            return parsed
    return []


def extract_text_parts(payload: dict[str, Any]) -> list[str]:
    output: list[str] = []
    candidates = payload.get("candidates")
    if not isinstance(candidates, list):
        return output

    for candidate in candidates:
        if not isinstance(candidate, dict):
            continue
        content = candidate.get("content")
        if not isinstance(content, dict):
            continue
        parts = content.get("parts")
        if not isinstance(parts, list):
            continue
        for part in parts:
            if not isinstance(part, dict):
                continue
            text = part.get("text")
            if isinstance(text, str) and text.strip():
                output.append(text)
    return output


def parse_json_like_object(text: str) -> dict[str, Any] | None:
    raw = strip_fence(text)
    parsed = try_parse_dict(raw)
    if parsed is not None:
        return parsed

    start = raw.find("{")
    end = raw.rfind("}")
    if start >= 0 and end > start:
        return try_parse_dict(raw[start : end + 1])
    return None


def parse_json_like_array(text: str) -> list[dict[str, Any]]:
    raw = strip_fence(text)
    parsed = try_parse_list(raw)
    if parsed is not None:
        return parsed

    start = raw.find("[")
    end = raw.rfind("]")
    if start >= 0 and end > start:
        parsed = try_parse_list(raw[start : end + 1])
        if parsed is not None:
            return parsed
    if start >= 0:
        parsed = try_parse_partial_list(raw[start:])
        if parsed:
            return parsed

    obj = parse_json_like_object(raw)
    if obj:
        for key in ("alternatives", "results", "products"):
            value = obj.get(key)
            if isinstance(value, list):
                return [item for item in value if isinstance(item, dict)]

    return []


def strip_fence(text: str) -> str:
    raw = text.strip()
    if raw.startswith("```"):
        raw = raw.strip("`")
        if raw.startswith("json"):
            raw = raw[4:].strip()
    return raw


def try_parse_dict(raw: str) -> dict[str, Any] | None:
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        return None
    return value if isinstance(value, dict) else None


def try_parse_list(raw: str) -> list[dict[str, Any]] | None:
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        return None
    if isinstance(value, list):
        return [item for item in value if isinstance(item, dict)]
    return None


def try_parse_partial_list(raw: str) -> list[dict[str, Any]]:
    decoder = json.JSONDecoder()
    items: list[dict[str, Any]] = []
    idx = 0

    while idx < len(raw):
        while idx < len(raw) and raw[idx] in " \n\r\t[":
            idx += 1

        while idx < len(raw) and raw[idx] == ",":
            idx += 1
            while idx < len(raw) and raw[idx] in " \n\r\t":
                idx += 1

        if idx >= len(raw) or raw[idx] == "]":
            break

        try:
            value, end = decoder.raw_decode(raw, idx)
        except json.JSONDecodeError:
            break

        if isinstance(value, dict):
            items.append(value)
        idx = end

    return items


def fallback_keywords_from_url(url: str) -> list[str]:
    parsed = urlparse(url)
    parts = [unquote(part) for part in parsed.path.split("/") if part]
    blob = " ".join(parts + [parsed.netloc])
    words = [w for w in re.findall(r"[a-z0-9]+", blob.lower()) if len(w) > 2 and w not in STOPWORDS]
    return dedupe(words)[:10]


def infer_category_from_keywords(keywords: set[str]) -> str:
    best_category = "default"
    best_score = 0
    for category, terms in CATEGORY_SIGNAL_TERMS.items():
        score = len(keywords & terms)
        if score > best_score:
            best_score = score
            best_category = category
    return best_category


def validate_candidate_contract(item: dict[str, Any]) -> dict[str, Any] | None:
    if not isinstance(item, dict):
        return None

    required = ["storeName", "productName", "productURL"]
    normalized: dict[str, Any] = {}
    for key in required:
        value = item.get(key)
        if not isinstance(value, str) or not value.strip():
            return None
        normalized[key] = value.strip()

    price = item.get("price")
    if isinstance(price, str) and price.strip():
        normalized["price"] = price.strip()
    else:
        normalized["price"] = "Price unavailable"

    product_url = normalize_product_url(normalized["productURL"])
    if not product_url:
        return None

    image_raw = item.get("imageURL")
    image_url = normalize_image_url(str(image_raw).strip(), product_url) if isinstance(image_raw, str) else ""

    normalized["productURL"] = product_url
    normalized["imageURL"] = image_url or None

    shop_country = normalize_country_code(item.get("shopCountry"))
    if shop_country:
        normalized["shopCountry"] = shop_country

    confidence = parse_confidence(item.get("confidence"))
    if confidence is not None:
        normalized["confidence"] = confidence

    is_shopify = parse_bool(item.get("isShopify"))
    if is_shopify is not None:
        normalized["isShopify"] = is_shopify

    merchant_tier = normalize_merchant_tier(item.get("merchantTier"))
    if merchant_tier:
        normalized["merchantTier"] = merchant_tier

    price_similarity = parse_confidence(item.get("priceSimilarity"))
    if price_similarity is not None:
        normalized["priceSimilarity"] = price_similarity

    normalized["priceValue"] = parse_price_value(normalized["price"])
    normalized["_canonicalKey"] = canonical_product_key(product_url)
    return normalized


def normalize_product_url(value: str) -> str:
    raw = value.strip()
    if not raw:
        return ""
    if raw.startswith("//"):
        raw = f"https:{raw}"

    parsed = urlparse(raw)
    if parsed.scheme not in {"http", "https"}:
        return ""
    host = parsed.netloc.lower().replace("www.", "")
    if not host:
        return ""

    clean = f"https://{host}{parsed.path or '/'}"
    if parsed.query:
        clean = f"{clean}?{parsed.query}"
    return clean


def normalize_image_url(value: str, product_url: str) -> str:
    raw = value.strip()
    if not raw:
        return ""
    if raw.startswith("//"):
        return f"https:{raw}"
    if raw.startswith("/"):
        host = urlparse(product_url).netloc.lower().replace("www.", "")
        return f"https://{host}{raw}"
    parsed = urlparse(raw)
    if parsed.scheme in {"http", "https"} and parsed.netloc:
        return raw
    return ""


def canonical_product_key(url: str) -> str:
    parsed = urlparse(url)
    host = parsed.netloc.lower().replace("www.", "")
    path = re.sub(r"/+", "/", parsed.path or "/")
    return f"{host}{path}".rstrip("/")


def parse_price_value(raw: Any) -> float | None:
    if raw is None:
        return None
    if isinstance(raw, (int, float)):
        value = float(raw)
        if value <= 0:
            return None
        return value

    text = str(raw)
    matches = re.findall(r"\d+(?:[\.,]\d+)?", text.replace(",", ""))
    if not matches:
        return None
    try:
        value = float(matches[0])
    except ValueError:
        return None
    return value if value > 0 else None


def parse_confidence(raw: Any) -> float | None:
    if raw is None:
        return None
    if isinstance(raw, bool):
        return None
    try:
        value = float(raw)
    except (TypeError, ValueError):
        return None
    if value < 0:
        return 0.0
    if value > 1:
        return 1.0
    return value


def parse_bool(raw: Any) -> bool | None:
    if isinstance(raw, bool):
        return raw
    if isinstance(raw, str):
        lower = raw.strip().lower()
        if lower in {"true", "yes", "1"}:
            return True
        if lower in {"false", "no", "0"}:
            return False
    return None


def normalize_merchant_tier(raw: Any) -> str:
    value = str(raw).strip().lower() if raw is not None else ""
    if value in MERCHANT_TIER_SCORES:
        return value
    return ""


def filter_and_rank_candidates(
    candidates: list[dict[str, Any]],
    context: ContextEnvelope,
) -> tuple[list[dict[str, str]], dict[str, int]]:
    if not candidates:
        return [], {}

    ranked: list[tuple[float, dict[str, Any]]] = []
    seen_keys: set[str] = set()
    stats: dict[str, int] = {
        "dropped_blocked": 0,
        "dropped_same_source": 0,
        "dropped_non_product_page": 0,
        "dropped_mismatch": 0,
        "dropped_non_local": 0,
        "dropped_low_confidence": 0,
    }

    source_tokens = set(fallback_keywords_from_url(context.normalized_url))
    source_category = infer_category_from_keywords(source_tokens)
    reference_price = estimate_reference_price(candidates)

    for candidate in candidates:
        canonical = str(candidate.get("_canonicalKey", ""))
        if not canonical or canonical in seen_keys:
            continue

        url = candidate["productURL"]
        store_name = candidate["storeName"].lower()
        host = urlparse(url).netloc.lower().replace("www.", "")

        if is_blocked_host(host) or is_blocked_store_name(store_name):
            stats["dropped_blocked"] += 1
            continue
        if host == context.source_host:
            stats["dropped_same_source"] += 1
            continue

        if not looks_like_product_page(url):
            stats["dropped_non_product_page"] += 1
            continue

        if not matches_source_intent(candidate, source_tokens, source_category):
            stats["dropped_mismatch"] += 1
            continue

        locality_country = detect_candidate_country(candidate, host)
        locality_score = score_locality(context.target_country, locality_country)
        preferred_merchant = is_preferred_merchant(context.target_country, host, candidate["storeName"])

        confidence = candidate.get("confidence")
        confidence_value = confidence if isinstance(confidence, float) else 0.72

        preferred_score = 30.0 if preferred_merchant else 0.0
        shopify_score = 24.0 if candidate.get("isShopify") else 0.0
        tier_score = score_merchant_tier(candidate.get("merchantTier"))
        confidence_score = confidence_value * 12.0
        price_score = score_price_soft(candidate.get("priceValue"), reference_price)
        price_similarity_score = (candidate.get("priceSimilarity") or 0.0) * 8.0
        missing_price_penalty = -10.0 if candidate.get("priceValue") is None else 0.0
        tie_breaker = stable_tiebreak(canonical)

        total = (locality_score * 1.2) + preferred_score + shopify_score + tier_score + confidence_score + price_score + price_similarity_score + missing_price_penalty + tie_breaker
        ranked.append((total, candidate))
        seen_keys.add(canonical)

    ranked.sort(key=lambda item: item[0], reverse=True)

    output: list[dict[str, str]] = []
    for _, candidate in ranked:
        item: dict[str, Any] = {
            "storeName": candidate["storeName"],
            "productName": candidate["productName"],
            "price": candidate["price"],
            "productURL": candidate["productURL"],
            "imageURL": candidate["imageURL"],
        }
        if candidate.get("shopCountry"):
            item["shopCountry"] = candidate["shopCountry"]
        if "isShopify" in candidate:
            item["isShopify"] = bool(candidate["isShopify"])
        if candidate.get("merchantTier"):
            item["merchantTier"] = candidate["merchantTier"]
        if candidate.get("confidence") is not None:
            item["confidence"] = round(float(candidate["confidence"]), 3)

        output.append(item)

    return output, stats


def matches_source_intent(candidate: dict[str, Any], source_tokens: set[str], source_category: str) -> bool:
    blob = " ".join(
        [
            candidate.get("productName", ""),
            candidate.get("storeName", ""),
            urlparse(candidate.get("productURL", "")).path.replace("/", " "),
        ]
    )
    tokens = set(tokenize(blob))
    if not tokens:
        return False

    if source_category == "electronics" and (tokens & MISMATCH_TERMS_FOR_ELECTRONICS):
        return False

    inferred = infer_category_from_keywords(tokens)
    if source_category and source_category != "default" and inferred != "default":
        compatible = inferred == source_category or {inferred, source_category} <= {"audio", "electronics"}
        if not compatible:
            return False

    return True


def looks_like_product_page(url: str) -> bool:
    parsed = urlparse(url)
    path = parsed.path.lower()
    if path in {"", "/"}:
        return False
    if any(
        p in path
        for p in (
            "/collections/",
            "/category/",
            "/categories/",
            "/search",
            "/review",
            "/reviews",
            "/blog",
            "/news",
            "/article",
        )
    ):
        return False
    return True


def detect_candidate_country(candidate: dict[str, Any], host: str) -> str:
    explicit = normalize_country_code(candidate.get("shopCountry"))
    if explicit:
        return explicit

    tld = host.split(".")[-1]
    if tld in COUNTRY_BY_TLD:
        return COUNTRY_BY_TLD[tld]

    name = str(candidate.get("storeName", "")).lower()
    if "canada" in name:
        return "CA"
    if "usa" in name or "united states" in name:
        return "US"
    return ""


def score_locality(target_country: str, candidate_country: str) -> float:
    if not target_country:
        return 35.0
    if candidate_country == target_country:
        return 100.0
    if candidate_country and candidate_country in NEARBY_COUNTRIES.get(target_country, set()):
        return 65.0
    if not candidate_country:
        return 22.0
    return 8.0


def score_merchant_tier(raw_tier: Any) -> float:
    tier = normalize_merchant_tier(raw_tier) or "unknown"
    return MERCHANT_TIER_SCORES.get(tier, 0.0)


def estimate_reference_price(candidates: list[dict[str, Any]]) -> float | None:
    prices = sorted(float(item["priceValue"]) for item in candidates if isinstance(item.get("priceValue"), float))
    if not prices:
        return None
    mid = len(prices) // 2
    if len(prices) % 2 == 1:
        return prices[mid]
    return (prices[mid - 1] + prices[mid]) / 2.0


def score_price_soft(candidate_price: float | None, profile_price: float | None) -> float:
    if not candidate_price or not profile_price or profile_price <= 0:
        return 5.0

    delta = abs(candidate_price - profile_price) / profile_price
    if delta <= 0.15:
        return 25.0
    if delta <= 0.30:
        return 16.0
    if delta <= 0.60:
        return 8.0
    return 0.0


def stable_tiebreak(value: str) -> float:
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()
    return int(digest[:2], 16) / 255.0


def is_blocked_host(host: str) -> bool:
    normalized = host.lower().replace("www.", "")
    if not normalized:
        return True

    for domain in BLOCKED_MARKETPLACE_DOMAINS | BLOCKED_BIGBOX_DOMAINS:
        if normalized == domain or normalized.endswith(f".{domain}"):
            return True

    if any(keyword in normalized for keyword in BLOCKED_MARKETPLACE_KEYWORDS):
        return True
    return False


def is_blocked_store_name(name_lower: str) -> bool:
    if any(keyword in name_lower for keyword in BLOCKED_MARKETPLACE_KEYWORDS):
        return True
    if any(keyword in name_lower for keyword in BLOCKED_BIGBOX_NAME_KEYWORDS):
        return True
    return False


def is_preferred_merchant(target_country: str, host: str, store_name: str) -> bool:
    if not target_country:
        return False

    policy = PREFERRED_MERCHANTS_BY_COUNTRY.get(target_country.upper())
    if not policy:
        return False

    normalized_host = host.lower().replace("www.", "")
    for domain in policy.get("domains", set()):
        if normalized_host == domain or normalized_host.endswith(f".{domain}"):
            return True

    name = store_name.lower()
    return any(keyword in name for keyword in policy.get("keywords", set()))


def preferred_merchants_hint(target_country: str) -> str:
    if not target_country:
        return "independent, specialty, and regional retailers"

    policy = PREFERRED_MERCHANTS_BY_COUNTRY.get(target_country.upper())
    if not policy:
        return "independent, specialty, and regional retailers"

    domains = sorted(policy.get("domains", set()))
    if not domains:
        return "independent, specialty, and regional retailers"
    return ", ".join(domains[:8])


def tokenize(text: str) -> list[str]:
    words = re.findall(r"[a-z0-9]+", text.lower())
    return [w for w in words if len(w) > 2 and w not in STOPWORDS]


def dedupe(values: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        out.append(value)
    return out


class Handler(BaseHTTPRequestHandler):
    server_version = "ShopifyAltBackend/4.0"

    def _send_json(self, payload: Any, status: int = HTTPStatus.OK) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        if self.path == HEALTH_PATH:
            self._send_json(
                {
                    "ok": True,
                    "mode": ENGINE.mode,
                    "geminiConfigured": bool(ENGINE.gemini_api_key),
                }
            )
            return

        self._send_json({"error": "Not found"}, status=HTTPStatus.NOT_FOUND)

    def do_POST(self) -> None:  # noqa: N802
        if self.path != DISCOVERY_PATH:
            self._send_json({"error": "Not found"}, status=HTTPStatus.NOT_FOUND)
            return

        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length) if length > 0 else b"{}"

        try:
            payload = json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError:
            self._send_json({"error": "Invalid JSON body"}, status=HTTPStatus.BAD_REQUEST)
            return

        product_url = payload.get("productURL")
        if not isinstance(product_url, str) or not product_url.strip():
            self._send_json({"error": "Missing productURL"}, status=HTTPStatus.BAD_REQUEST)
            return

        try:
            alternatives, meta = ENGINE.discover(payload)
        except Exception as exc:
            alternatives = []
            meta = build_meta(
                source_stage="none",
                locality_used="global",
                result_quality="low",
                reason=f"discovery_error:{exc.__class__.__name__}",
            )

        self._send_json({"alternatives": alternatives, "meta": meta}, status=HTTPStatus.OK)

    def log_message(self, fmt: str, *args: Any) -> None:
        return


def main() -> None:
    parser = argparse.ArgumentParser(description="Run local Shopify discovery backend.")
    parser.add_argument("--host", default="127.0.0.1", help="Bind host (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=8899, help="Bind port (default: 8899)")
    args = parser.parse_args()

    if args.port < 1 or args.port > 65535:
        raise ValueError("Port must be between 1 and 65535")

    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"Shopify discovery backend running at http://{args.host}:{args.port}")
    print(f"Endpoint: POST {DISCOVERY_PATH}")
    print(f"Health:   GET  {HEALTH_PATH}")
    print(f"Mode:     {ENGINE.mode} (geminiConfigured={bool(ENGINE.gemini_api_key)})")
    server.serve_forever()


if __name__ == "__main__":
    main()
