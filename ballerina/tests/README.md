# Running Tests

## Test approach

The test suite runs against a local mock of the Text Generation Inference API on port 9090 and covers every operation of the client: health, server info, metrics, model listing, token generation (including the compatibility and streaming modes), tokenization of text and chat requests, chat and text completions, and the Sagemaker compatible invocation.

## Running the tests

1. To run the tests against the mock server:

   ```bash
   bal test --groups mock_tests
   ```

2. To run the tests against a live TGI server, set the following environment variables:

   ```bash
   export IS_LIVE_SERVER=true
   export TGI_SERVICE_URL=<tgi-server-url>
   export TGI_TOKEN=<access-token>
   bal test --groups live_tests
   ```
