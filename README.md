<p align="center">
  <img src="priv/static/images/jejak-jati-logo.svg" alt="Jejak Jati" width="220">
</p>

<h1 align="center">Jejak Jati</h1>

<p align="center">
  An evidence-oriented research system for tracing bibliographic works,
  authorship, identities, and historical records across heterogeneous sources.
</p>

---

## About

**Jejak Jati** is an experimental research application for investigating
bibliographic works and the people associated with them.

Rather than treating a single database result as authoritative, Jejak Jati is
being designed around a multi-source and evidence-oriented research workflow.

A research request starts with basic bibliographic information such as:

- title
- author
- ISBN, when available

Jejak Jati then queries external sources, normalizes their records, evaluates
possible matches, and preserves the results for review.

The long-term goal is to make bibliographic and authority research
**traceable, explainable, and source-aware**.

## Current Status

Jejak Jati is under active development.

The current prototype implements an end-to-end research workflow using the
**Deutsche Nationalbibliothek (DNB)** as its first bibliographic source.

A research run currently performs the following pipeline:

```text
Research request
      │
      ▼
ResearchRun
      │
      ▼
Oban background job
      │
      ▼
DNB SRU adapter
      │
      ▼
MARC21 XML normalization
      │
      ▼
WorkResult candidates
      │
      ▼
WorkMatcher
      │
      ▼
SourceRequest + SourceCandidates
      │
      ▼
Review in the web interface
```

The browser interface updates the research results asynchronously using htmx.

## Implemented Features

The current prototype includes:

- Phoenix web interface for starting research runs
- PostgreSQL persistence through Ecto
- `Ecto.Enum` based research and source states
- asynchronous research jobs with Oban
- DNB SRU catalogue integration
- MARC21 XML parsing and normalization
- normalization of DNB-specific non-sorting characters
- bibliographic candidate matching
- title, author, and ISBN comparison
- explainable matching scores
- confidence classification
- persistence of source queries
- persistence of individual bibliographic candidates
- preservation of matching reasons
- automatic browser polling with htmx
- display of source candidates and their matching scores
- offline source tests using `Req.Test` and XML fixtures

## Matching

External catalogue results are treated as **candidates**, not automatically as
facts.

The current matcher considers signals such as:

```text
Exact ISBN match
Exact title match
Title similarity
Exact author match
Author similarity
```

Each candidate receives a score together with the reasons that contributed to
that score.

Candidates are currently classified approximately as:

```text
80+     strong match
50–79   requires review
<50     no reliable match
```

These thresholds are experimental and will evolve as additional sources and
real-world test cases are introduced.

A low-scoring result is therefore not silently accepted merely because it is
the best result returned by a catalogue.

## Source Architecture

Source-specific logic is isolated behind source adapters.

The first implemented adapter is:

```text
JejakJati.Sources.DNB
```

It communicates with the SRU interface of the Deutsche Nationalbibliothek and
normalizes MARC21 records into source-independent `WorkResult` structures.

The application deliberately separates:

```text
Source adapter  → candidate discovery and normalization
WorkMatcher     → candidate comparison and ranking
Research layer  → persistence and research decisions
Worker          → asynchronous orchestration
```

This is intended to allow additional bibliographic and authority sources to be
added without coupling the core research logic to a particular catalogue.

## Data Model

The current research workflow is centered around three entities:

```text
ResearchRun
└── SourceRequest
    └── SourceCandidate
```

### ResearchRun

Represents a research request initiated by the user.

### SourceRequest

Records the outcome of consulting one external source for a research run,
including:

- source
- execution status
- number of candidates
- best matching score
- matching decision
- errors

A successful source request does **not** imply that a match was found.

For example:

```text
source: DNB
status: succeeded
candidate_count: 6
best_score: 14
decision: no_match
```

means that the DNB request succeeded technically, but none of the returned
records was considered a reliable bibliographic match.

### SourceCandidate

Preserves an individual normalized catalogue candidate, including:

- source identifier
- title
- author
- ISBN
- publication year
- publisher
- source URL
- matching score
- matching reasons

This allows research decisions to remain inspectable after a background job
has completed.

## Technology

Jejak Jati currently uses:

- Elixir
- Phoenix
- Ecto
- PostgreSQL
- Oban
- Req
- SweetXml
- htmx
- Tailwind CSS
- daisyUI

## Development

Install dependencies:

```bash
mix setup
```

Make sure PostgreSQL is running and your local database credentials are
configured.

Run migrations:

```bash
mix ecto.migrate
```

Start the Phoenix server:

```bash
mix phx.server
```

The application is then available at:

```text
http://localhost:4000
```

## Tests

Run the test suite with:

```bash
mix test
```

External source tests do not depend on the live DNB service. DNB responses are
tested using `Req.Test` and local MARC21 XML fixtures.

This keeps the test suite deterministic and prevents automated tests from
sending requests to external catalogues.

## Configuration and Secrets

Database passwords and other credentials must **not** be committed to the
repository.

Local secrets should be provided through environment variables or other
ignored local configuration.

Before committing changes, always check:

```bash
git status
git diff --cached
```

and ensure that credentials, local environment files, and other secrets are
not included.

## Roadmap

The next development phase will focus on turning the current single-source
prototype into a multi-source research system.

Planned work includes:

- source orchestration
- additional bibliographic sources
- authority-record sources
- cross-source candidate reconciliation
- richer evidence persistence
- provenance tracking
- confidence and conflict handling
- manual candidate review
- improved research result presentation

The matching model and confidence thresholds will be refined as the system is
tested against a broader range of bibliographic records.

## Project Philosophy

Jejak Jati is designed around a simple principle:

> A search result is not evidence merely because it is the first result.

The system should preserve where information came from, distinguish technical
success from evidential confidence, expose uncertainty, and allow research
decisions to be inspected rather than hiding them behind a single opaque
result.

---

**Jejak Jati** is currently an experimental project and should not yet be
treated as an authoritative bibliographic or identity-resolution service.
