# Running Tests

## Test Environments

The tests can run against two different environments:

1. **Mock Server** (default) — a local mock server on port 9090.
2. **Live Hugging Face API** — the Hugging Face Inference Providers router or a custom TGI instance.

## Hugging Face Router Base URLs

Recommended: `https://router.huggingface.co/hf-inference` for the full TGI API, or `https://router.huggingface.co` for OpenAI-style endpoints only.

| Base URL | What works |
|---|---|
| `https://router.huggingface.co` | OpenAI-style `/v1/chat/completions`, `/v1/models` |
| `https://router.huggingface.co/hf-inference` | Full TGI API: `/generate`, `/health`, `/info`, `/tokenize`, `/v1/chat/completions`, etc. |

> **Note:** The legacy `https://api-inference.huggingface.co` endpoint has been decommissioned and no longer resolves. Use the router URLs above instead.

For the full test suite, use `https://router.huggingface.co/hf-inference`.

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
serviceUrl = "https://router.huggingface.co/hf-inference"
modelId = "meta-llama/Llama-3.1-8B-Instruct"
```

Set the following environment variables:

```bash
export IS_LIVE_SERVER=true
export TGI_TOKEN="<your-huggingface-access-token>"
```

### Tested models

Run live tests one model at a time by changing `modelId` in `Config.toml`:

| Model | `modelId` value |
|---|---|
| Llama 3.1 8B Instruct | `meta-llama/Llama-3.1-8B-Instruct` |
| Llama 3.1 70B Instruct | `meta-llama/Llama-3.1-70B-Instruct` |
| GPT-OSS 20B | `openai/gpt-oss-20b` |
| GPT-OSS 120B | `openai/gpt-oss-120b` |
| Qwen3 4B Thinking | `Qwen/Qwen3-4B-Thinking-2507` |

For large models, you may need a provider suffix (e.g. `openai/gpt-oss-120b:fastest`).

### Run live tests

```bash
bal test --groups live_tests
```

Or using Gradle:

```bash
./gradlew clean test -Pgroups=live_tests
```

> **Note:** Some test groups (`metrics`, `sagemaker`, `params`, `types`) are mock-only or unit tests and are not included in `live_tests`.

## Running Tests Against a Custom TGI Instance

Deploy your own TGI instance (e.g. via Docker or a Hugging Face Inference Endpoint) and point the tests at it:

```toml
serviceUrl = "https://your-tgi-endpoint.example.com"
modelId = "your-model-id"
```

```bash
export IS_LIVE_SERVER=true
export TGI_TOKEN="<your-access-token-if-required>"
bal test --groups live_tests
```
