## Overview

[Hugging Face Text Generation Inference (TGI)](https://huggingface.co/docs/text-generation-inference/index) is a purpose-built solution for deploying and serving Large Language Models (LLMs) in production. It enables high-performance text generation on models like Llama, Mistral, Falcon, and Qwen.

The `ballerinax/huggingface.tgi` package offers functionality to connect and interact with the TGI REST API, enabling seamless integration of advanced text generation, chat completions, tokenization, and model metadata retrieval into your applications.

### Key Features

- Native `/generate` and `/generate_stream` endpoints with fine-grained sampling control (temperature, top-k, top-p, stop sequences, repetition penalty)
- OpenAI-compatible chat completions via `/v1/chat/completions`, including tool/function calling, forced tool choice, and logprobs (drop-in replacement for OpenAI SDK users)
- OpenAI-compatible completions via `/v1/completions`
- Tokenization via `/tokenize` and `/chat_tokenize` to inspect and manage model context limits
- Prometheus metrics scraping via `/metrics`, model info via `/info` and `/v1/models`, and health check via `/health`
- SageMaker-compatible inference via `/invocations`

## Setup guide

To use the Hugging Face TGI connector, you need a Hugging Face account and an API token. If you do not have an account, sign up at [huggingface.co](https://huggingface.co/join).

### Step 1: Create a Hugging Face Account

1. Go to [https://huggingface.co/join](https://huggingface.co/join) and create an account.
2. Verify your email address and log in to the Hugging Face Hub.

### Step 2: Generate an Access Token

1. Navigate to your profile settings by clicking your avatar in the top-right corner and selecting **Settings**.
2. In the left sidebar, click on **Access Tokens**.
3. Click **New token**, give it a name, select the appropriate role (`read` is sufficient for inference), and click **Generate a token**.
4. Copy the generated token immediately — it will not be shown again.

### Step 3: Choose a Model Endpoint

You can connect to Hugging Face serverless inference or deploy your own TGI instance. Verified live against
the real API:

| Base URL | What works |
|---|---|
| `https://router.huggingface.co` | OpenAI-style `/v1/chat/completions`, routed to **any** Inference Provider (Cerebras, Groq, Nscale, Together, etc.) based on the model. This is the only base URL needed for chat completions and tool calling. |
| Your own **TGI instance** (Docker, or a dedicated Hugging Face Inference Endpoint URL) | The full native TGI API: `/generate`, `/health`, `/info`, `/tokenize`, `/generate_stream`, etc. |

> **Important:** `https://router.huggingface.co/hf-inference` is **not** a usable base URL for this connector
> against most models. It is one specific Inference Provider (HF's own infrastructure), which as of mid-2025
> mostly serves small/legacy models (BERT, GPT-2, etc.), not modern chat models — and even where a model is
> hosted there, neither the native TGI paths nor the OpenAI-style paths (`/v1/chat/completions`,
> `/v1/models`) are exposed through the shared router at that path. To reach Groq, Cerebras, Nscale, or any
> other third-party provider, use the bare `https://router.huggingface.co` base URL with `/v1/chat/completions`.

> **Note:** The legacy `https://api-inference.huggingface.co` endpoint has been decommissioned and no longer resolves.

You can either:

- Use **Hugging Face Inference Providers** at `https://router.huggingface.co` for serverless chat completions across any provider (requires a token with Inference Providers permission).
- Deploy your own **TGI instance** (Docker, Hugging Face Inference Endpoint, etc.) and point the connector at your service URL to use the full native TGI API (`/generate`, `/tokenize`, `/health`, `/info`, etc.).

## Quickstart

To use the `ballerinax/huggingface.tgi` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `ballerinax/huggingface.tgi` module.

```ballerina
import ballerinax/huggingface.tgi;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the token and service URL as follows:

```toml
token = "<Your Hugging Face API Token>"
serviceUrl = "https://router.huggingface.co"
```

2. Initialize the connector using the target service URL and `tgi:ConnectionConfig` with the access token:

```ballerina
configurable string token = ?;
configurable string serviceUrl = ?;

final tgi:Client hfClient = check new (serviceUrl, {
    auth: {
        token: token
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Run a chat completion

```ballerina
public function main() returns error? {
    tgi:ChatCompletion completion = check hfClient->/v1/chat/completions.post({
        messages: [{role: "user", content: "What is Deep Learning?"}],
        model: "meta-llama/Llama-3.1-8B-Instruct",
        temperature: 0.7
    });
}
```

#### Generate text

`/generate` and the other native TGI endpoints (`/health`, `/info`, `/tokenize`, `/generate_stream`, etc.)
are not exposed through `https://router.huggingface.co` — they require a dedicated TGI deployment
(Docker, or a Hugging Face Inference Endpoint), so use that deployment's own URL as `serviceUrl` for this call:

```ballerina
public function main() returns error? {
    tgi:GenerateResponse resp = check hfClient->/generate.post({
        inputs: "Once upon a time",
        parameters: {maxNewTokens: 50}
    });
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Examples

The `huggingface.tgi` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/tree/main/examples/), covering the following use cases:

1. **Text Generation** - Demonstrates native `/generate` endpoint with sampling control for creative writing, factual completion, and code generation
2. **Token Counter** - Shows how to use `/tokenize` and `/info` endpoints to count tokens and check against model context windows
