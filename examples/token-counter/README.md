# Token Counter

This example demonstrates how to use the `/tokenize` and `/info` endpoints to count tokens before sending a request, check against the model's context window, and decide whether to truncate or chunk the input. This is a critical pattern for production systems to avoid unexpected 422 errors.

## Prerequisites

- A running TGI instance, or Hugging Face Inference Providers at `https://router.huggingface.co/hf-inference`
- Set `serviceUrl` and `token` in `Config.toml`:

```toml
token = "<Your Hugging Face API Token>"
serviceUrl = "https://router.huggingface.co/hf-inference"
```

> **Note:** The legacy `https://api-inference.huggingface.co` endpoint has been decommissioned. See the [base URL guide](../../README.md#step-3-choose-a-model-endpoint) for details on router endpoints.

## Running the example

```bash
bal run
```

## Sample output

The example shows three test cases:
1. **Short prompt** - Fits comfortably within context window
2. **Medium prompt** - Fits but close to limit
3. **Chat template tokenization** - Shows how chat messages are tokenized with the template applied
   