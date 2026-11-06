## Overview

[Hugging Face Text Generation Inference (TGI)](https://huggingface.co/docs/text-generation-inference) is a server for deploying and serving large language models with high performance.

The Hugging Face TGI connector lets Ballerina applications generate text and stream tokens, create OpenAI-compatible chat and text completions, tokenize text and chat conversations, and inspect the health, metrics and model information of a TGI server. It supports version 3.3.6 of the TGI API.

### Key features

- Generate text and stream generated tokens as server-sent events
- Create OpenAI-compatible chat and text completions
- Tokenize plain text and chat conversations with the model's chat template
- Inspect server health, Prometheus metrics and served model information

## Setup guide

To use the Hugging Face TGI connector, you need a running TGI server. If your server does not require authentication, any placeholder token is accepted.

### Step 1: Start a TGI server

1. Install [Docker](https://www.docker.com/get-started) and, for gated models, create a [Hugging Face access token](https://huggingface.co/settings/tokens).

2. Launch the server with the model you want to serve:

   ```bash
   docker run --gpus all --shm-size 1g -p 8080:80 -v $PWD/data:/data \
     -e HF_TOKEN=<your-hugging-face-token> \
     ghcr.io/huggingface/text-generation-inference:latest \
     --model-id <model-id>
   ```

3. Wait until the server finishes downloading and loading the model.

### Step 2: Note the server URL and token

1. The server URL is the address you published, for example `http://localhost:8080`. For a [Hugging Face Inference Endpoint](https://huggingface.co/inference-endpoints), use the endpoint URL.

2. If the server sits behind a gateway or is an Inference Endpoint that requires authentication, create an access token and keep it for the connector configuration.

### Step 3: Verify your setup

```bash
curl http://localhost:8080/info
```

The response describes the model that the server is running.

## Quickstart

To use the Hugging Face TGI connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `huggingface.tgi` module.

```ballerina
import ballerinax/huggingface.tgi;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and configure the server URL and token obtained in the steps above:

```toml
serviceUrl = "<TGI server URL>"
token = "<access token>"
```

2. Create a `tgi:Client` using the configuration:

```ballerina
configurable string serviceUrl = ?;
configurable string token = ?;

final tgi:Client tgiClient = check new ({auth: {token}}, serviceUrl);
```

### Step 3: Invoke the connector operation

1. Generate text for a prompt:

```ballerina
public function main() returns error? {
    tgi:GenerateResponse _ = check tgiClient->generateTokens({inputs: "What is deep learning?"});
}
```

2. Use `bal run` to compile and run the Ballerina program.

## Examples

The `Hugging Face TGI` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/tree/main/examples/), covering the following use cases:

1. [Text generation with a health check](../examples/text_generation_health_check/text_generation_health_check.md) - Check the health of a TGI server, read the model information and generate text from a prompt.

2. [Chat assistant with tokenization](../examples/chat_assistant_tokenization/chat_assistant_tokenization.md) - Count the tokens of a templated chat prompt and ask the served model for a chat completion.
