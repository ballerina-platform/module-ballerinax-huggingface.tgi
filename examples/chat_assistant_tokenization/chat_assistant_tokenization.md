# Chat assistant with tokenization

This example finds the model served by a Text Generation Inference endpoint, counts the tokens of a question after the chat template is applied, and asks the model for a chat completion.

## Prerequisites

### 1. Run a TGI server

Follow the [Setup guide](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/blob/main/ballerina/README.md#setup-guide) to start a server with a chat model and note its URL.

### 2. Configuration

Create a `Config.toml` file in this example's directory with the following content:

```toml
serviceUrl = "<tgi-server-url>"
token = "<access-token>"
question = "What is the capital of France?"
maxTokens = 128
```

## Run the example

Execute the following command to run the example:

```bash
bal run
```
