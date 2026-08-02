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
