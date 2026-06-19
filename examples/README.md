# Examples

The `ballerinax/huggingface.tgi` connector provides practical examples illustrating usage in various scenarios.

1. **Text Generation** - Native `/generate` endpoint with fine-grained sampling control (temperature, top-k, top-p, repetition penalty)
2. **Token Counter** - Using `/tokenize` and `/info` endpoints to count tokens and check context windows

## Prerequisites

| Base URL | What works |
|---|---|
| `https://router.huggingface.co` | OpenAI-style `/v1/chat/completions`, `/v1/models` |
| `https://router.huggingface.co/hf-inference` | Full TGI API: `/generate`, `/health`, `/info`, `/tokenize`, `/v1/chat/completions`, etc. |

Each example requires a `Config.toml` with `serviceUrl` and, for Hugging Face serverless inference, a `token`. See the individual example READMEs for details.
## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the build scripts may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

    On Windows:

    ```batch
    build.bat build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```

    On Windows:

    ```batch
    build.bat run
    ```
