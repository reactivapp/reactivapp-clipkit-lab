const API_KEY = process.env.REACT_APP_BACKBOARD_API_KEY;
const BASE = '/api';

function jsonHeaders() {
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': API_KEY,
  };
}

export async function bbCreateAssistant(name, systemPrompt) {
  const res = await fetch(`${BASE}/assistants`, {
    method: 'POST',
    headers: jsonHeaders(),
    body: JSON.stringify({ name, system_prompt: systemPrompt }),
  });
  if (!res.ok) throw new Error(`Create assistant: ${res.status}`);
  return res.json();
}

export async function bbCreateThread(assistantId) {
  const res = await fetch(`${BASE}/assistants/${assistantId}/threads`, {
    method: 'POST',
    headers: jsonHeaders(),
  });
  if (!res.ok) throw new Error(`Create thread: ${res.status}`);
  return res.json();
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
  if (!res.ok) throw new Error(`Send message: ${res.status}`);
  return res.json();
}
