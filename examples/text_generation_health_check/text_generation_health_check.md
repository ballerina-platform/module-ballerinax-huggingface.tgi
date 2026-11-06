# Text generation with a health check

This example checks that a Text Generation Inference server is healthy, prints the model and limits of the running server, and generates text from a prompt.

## Prerequisites

### 1. Run a TGI server

Follow the [Setup guide](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/blob/main/ballerina/README.md#setup-guide) to start a server and note its URL.

### 2. Configuration

Create a `Config.toml` file in this example's directory with the following content:

```toml
serviceUrl = "<tgi-server-url>"
token = "<access-token>"
prompt = "What is deep learning?"
maxNewTokens = 64
```

## Run the example

Execute the following command to run the example:

```bash
bal run
```
