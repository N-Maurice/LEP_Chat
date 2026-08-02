"""Prompt templates for the legal research agent. Kept separate from the agent's control
flow so wording can be tuned without touching logic."""

DOMAIN_GUESS_PROMPT = """You are a legal research assistant for Rwandan law. Below is the table of
contents of a legal document repository, structured as category -> domain -> subdomain -> file count.

TABLE OF CONTENTS:
{toc_text}

USER QUESTION:
{question}

Based on the table of contents above, identify the single most relevant "domain" and, if
applicable, "subdomain" for this question. Respond with ONLY a JSON object, no other text,
in this exact format:
{{"category": "...", "domain": "...", "subdomain": "..." or null}}
"""

GROUNDED_ANSWER_PROMPT = """You are a legal research assistant for Rwandan law. Answer the question using
ONLY the sources provided below. Cite the specific source number(s) for every claim, like [Source 2].
If the sources don't contain enough information to answer, say so clearly rather than guessing.

SOURCES:
{context}

QUESTION:
{question}

ANSWER (with inline [Source N] citations):
"""

COURSE_GENERATION_PROMPT = """You are building a self-study legal education course for the "{track_label}"
track, for citizens learning about Rwandan law. Below are numbered source excerpts pulled from the actual
ingested legal document corpus for this track.

Using ONLY these sources — do not invent facts, laws, or content that isn't grounded in them — organize
them into a course with EXACTLY 5 modules. Each module should cover a distinct, coherent theme found in the
sources (don't just split them arbitrarily). If the sources only really support fewer than 5 distinct themes,
it's fine for a module to draw on the same handful of sources as another as long as its angle is genuinely
different — but never fabricate a theme that isn't backed by the sources.

SOURCES:
{context}

Respond with ONLY a JSON object, no other text, in this exact format:
{{
  "course_title": "...",
  "course_description": "one or two sentences",
  "modules": [
    {{
      "title": "...",
      "summary": "2-4 sentences explaining what this module covers, grounded in its sources",
      "source_numbers": [1, 3]
    }}
  ]
}}
The "modules" array must have exactly 5 entries. "source_numbers" must reference the [Source N] numbers above.
"""
