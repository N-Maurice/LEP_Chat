# Legal Ecosystem Platform (LEP Chat)

A mobile application for legal awareness and access to justice in Rwanda, built with **Flutter** on the frontend and a dedicated **FastAPI** backend on top of **Firebase** (Authentication, Firestore, Cloud Storage) and **Vertex AI (Gemini)**.

LEP Chat exists to close the legal-awareness gap affecting ordinary citizens: it lets someone ask a plain-language legal question and see the exact law it was answered from, generate a self-study course from real ingested legal documents, file and track a case or violation report with evidence attached, and message another citizen — all through one consistent, tested backend.

## Table of Contents

- [What This Project Does](#what-this-project-does)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Setup — Backend](#setup--backend)
- [Setup — Mobile App](#setup--mobile-app)
- [Running Tests](#running-tests)
- [Deployment](#deployment)
- [Authors](#authors)

## What This Project Does

LEP Chat is organised around five bottom-navigation tabs, plus a couple of screens reached from them:

- **Home** — dashboard with quick actions and a trending-legal-topics carousel.
- **Talk with Assistant** — a chat interface backed by a real Retrieval-Augmented Generation (RAG) agent. Gemini is given a `search_legal_corpus` tool and decides for itself when and how many times to search the ingested legal corpus before answering, citing the exact source document (and Article number, when the source names one) for every claim — never answering from general knowledge alone.
- **Education** — two segments in one screen:
  - *Learning Tracks*: four AI-generated, five-module self-study courses (Labour Law 101, Business Compliance, Family Law, Land Rights), grounded only in the ingested corpus.
  - *Legal Research*: a live semantic search box over the same corpus, with a "Read Original" link to a signed URL of the actual source PDF.
  - A **Regional Law Explorer** entry point (Rwanda functional; other African jurisdictions marked "coming soon").
- **Cases** — submit a case, attach evidence in any file format, and track its status. A citizen-filed **Report a Violation** feeds into this same backend, tagged as a violation report.
- **Community** — search other citizens by username and exchange direct messages.
- **Profile** — account details and sign-out.

Authentication supports both email/password (with Firebase's own email verification — no custom SMTP/OTP) and Google Sign-In.

## Architecture

The Flutter app never talks to Firestore directly — it has no Firestore SDK dependency at all. Every read and write is a REST call to the FastAPI backend, carrying the user's Firebase ID token as a bearer token. This keeps all data-ownership and access-control logic in one testable place (the backend service layer) instead of splitting it between the client and a Firestore rules file.

```
Flutter (Provider)  ──REST + Firebase ID token──>  FastAPI  ──>  Firestore / Cloud Storage
        │                                              │
        └── Firebase Auth (identity only) ─────────────┘
                                                         └──>  Vertex AI (Gemini + embeddings)
```

- **Frontend**: Flutter, using the `provider` package for state management (a single `AuthController extends ChangeNotifier` drives the whole auth funnel; other screens talk to the backend through small, injectable `*ApiService` classes).
- **Backend**: FastAPI, structured as `routers/` (HTTP layer) → `services/` (business logic + ownership checks) → `db/repositories/` (pure Firestore CRUD), plus `agents/` for the RAG chat agent and course generator.
- **Data**: Cloud Firestore for all structured data, Cloud Storage for ingested legal-document PDFs and citizen-submitted evidence (served back as short-lived signed URLs, never public links).
- **AI**: Vertex AI's `text-embedding-005` for embeddings and `gemini-2.5-flash` for generation, via the `google-genai` SDK.


## Repository Structure

```
LEP_Chat/
├── api_lep_chat/
│   ├── app/                    # FastAPI backend
│   │   ├── agents/             # RAG chat agent, course generator, prompts
│   │   ├── core/                # Settings, Firebase Admin SDK bootstrap
│   │   ├── db/                  # Firestore/Storage clients + repositories
│   │   ├── middleware/          # CORS
│   │   ├── routers/             # auth, users, sessions, messages, education,
│   │   │                        #   research, cases, conversations
│   │   ├── schemas/             # Pydantic request/response contracts
│   │   ├── services/            # Business logic + ownership checks
│   │   ├── tests/                # pytest suite (61 tests)
│   │   ├── main.py               # FastAPI app + router registration
│   │   ├── requirements.txt
│   │   └── .env                  # Local environment config (gitignored)
│   ├── gcs/                    # Offline ingestion pipeline for the legal-document corpus
│   ├── functions/              # (Firebase Cloud Functions, if any)
│   └── requirements.txt        # Full pinned dependency set (for Render deployment)
├── lep_chat_mobile/
│   ├── lib/
│   │   ├── core/                 # ApiClient, AuthController, Env
│   │   ├── models/                # Typed API response models
│   │   ├── services/               # One *ApiService per feature
│   │   ├── screens/                 # One file per screen/route
│   │   ├── theme/                    # "Docket & Ledger" design tokens
│   │   └── main.dart                  # MaterialApp, AuthGate, bottom-nav shell
│   ├── test/                    # flutter_test suite (43 tests)
│   └── .env.json                 # API_BASE_URL — local vs. deployed backend
├── docs/
│   └── LEP_Chat_Final_Report.pdf
├── setup.sh                    # Quick backend bootstrap
└── push.sh                     # Commit-splitting helper script
```

## Prerequisites

- Installing Flutter SDK (https://docs.flutter.dev/get-started/install)
- Application apk (https://drive.google.com/drive/folders/1RJX2nL3w9G7NTPVKBZebVFif5T9fJXe5?usp=sharing (3.10+))
- Python 3.13
- A Firebase project with Authentication (Email/Password + Google) and Firestore enabled
- A Firebase service-account JSON key (for the backend) — **never commit this file**; it's gitignored
- A Google Cloud project with Vertex AI enabled, and a GCS bucket holding the ingested legal-document corpus

## Setup — Backend

```bash
cd api_lep_chat
python3 -m venv app/.venv
app/.venv/bin/pip install -r app/requirements.txt
```

Place your Firebase service-account key inside `api_lep_chat/app/` and create `api_lep_chat/app/.env`:

```env
ENVIRONMENT=development
GOOGLE_CLOUD_PROJECT=your-gcp-project
GOOGLE_CLOUD_LOCATION=us-central1
FIREBASE_CREDENTIALS_PATH=/absolute/path/to/api_lep_chat/app/your-service-account.json
FIRESTORE_DATABASE_ID=default
GCS_CORPUS_BUCKET=your-corpus-bucket
GCS_EVIDENCE_BUCKET=your-evidence-bucket
EMBEDDING_MODEL=text-embedding-005
GENERATION_MODEL=gemini-2.5-flash
```

Run it:

```bash
app/.venv/bin/uvicorn app.main:app --reload --port 8000
# or simply: ./setup.sh
```

The interactive API docs are then available at `http://localhost:8000/docs`.

## Setup — Mobile App

```bash
cd lep_chat_mobile
flutter pub get
```

Point the app at your backend via `.env.json` (already present, not gitignored — it carries only a base URL, no secrets):

```json
{
  "API_BASE_URL": "http://localhost:8000/api/v1"
}
```

Add your Firebase config (`flutterfire configure`, or manually place `google-services.json` / `GoogleService-Info.plist`), then run:

```bash
flutter run -d chrome     # or a connected Android/iOS device/emulator
```

## Running Tests

```bash
# Backend — 61 passing
cd api_lep_chat/app
../app/.venv/bin/pytest -q

# Mobile — 43 passing, 0 analyzer warnings
cd lep_chat_mobile
flutter test
flutter analyze
```

## Deployment

The backend is deployed on [Render](https://lep-chat.onrender.com/docs) at `https://lep-chat.onrender.com`. Its start command binds explicitly to `0.0.0.0:$PORT` (`uvicorn app.main:app --host 0.0.0.0 --port $PORT`), and the Firebase service-account key is uploaded through Render's **Secret Files**, never committed to the repository. The mobile app's `.env.json` is switched between the local and deployed URL depending on environment.

## Authors

**Group 17 — African Leadership University**

- Nshimyumukiza Maurice
- Boussamba Quenum Joseph
- Grace Umwari
