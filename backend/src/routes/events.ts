// src/routes/events.ts
// Event endpoints: create, get, nearby, update status

import { Router, Request, Response } from "express";
import { supabase } from "../lib/supabase";
import { v4 as uuidv4 } from "uuid";

const router = Router();

// GET /events/nearby?lat=&lng=&radius=
// Returns events within radius (km) sorted by distance
router.get("/nearby", async (req: Request, res: Response) => {
  try {
    const lat = parseFloat(req.query.lat as string);
    const lng = parseFloat(req.query.lng as string);
    const radius = parseFloat(req.query.radius as string) || 5;

    if (isNaN(lat) || isNaN(lng)) {
      res.status(400).json({ error: "lat and lng are required" });
      return;
    }

    // Simple bounding box query (Haversine for production)
    const degreeOffset = radius / 111.32;

    const { data: events, error } = await supabase
      .from("events")
      .select("*, options(*)")
      .in("status", ["live", "bets_closed"])
      .gte("location_lat", lat - degreeOffset)
      .lte("location_lat", lat + degreeOffset)
      .gte("location_lng", lng - degreeOffset)
      .lte("location_lng", lng + degreeOffset)
      .order("created_at", { ascending: false });

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    // Calculate distance and sort
    const withDistance = (events || []).map((event) => ({
      ...event,
      distance_km: haversine(
        lat, lng,
        event.location_lat, event.location_lng
      ),
    }));

    withDistance.sort((a, b) => a.distance_km - b.distance_km);

    res.json({ events: withDistance });
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch nearby events" });
  }
});

// GET /events/:eventId
router.get("/:eventId", async (req: Request, res: Response) => {
  try {
    const { data: event, error } = await supabase
      .from("events")
      .select("*, options(*), organizers(id, rating, events_created)")
      .eq("id", req.params.eventId)
      .single();

    if (error || !event) {
      res.status(404).json({ error: "Event not found" });
      return;
    }

    res.json({ event });
  } catch (err) {
    res.status(500).json({ error: "Failed to fetch event" });
  }
});

// POST /events
// Create a new prediction market
router.post("/", async (req: Request, res: Response) => {
  try {
    const {
      name,
      options,
      minimum_bet,
      betting_window,
      organizer_id,
      location_lat,
      location_lng,
      location_name,
    } = req.body;

    if (!name || !options || options.length < 2 || !organizer_id) {
      res.status(400).json({
        error: "name, options (min 2), and organizer_id are required",
      });
      return;
    }

    if (options.length > 6) {
      res.status(400).json({ error: "Maximum 6 options allowed" });
      return;
    }

    const eventId = uuidv4();

    // Create event
    const { error: eventError } = await supabase.from("events").insert({
      id: eventId,
      name,
      minimum_bet: minimum_bet || 5,
      betting_window: betting_window || "manual",
      organizer_id,
      location_lat,
      location_lng,
      location_name,
      started_at: new Date().toISOString(),
    });

    if (eventError) {
      res.status(500).json({ error: eventError.message });
      return;
    }

    // Create options
    const optionRows = options.map((opt: string) => ({
      id: uuidv4(),
      event_id: eventId,
      name: opt,
    }));

    const { error: optError } = await supabase
      .from("options")
      .insert(optionRows);

    if (optError) {
      res.status(500).json({ error: optError.message });
      return;
    }

    // Increment organizer event count (non-critical)
    try {
      await supabase
        .from("organizers")
        .update({ events_created: (await supabase.from("organizers").select("events_created").eq("id", organizer_id).single()).data?.events_created + 1 || 1 })
        .eq("id", organizer_id);
    } catch {
      // Non-critical, ignore
    }

    // Fetch complete event
    const { data: event } = await supabase
      .from("events")
      .select("*, options(*)")
      .eq("id", eventId)
      .single();

    res.status(201).json({
      event,
      qr_url: `${process.env.CLIPBET_BASE_URL || "https://clipbet.io"}/event/${eventId}`,
    });
  } catch (err) {
    res.status(500).json({ error: "Failed to create event" });
  }
});

// PATCH /events/:eventId/status
// Update event status (close bets, etc.)
router.patch("/:eventId/status", async (req: Request, res: Response) => {
  try {
    const { status } = req.body;
    const validStatuses = ["live", "bets_closed"];

    if (!validStatuses.includes(status)) {
      res.status(400).json({ error: "Invalid status" });
      return;
    }

    const updates: Record<string, unknown> = { status };
    if (status === "bets_closed") {
      updates.closed_at = new Date().toISOString();
    }

    const { data, error } = await supabase
      .from("events")
      .update(updates)
      .eq("id", req.params.eventId)
      .select()
      .single();

    if (error) {
      res.status(500).json({ error: error.message });
      return;
    }

    res.json({ event: data });
  } catch (err) {
    res.status(500).json({ error: "Failed to update status" });
  }
});

// Haversine distance formula
function haversine(
  lat1: number, lon1: number,
  lat2: number, lon2: number
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 100) / 100;
}

export default router;
