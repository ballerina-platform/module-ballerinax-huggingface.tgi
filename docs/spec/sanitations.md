_Author_: @HasithaErandika \
_Created_: 2026-06-10 \
_Updated_: 2026-06-17 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Hugging Face Text Generation Inference (TGI).
The OpenAPI specification is obtained from the TGI server's `/openapi.json` endpoint (see `docs/spec/openapi.json`).
These changes are done in order to improve overall usability and as workarounds for known Ballerina OpenAPI tool limitations.

---

## Sanitization 1 - Fix `ChatRequest.responseFormat` default (`types.bal`)

**File:** `ballerina/types.bal`
**Record:** `ChatRequest`
**Field:** `responseFormat`

**Before:**
```ballerina
@jsondata:Name {value: "response_format"}
GrammarType? responseFormat = "null";
```

**After:**
```ballerina
@jsondata:Name {value: "response_format"}
GrammarType? responseFormat = ();
```

**Reason:** The OpenAPI spec uses `"default": "null"` to represent a JSON null/absent value.
The Ballerina OpenAPI tool incorrectly translated this as the string literal `"null"`.
`GrammarType?` resolves to `GrammarType | ()`. A bare string is not assignable to this union,
causing a **compilation error**. The correct Ballerina nil literal is `()`.

---

## Sanitization 2 - Fix `GenerateParameters.grammar` default (`types.bal`)

**File:** `ballerina/types.bal`
**Record:** `GenerateParameters`
**Field:** `grammar`

**Before:**
```ballerina
GrammarType? grammar = "null";
```

**After:**
```ballerina
GrammarType? grammar = ();
```

**Reason:** Identical root cause to Sanitization 1. The string `"null"` is not assignable to
`GrammarType?`, producing a **compilation error**. Corrected to the nil literal `()`.

---

## Sanitization 3 - Fix `GenerateParameters.adapterId` default (`types.bal`)

**File:** `ballerina/types.bal`
**Record:** `GenerateParameters`
**Field:** `adapterId`

**Before:**
```ballerina
@jsondata:Name {value: "adapter_id"}
string? adapterId = "null";
```

**After:**
```ballerina
@jsondata:Name {value: "adapter_id"}
string? adapterId = ();
```

**Reason:** Although `string?` technically accepts the string `"null"`, this is a **semantic runtime bug**.
When no adapter ID is provided, the client would send the literal string `"null"` to the TGI server.
The TGI server would then attempt to load a LoRA adapter named `"null"`, causing the request to crash.
The correct default is `()` (nil/absent), which causes the field to be omitted from the serialized JSON.

---

## Sanitization 4 - Add Bearer token authentication to `ConnectionConfig` and `Client` (`types.bal`, `client.bal`)

**Files:** `ballerina/types.bal`, `ballerina/client.bal`

**Root cause:** TGI endpoints hosted on Hugging Face Inference Endpoints, or serving gated models
(e.g., Llama, Mistral), require an `Authorization: Bearer <HF_TOKEN>` HTTP header.
The auto-generated `ConnectionConfig` contained no auth field, and the `Client.init()` passed
no `auth` config to `http:ClientConfiguration`, making it **impossible to connect to secured endpoints**.

### Change in `types.bal` — Added `auth` field to `ConnectionConfig`

```ballerina
    # Authentication configuration for Hugging Face API.
    # Required for gated models (e.g., Llama) and private/dedicated TGI endpoints.
    # Uses Bearer token authentication.
    # Example: { token: "hf_xxxx" }. Obtain your token at https://huggingface.co/settings/tokens
    @display {label: "HF Auth Config"}
    http:BearerTokenConfig auth?;
```

### Change in `client.bal` — Wire `auth` into `http:ClientConfiguration`

```ballerina
        http:ClientConfiguration httpClientConfig = {
            auth: config.auth,
            // ... all other fields unchanged
        };
```

When `config.auth` is configured (e.g., containing the Hugging Face token), the HTTP client is configured with Bearer token authentication, causing the `Authorization: Bearer <token>` header to be injected automatically into every request. When no auth is provided, no authorization header is sent, preserving backwards compatibility with public/local endpoints.

---

## Sanitization 5 - Refactor and close Message type to enforce oneOf constraint (`types.bal`)

**File:** `ballerina/types.bal`  
**Record:** `Message`

**Before:**
```ballerina
public type Message record {
    *MessageBody;
    string role;
    string? name?;
};
```

**After:**
```ballerina
public type MessageWithContent record {|
    # Message content (text string or array of content chunks)
    MessageContent content;
    string role;
    string? name?;
|};

public type MessageWithToolCalls record {|
    # Tool calls made by the assistant (mutually exclusive with content)
    @jsondata:Name {value: "tool_calls"}
    ToolCall[] toolCalls;
    string role;
    string? name?;
|};

public type Message MessageWithContent|MessageWithToolCalls;
```

**Reason:**  
The auto-generated `Message` record used `*MessageBody` (record inclusion), but `MessageBody` is a union type (`MessageBodyOneOf1|MessageBodyMessageBodyOneOf12`), which is illegal for record inclusion in Ballerina. This sanitization removes the illegal inclusion and replaces `Message` with two closed, mutually exclusive records and a union alias, properly enforcing the OpenAPI `oneOf` constraint: a message carries either `content` or `tool_calls`, never both.

---

## File headers

Both `types.bal` and `client.bal` had their `// AUTO-GENERATED FILE. DO NOT MODIFY.` banner replaced
with:

```ballerina
// Generated by Ballerina OpenAPI tool and manually sanitized.
// See docs/spec/sanitations.md for changes made post-generation.
```

This signals to future maintainers that the files have intentional manual edits that must not be
blindly overwritten by re-running `bal openapi`.

---

## OpenAPI CLI commands

The following commands were used to generate the initial Ballerina client from the OpenAPI specification.
Run from the repository root directory:

**Step 1 - Flatten the OpenAPI definition:**
```bash
bal openapi flatten -i docs/spec/openapi.json -o docs/spec
```

**Step 2 - Align the flattened definition:**
```bash
bal openapi align -i docs/spec/flattened_openapi.json -o docs/spec
```

After these steps, remove `openapi.json` and `flattened_openapi.json` from `docs/spec/` and rename `aligned_ballerina_openapi.json` to `openapi.json`.

**Step 3 - Generate the Ballerina client:**
```bash
bal openapi -i docs/spec/openapi.json --mode client --license docs/license.txt -o ballerina/
```

Note: The license year is hardcoded to 2024 in the generated header; update if necessary.
---
