# Running Tests

## Prerequisites

You need a Hugging Face access token.

To obtain this, refer to the [Hugging Face Settings](https://huggingface.co/settings/tokens).

## Test Environments

The tests can run against two different environments:
1. **Mock Server** (Default Environment) - A local mock server running on port 9090.
2. **Live Hugging Face API** - The actual Hugging Face Inference Endpoint or a custom TGI instance.

## Running Tests in the Mock Server

To execute the tests on the mock server:
No extra configuration is needed as the tests will use the mock server on `http://localhost:9090` by default.

Run the following command to execute the tests:

```bash
bal test
```

Or using Gradle:

```bash
./gradlew clean test
```

## Running Tests Against the Live Hugging Face API or a Custom TGI Instance

### Using a `Config.toml` File

Create or update the `Config.toml` file in the `tests` directory with the following content:

```toml
serviceUrl = "https://api-inference.huggingface.co"
token = "<your-huggingface-access-token>"
```

Then, run the tests:

```bash
bal test
```

Or using Gradle:

```bash
./gradlew clean test
```
