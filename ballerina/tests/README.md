# Running Tests

## Test Environments

The tests can run against two different environments:

1. **Mock Server** (default) — a local mock server on port 9090.
2. **Live Hugging Face API** — the Hugging Face Inference Providers router or a custom TGI instance.

## Hugging Face Router Base URLs

Verified live against the real API (2026-06-23):

| Base URL | What actually works |
|---|---|
| `https://router.huggingface.co` | `/v1/chat/completions` - routed to **any** Inference Provider (Cerebras, Groq, Nscale, Together, etc.) based on the model. `/v1/models` - returns an OpenAI-style `{object: "list", data: [...]}` catalog of every model (bound as `ModelList`, not `ModelInfo`). `/v1/completions` - 404 (chat-only endpoint per HF's docs). |
| `https://router.huggingface.co/hf-inference` | **Nothing tested worked.** `/generate`, `/tokenize`, `/chat_tokenize` returned `400 "Model not supported by provider hf-inference"` even for models HF's own docs list as hf-inference-supported (e.g. `gpt2`). `/health`, `/info`, `/v1/models`, `/v1/chat/completions` all returned `404 Not Found`. |

**Why:** `hf-inference` is one specific Inference Provider, not the multi-provider router, and as of mid-2025
[HF's own docs](https://huggingface.co/docs/inference-providers/en/providers/hf-inference) say it "focuses
mostly on CPU inference... or smaller LLMs that have historical importance like BERT or GPT-2" — it is not a
realistic target for testing this connector's chat/tool-calling surface against HF's shared infrastructure
at all anymore. The TGI-native endpoints (`/generate`, `/health`, `/info`, `/tokenize`, `/chat_tokenize`,
`/generate_stream`, `/invocations`, `/metrics`) are designed for a single dedicated TGI server and are
**not exposed through the shared router in any form we could find** — they only work against a genuinely
self-hosted TGI instance (Docker) or a dedicated Hugging Face Inference Endpoint, see below.

> **Note:** The legacy `https://api-inference.huggingface.co` endpoint has been decommissioned and no longer resolves.

## Running Tests Against the Mock Server

No extra configuration is needed. Tests use the mock server at `http://localhost:9090` by default.

```bash
bal test
```

Or using Gradle:

```bash
./gradlew clean test
```

## Running Tests Against the Live Hugging Face API

### Prerequisites

1. A Hugging Face access token with **Inference Providers** permission. Create one at [Hugging Face Settings](https://huggingface.co/settings/tokens).
2. For gated models (e.g. Llama), accept the model license on the Hugging Face Hub before running tests.

### Configuration

Create or update `Config.toml` in the `tests` directory:

```toml
token = "<your-huggingface-access-token>"
serviceUrl = "https://router.huggingface.co"
modelId = "openai/gpt-oss-120b"
```

`Config.toml` is gitignored — it's safe to put a real token in it directly instead of using the
`TGI_TOKEN` environment variable, as long as you don't commit it.

Set the following environment variable:

```bash
export IS_LIVE_SERVER=true
```

(If you'd rather not put the token in `Config.toml`, leave `token` unset there and instead `export TGI_TOKEN="<your-token>"`.)

There are two live groups, scoped to what each target actually exposes:

- **`live_router`** — only the `/v1/chat/completions` and `/v1/models` tests (basic chat, multi-turn, usage,
  logprobs, tool calling, tool-call round trip, `toolChoice: "none"`, forced specific tool, model catalog).
  This is the subset that works against the shared `https://router.huggingface.co`, across any Inference
  Provider.
- **`live_tests`** — the full set, including the native TGI endpoints (`/generate`, `/health`, `/info`,
  `/tokenize`, `/chat_tokenize`, `/generate_stream`, `/v1/completions`). This only passes against a real,
  dedicated TGI server (Docker or a Hugging Face Inference Endpoint) — see "Running Tests Against a Custom
  TGI Instance" below. Running `live_tests` against the shared router will fail on everything outside
  `/v1/chat/completions` and `/v1/models`, not because the connector is broken, but because the router
  doesn't expose those other endpoints/shapes at all.

Against the router, run:

```bash
bal test --groups live_router
```

### Run live tests

Against the shared router (`serviceUrl = "https://router.huggingface.co"`):

```bash
bal test --groups live_router
```

Against a dedicated TGI deployment (see below), the full set:

```bash
bal test --groups live_tests
```

Or using Gradle:

```bash
./gradlew clean test -Pgroups=live_router
./gradlew clean test -Pgroups=live_tests
```

> **Note:** Some test groups (`metrics`, `sagemaker`, `params`, `types`) are mock-only or unit tests and are not included in `live_tests`/`live_router`.

## Running Tests Against a Custom TGI Instance

Deploy your own TGI instance (e.g. via Docker or a Hugging Face Inference Endpoint) and point the tests at
it. This is required for the native TGI endpoints (`/generate`, `/health`, `/info`, `/tokenize`,
`/chat_tokenize`, `/generate_stream`, `/v1/completions`) — none of these are reachable through
`https://router.huggingface.co`:

```toml
serviceUrl = "https://your-tgi-endpoint.example.com"
modelId = "your-model-id"
```

```bash
export IS_LIVE_SERVER=true
export TGI_TOKEN="<your-access-token-if-required>"
bal test --groups live_tests
```
