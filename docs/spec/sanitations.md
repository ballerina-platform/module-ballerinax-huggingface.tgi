_Author_: @HasithaErandika \
_Created_: 2026-06-10 \
_Updated_: 2026-06-18 \
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

## Sanitization 6 - Update default serviceUrl, swap parameter order in `Client.init` (`client.bal`)

**File:** `ballerina/client.bal`  
**Function:** `Client.init`

**Before:**
```ballerina
public isolated function init(string serviceUrl, ConnectionConfig config = {}) returns error? {
    http:ClientConfiguration httpClientConfig = {httpVersion: config.httpVersion, http1Settings: config.http1Settings, http2Settings: config.http2Settings, timeout: config.timeout, forwarded: config.forwarded, followRedirects: config.followRedirects, poolConfig: config.poolConfig, cache: config.cache, compression: config.compression, circuitBreaker: config.circuitBreaker, retryConfig: config.retryConfig, cookieConfig: config.cookieConfig, responseLimits: config.responseLimits, secureSocket: config.secureSocket, proxy: config.proxy, socketConfig: config.socketConfig, validation: config.validation, laxDataBinding: config.laxDataBinding};
```

**After:**
```ballerina
public isolated function init(ConnectionConfig config = {}, string serviceUrl = "https://router.huggingface.co/hf-inference") returns error? {
    http:ClientConfiguration httpClientConfig = {
        auth: config.auth,
        httpVersion: config.httpVersion,
        http1Settings: config.http1Settings,
        http2Settings: config.http2Settings,
        timeout: config.timeout,
        forwarded: config.forwarded,
        followRedirects: config.followRedirects,
        poolConfig: config.poolConfig,
        cache: config.cache,
        compression: config.compression,
        circuitBreaker: config.circuitBreaker,
        retryConfig: config.retryConfig,
        cookieConfig: config.cookieConfig,
        responseLimits: config.responseLimits,
        secureSocket: config.secureSocket,
        proxy: config.proxy,
        socketConfig: config.socketConfig,
        validation: config.validation,
        laxDataBinding: config.laxDataBinding
    };
```

**Reason:** Three related changes were made together:

1. **Parameter order swapped** — `ConnectionConfig config = {}` is now the first parameter and `string serviceUrl` the second. This allows `serviceUrl` to carry a meaningful default value; in Ballerina, a required parameter (`string serviceUrl` with no default) cannot appear after an optional one (`config = {}`), so the order must be `config` first, `serviceUrl` second.

2. **Default `serviceUrl` updated** — Changed from no default (required parameter) to `"https://router.huggingface.co/hf-inference"`. The Hugging Face Inference API has migrated to the router endpoint; the old `api-inference.huggingface.co` endpoint does not resolve. Use `https://router.huggingface.co/hf-inference` for the full TGI API (`/generate`, `/health`, `/info`, `/tokenize`, `/v1/chat/completions`, etc.). Use `https://router.huggingface.co` for OpenAI-style endpoints only (`/v1/chat/completions`, `/v1/models`).

3. **`http:ClientConfiguration` reformatted to multiline** — The single-line initializer was expanded to one field per line for readability, and `auth: config.auth` was added as part of Sanitization 4.

---

## Sanitization 7 - Change HTTP version default to HTTP/1.1 (`types.bal`)

**File:** `ballerina/types.bal`
**Record:** `ConnectionConfig`
**Field:** `httpVersion`

**Before:**
```ballerina
http:HttpVersion httpVersion = http:HTTP_2_0;
```

**After:**
```ballerina
http:HttpVersion httpVersion = http:HTTP_1_1;
```

**Reason:** The Hugging Face router endpoint does not support HTTP/2, causing connection failures when the default HTTP/2 configuration is used.

---

## Sanitization 8 - Make systemFingerprint nullable in ChatCompletion and CompletionFinal (`types.bal`)

**File:** `ballerina/types.bal`
**Records:** `ChatCompletion`, `CompletionFinal`
**Field:** `systemFingerprint`

**Before:**
```ballerina
@jsondata:Name {value: "system_fingerprint"}
string systemFingerprint;
```

**After:**
```ballerina
@jsondata:Name {value: "system_fingerprint"}
string? systemFingerprint;
```

**Reason:** The Hugging Face router returns `null` for `system_fingerprint` in the response for several models (Llama-3.1, gpt-oss, Qwen3), causing deserialization errors or data loss when the field is non-nullable.

---

## Sanitization 9 - Make TextMessage.content nullable (`types.bal`)

**File:** `ballerina/types.bal`
**Record:** `TextMessage`
**Field:** `content`

**Before:**
```ballerina
public type TextMessage record {
    string role;
    @jsondata:Name {value: "tool_call_id"}
    string? toolCallId?;
    string content;
};
```

**After:**
```ballerina
public type TextMessage record {
    string role;
    @jsondata:Name {value: "tool_call_id"}
    string? toolCallId?;
    string? content?;
};
```

**Reason:** When a tool call is returned in a chat completion response, the `content` field may be `null` (OpenAI API spec). This change allows proper deserialization of tool-calling responses.

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
