# Ballerina Hugging Face TGI connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/actions/workflows/ci.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-huggingface.tgi.svg)](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/commits/main)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/huggingface.tgi.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Fhuggingface.tgi)

## Overview

[Hugging Face Text Generation Inference (TGI)](https://huggingface.co/docs/text-generation-inference) is a server for deploying and serving large language models with high performance.

The Hugging Face TGI connector lets Ballerina applications generate text and stream tokens, create OpenAI-compatible chat and text completions, tokenize text and chat conversations, and inspect the health, metrics and model information of a TGI server. It supports version 3.3.6 of the TGI API.

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

1. [Text generation with a health check](examples/text_generation_health_check/text_generation_health_check.md) - Check the health of a TGI server, read the model information and generate text from a prompt.

2. [Chat assistant with tokenization](examples/chat_assistant_tokenization/chat_assistant_tokenization.md) - Count the tokens of a templated chat prompt and ask the served model for a chat completion.

## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To run tests against different environments:

   ```bash
   ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`huggingface.tgi` package](https://central.ballerina.io/ballerinax/huggingface.tgi/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
