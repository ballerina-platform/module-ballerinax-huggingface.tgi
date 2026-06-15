## Overview

[Hugging Face Text Generation Inference (TGI)](https://huggingface.co/docs/text-generation-inference/index) is a purpose-built solution for deploying and serving Large Language Models (LLMs) in production. It enables high-performance text generation on models like Llama, Mistral, Falcon, and Qwen.

The `ballerinax/huggingface.tgi` package offers functionality to connect and interact with the TGI REST API, enabling seamless integration of advanced text generation, chat completions, tokenization, and model metadata retrieval into your applications.

### Key Features

- Native `/generate` and `/generate_stream` endpoints with fine-grained sampling control (temperature, top-k, top-p, stop sequences, repetition penalty)
- OpenAI-compatible chat completions via `/v1/chat/completions` (drop-in replacement for OpenAI SDK users)
- OpenAI-compatible completions via `/v1/completions`
- Tokenization via `/tokenize` and `/chat_tokenize` to inspect and manage model context limits
- Prometheus metrics scraping via `/metrics`, model info via `/info` and `/v1/models`, and health check via `/health`

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

You can either:

- Use the **Hugging Face Inference API** at `https://api-inference.huggingface.co` for serverless inference on hosted models.
- Deploy your own **TGI instance** and point the connector at your own service URL.

## Quickstart

To use the `ballerinax/huggingface.tgi` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `ballerinax/huggingface.tgi` module.

```ballerina
import ballerinax/huggingface.tgi;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the obtained token as follows:

```toml
token = "<Your Hugging Face API Token>"
```

2. Initialize the connector using `tgi:ConnectionConfig` with the access token.

```ballerina
configurable string token = ?;

final tgi:Client hfClient = check new ({
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
        temperature: 0.7
    });
}
```

#### Generate text

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
