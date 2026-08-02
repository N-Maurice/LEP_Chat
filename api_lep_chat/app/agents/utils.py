"""Small helpers shared by every agent."""

import json


def excerpt(text: str, max_chars: int = 240) -> str:
    text = " ".join(text.split())
    if len(text) <= max_chars:
        return text
    return text[:max_chars].rsplit(" ", 1)[0] + "…"


def parse_json_response(text: str) -> dict:
    """Gemini is asked for raw JSON but sometimes wraps it in a ```json fence anyway."""
    text = (text or "").strip()
    if text.startswith("```"):
        text = text.split("```")[1]
        if text.startswith("json"):
            text = text[4:]
    try:
        return json.loads(text.strip())
    except json.JSONDecodeError:
        return {}
