const API_KEY = process.env.REACT_APP_BACKBOARD_API_KEY || 'espr_N8iIQE8wNuJCq1VKebscrrB23EbGvbLHGaQF7BZoD54';
const BASE = process.env.NODE_ENV === 'development' ? '/api' : 'https://app.backboard.io/api';

function jsonHeaders() {
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': API_KEY,
  };
}

function readJsonOrThrow(res, label) {
  if (!res.ok) {
    throw new Error(`${label}: ${res.status}`);
  }
  return res.json();
}

export async function bbCreateAssistant(name, systemPrompt) {
  const res = await fetch(`${BASE}/assistants`, {
    method: 'POST',
    headers: jsonHeaders(),
    body: JSON.stringify({ name, system_prompt: systemPrompt }),
  });
  return readJsonOrThrow(res, 'Create assistant');
}

export async function bbCreateThread(assistantId) {
  const res = await fetch(`${BASE}/assistants/${assistantId}/threads`, {
    method: 'POST',
    headers: jsonHeaders(),
  });
  return readJsonOrThrow(res, 'Create thread');
}

export async function bbSendMessage(threadId, content) {
  const body = new URLSearchParams();
  body.append('content', content);
  body.append('stream', 'false');
  body.append('memory', 'Auto');

  const res = await fetch(`${BASE}/threads/${threadId}/messages`, {
    method: 'POST',
    headers: { 'X-API-Key': API_KEY, 'Accept': 'application/json' },
    body,
  });
  return readJsonOrThrow(res, 'Send message');
}
