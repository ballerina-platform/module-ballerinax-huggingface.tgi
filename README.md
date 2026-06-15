# module-ballerinax-huggingface.tgi
Ballerina connector for Hugging Face Text Generation Inference (TGI)

[![Build](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/actions/workflows/ci.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-huggingface.tgi.svg)](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/commits/master)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/module-ballerinax-huggingface.tgi.svg?label=Open%20Issues)](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/issues)

## Overview

HuggingFace Text Generation Inference (TGI) is a high-performance serving framework for large language models. It powers HuggingFace Inference Endpoints and supports models such as Llama, Mistral, Qwen, Falcon, and more.

The `ballerinax/huggingface.tgi` connector provides a Ballerina client for the TGI REST API, covering:

- OpenAI-compatible chat via `/v1/chat/completions` (drop-in replacement for OpenAI SDK users)
- OpenAI-compatible completions via `/v1/completions`
- TGI native generation via `/generate` with full sampling control
- Streaming generation via `/generate_stream` (Server-Sent Events)
- Tokenization via `/tokenize` and `/chat_tokenize`
- Model & server info via `/info` and `/v1/models`
- Health check via `/health`

Note: For text embeddings, reranking, and classification, see `ballerinax/huggingface.tei`.

## Setup guide

To use the Hugging Face connector, you need a Hugging Face account and an API token. If you do not have an account, sign up at [huggingface.co](https://huggingface.co/join).

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

## Issues and projects

The **Issues** and **Projects** tabs are available for this repository. To report bugs, request new features, or start discussions, visit the [Issues](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/issues) page.

## Building from the source

### Prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows:

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

3. To build without the tests:

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

## Contributing to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, see the [Contribution Guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`huggingface.tgi` package](https://central.ballerina.io/ballerinax/huggingface.tgi/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
