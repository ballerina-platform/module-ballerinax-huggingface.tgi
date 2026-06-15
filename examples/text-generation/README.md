# Text Generation

This example demonstrates how to use the TGI native `/generate` endpoint to perform raw text completion with fine-grained sampling control (temperature, top-k, top-p, repetition penalty). This is useful when you need maximum control over the generation process beyond the chat interface.

## Prerequisites

- A running TGI instance
- Set `serviceUrl` in `Config.toml`

## Running the example

```bash
bal run
```

## Sample output

The example shows three use cases:
1. **Creative writing** with high temperature (0.9)
2. **Factual completion** with low temperature (0.2)
3. **Code generation** with stop sequences