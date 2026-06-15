# Examples

The `ballerinax/huggingface.tgi` connector provides practical examples illustrating usage in various scenarios.

1. **Text Generation** - Native `/generate` endpoint with fine-grained sampling control (temperature, top-k, top-p, repetition penalty)
2. **Token Counter** - Using `/tokenize` and `/info` endpoints to count tokens and check context windows

## Prerequisites

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
