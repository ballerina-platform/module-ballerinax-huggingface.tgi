# Examples

The `ballerinax/huggingface.tgi` connector provides practical examples illustrating usage in various scenarios.

1. **[Text generation with a health check](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/tree/main/examples/text_generation_health_check)** - Check the health of a TGI server, read the model information and generate text from a prompt.

2. **[Chat assistant with tokenization](https://github.com/ballerina-platform/module-ballerinax-huggingface.tgi/tree/main/examples/chat_assistant_tokenization)** - Count the tokens of a templated chat prompt and ask the served model for a chat completion.

## Prerequisites

1. Start a TGI server and note its URL as described in the [Setup guide](https://central.ballerina.io/ballerinax/huggingface.tgi/latest#setup-guide).

2. For each example, create a `Config.toml` file with the related configuration. Here's an example of how your Config.toml file should look:

```toml
serviceUrl = "<tgi-server-url>"
token = "<access-token>"
```

Each example lists the additional values it needs in its own README.

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

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
