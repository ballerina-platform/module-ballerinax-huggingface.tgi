# Token Counter

This example demonstrates how to use the `/tokenize` and `/info` endpoints to count tokens before sending a request, check against the model's context window, and decide whether to truncate or chunk the input. This is a critical pattern for production systems to avoid unexpected 422 errors.

## Prerequisites

- A running TGI instance
- Set `serviceUrl` in `Config.toml`

## Running the example

```bash
bal run
```

## Sample output

The example shows three test cases:
1. **Short prompt** - Fits comfortably within context window
2. **Medium prompt** - Fits but close to limit
3. **Chat template tokenization** - Shows how chat messages are tokenized with the template applied