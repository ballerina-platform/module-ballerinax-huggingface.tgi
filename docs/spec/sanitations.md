_Author_: @HasithaErandika \
_Created_: 2026-06-10 \
_Updated_: 2026-06-23 \
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

## Sanitization 6 - Swap parameter order and make serviceUrl required in `Client.init` (`client.bal`)

**File:** `ballerina/client.bal`  
**Function:** `Client.init`

**Before:**
```ballerina
public isolated function init(string serviceUrl, ConnectionConfig config = {}) returns error? {
    http:ClientConfiguration httpClientConfig = {httpVersion: config.httpVersion, http1Settings: config.http1Settings, http2Settings: config.http2Settings, timeout: config.timeout, forwarded: config.forwarded, followRedirects: config.followRedirects, poolConfig: config.poolConfig, cache: config.cache, compression: config.compression, circuitBreaker: config.circuitBreaker, retryConfig: config.retryConfig, cookieConfig: config.cookieConfig, responseLimits: config.responseLimits, secureSocket: config.secureSocket, proxy: config.proxy, socketConfig: config.socketConfig, validation: config.validation, laxDataBinding: config.laxDataBinding};
```

**After:**
```ballerina
public isolated function init(ConnectionConfig config = {}, string serviceUrl) returns error? {
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

1. **Parameter order swapped** — `ConnectionConfig config = {}` is now the first parameter and `string serviceUrl` the second. This is because in Ballerina, a required parameter (`string serviceUrl` with no default) cannot appear after an optional one (`config = {}`), so the order must be `config` first, `serviceUrl` second.

2. **`serviceUrl` is now required with no default** — The default value has been removed, making `serviceUrl` a required parameter. The recommended endpoint URLs are documented in the function's doc comments.

3. **`http:ClientConfiguration` reformatted to multiline** — The single-line initializer was expanded to one field per line for readability, and `auth: config.auth` was added as part of Sanitization 4.

---

## Sanitization 7 - Make systemFingerprint nullable in ChatCompletion and CompletionFinal (`types.bal`)

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

## Sanitization 8 - Make TextMessage.content nullable (`types.bal`)

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

## Sanitization 9 - Rename `FunctionDefinition.arguments` to `parameters` (`types.bal`)

**File:** `ballerina/types.bal`
**Record:** `FunctionDefinition`
**Field:** `arguments` → `parameters`

**Before:**
```ballerina
anydata arguments;
```

**After:**
```ballerina
@jsondata:Name {value: "parameters"}
map<json> parameters?;
```

**Reason:** The OpenAI tool-calling specification requires the tool schema field to be named
`"parameters"` in serialized JSON. The auto-generated connector used `arguments` with no
`@jsondata:Name` override, causing it to serialize as `"arguments"` instead. OpenAI-compatible
providers such as Cerebras and Groq validate the tool schema strictly and reject requests
containing `"arguments"`, breaking all tool-calling functionality on `/v1/chat/completions`.

---

## Sanitization 10 - Split `ToolCall.function` into its own type instead of reusing `FunctionDefinition` (`types.bal`)

**File:** `ballerina/types.bal`
**Records:** `ToolCall`, `ToolCallFunction` (new)

**Before:**
```ballerina
public type ToolCall record {
    FunctionDefinition 'function;
    string id;
    string 'type;
};
```

**After:**
```ballerina
public type ToolCall record {
    ToolCallFunction 'function;
    string id;
    string 'type;
};

public type ToolCallFunction record {
    string name;
    string arguments;
};
```

**Reason:** The upstream OpenAPI spec (and the originally generated connector) reused `FunctionDefinition`
for both the tool schema a client *sends* (`Tool.function`, needs `parameters` as a JSON Schema object) and
the tool call a model *returns* (`ToolCall.function`). These are not the same shape. TGI's own server
(`router/src/lib.rs`) serializes a returned function call as `{"name": ..., "arguments": "<JSON-encoded string>"}`
- this is also how OpenAI, Groq, and Cerebras represent it. After Sanitization 9 renamed the shared field to
`parameters: map<json>`, `ToolCall.function` could no longer bind a real tool-call response: the JSON key is
`arguments`, not `parameters`, and the value is a string, not an object. Without this split, any model that
actually invokes a tool would silently fail to deserialize its arguments. The official
`ballerinax/openai.chat` connector follows the same pattern (`FunctionObject` for requests,
`ChatCompletionMessageToolCall_function` for responses), which this change mirrors.

---

## Sanitization 11 - Reorder `OutputMessage` union so `ToolCallMessage` is tried before `TextMessage` (`types.bal`)

**File:** `ballerina/types.bal`
**Type:** `OutputMessage`

**Before:**
```ballerina
public type OutputMessage TextMessage|ToolCallMessage;
```

**After:**
```ballerina
public type OutputMessage ToolCallMessage|TextMessage;
```

**Reason:** Discovered while adding test coverage for Sanitization 10 - a mock tool-call response
(`{"role": "assistant", "tool_calls": [...]}`) was binding to `TextMessage` instead of `ToolCallMessage`,
silently dropping the tool call. Both records are open and `TextMessage` declares no required fields
besides `role`, so when a union is data-bound, Ballerina tries members in declaration order and accepts
the first structural match - `TextMessage` matched every response, tool call or not, because its open
shape ignores the unrecognized `tool_calls` field. Listing `ToolCallMessage` first means its required,
non-nilable `toolCalls` field must bind successfully (and a plain-text response, where `tool_calls` is
absent or `null`, correctly fails that and falls through to `TextMessage`). This is a precondition for
Sanitization 10 actually taking effect at runtime.

---

## Sanitization 12 - Fix `ChatRequest.toolChoice` default from `"auto"` to `()` (`types.bal`)

**File:** `ballerina/types.bal`
**Record:** `ChatRequest`
**Field:** `toolChoice`

**Before:**
```ballerina
@jsondata:Name {value: "tool_choice"}
ToolChoice? toolChoice = "auto";
```

**After:**
```ballerina
@jsondata:Name {value: "tool_choice"}
ToolChoice? toolChoice = ();
```

**Reason:** Discovered live, against Cerebras,a plain`testChatCompletionsBasic` request with 
no `tools` at all was rejected with `"Tools were requested but notools found in request."` 
(`code: "wrong_api_format"`). The OpenAPI spec marks `tool_choice`'s default as
`"auto"` to document the *server's* fallback behavior when the field is absent, the same root cause as
Sanitizations 1-3. The generated connector instead used it as a Ballerina field default, so every
`ChatRequest` — even ones that never touch `tools`/`toolChoice` - explicitly serialized `"tool_choice":
"auto"`. Confirmed directly against the live API: Cerebras accepts `"tool_choice": null` (or the key
omitted) without `tools`, but rejects any non-null value (e.g. `"auto"`) when `tools` is absent. Changing
the default to `()` means the field serializes as `null` (or is omitted) unless the caller sets it,
matching what the server actually tolerates, while still allowing `"auto"`/`"required"` to be sent
explicitly when `tools` is also provided.

---

## Sanitization 13 - Add `toolCallId` to `MessageWithContent` (`types.bal`)

**File:** `ballerina/types.bal`
**Record:** `MessageWithContent`

**Before:**
```ballerina
public type MessageWithContent record {|
    # Message content (text string or array of content chunks)
    MessageContent content;
    string role;
    string? name?;
|};
```

**After:**
```ballerina
public type MessageWithContent record {|
    # Message content (text string or array of content chunks)
    MessageContent content;
    string role;
    string? name?;
    # The ID of the tool call this message is responding to. Required when `role` is `"tool"` —
    # OpenAI-compatible providers (e.g. Cerebras) reject a tool-result message without it.
    @jsondata:Name {value: "tool_call_id"}
    string? toolCallId?;
|};
```

**Reason:** Discovered while writing a full tool-calling round-trip test (request → model calls a tool →
client sends the tool's result back → model answers using it). The upstream OpenAPI spec's request-side
`Message`/`MessageBody` schema has no `tool_call_id` field at all — confirmed in TGI's own Rust source
(`router/src/lib.rs`, `struct Message`), which only carries `role`, `body` (`Content` or `Tool`), and `name`.
That's a real gap in TGI's own native API, not just the Ballerina generator: TGI has no way to receive a
`"tool"`-role message that says *which* tool call it's answering. OpenAI-compatible providers don't share
that limitation and require it — confirmed live against Cerebras, a `"tool"`-role message without
`tool_call_id` is rejected outright (`"messages.2.tool.tool_call_id: Field required"`), while the same
request with it succeeds end-to-end. Without this field, this connector could not construct a valid
multi-turn tool-calling conversation against any third-party OpenAI-compatible provider. `MessageWithToolCalls` doesn't need the same treatment: it represents the
*assistant's* tool-calling turn, which carries `tool_calls` (each with its own `id`), not a single
`tool_call_id`.

---

## Sanitization 14 - Add missing `type` field to `ToolChoiceToolChoiceToolChoiceToolChoiceOneOf1234` (`types.bal`)

**File:** `ballerina/types.bal`
**Record:** `ToolChoiceToolChoiceToolChoiceToolChoiceOneOf1234` (the forced-specific-tool form of `ToolChoice`)

**Before:**
```ballerina
public type ToolChoiceToolChoiceToolChoiceToolChoiceOneOf1234 record {
    FunctionName 'function;
};
```

**After:**
```ballerina
public type ToolChoiceToolChoiceToolChoiceToolChoiceOneOf1234 record {
    FunctionName 'function;
    "function" 'type = "function";
};
```

**Reason:** Discovered live, against Cerebras, while testing a forced specific tool choice
(`toolChoice: {'function: {name: "..."}}`). Cerebras rejected the request:
`"tool_choice.ChoiceObject.type: Field required"`. The upstream OpenAPI spec's
`ToolChoiceToolChoiceToolChoiceToolChoiceOneOf1234` schema only declares `function`, omitting `type` —
even though TGI's own Rust source (`router/src/lib.rs`) documents the correct shape in a doc comment:
`{"type": "function", "function": {"name": "my_function"}}`. This is an upstream OpenAPI spec gap (the
schema doesn't match TGI's own documented format), faithfully but incompletely translated into the
generated connector. Without `type`, this connector could not actually force a specific tool against any
OpenAI-compatible provider that validates strictly. Defaulted to `"function"` (the only valid value) so
callers don't need to set it.

---

## Sanitization 15 - Replace the `OutputMessage` union with a single flat type (`types.bal`)

**File:** `ballerina/types.bal`
**Types:** `OutputMessage` (was `ToolCallMessage|TextMessage`), `ToolCallMessage` and `TextMessage` removed

**Before:**
```ballerina
public type TextMessage record {
    string role;
    @jsondata:Name {value: "tool_call_id"}
    string? toolCallId?;
    string? content?;
};

public type ToolCallMessage record {
    string role;
    @jsondata:Name {value: "tool_calls"}
    ToolCall[] toolCalls;
};

public type OutputMessage ToolCallMessage|TextMessage;
```

**After:**
```ballerina
public type OutputMessage record {
    string role;
    string? content?;
    @jsondata:Name {value: "tool_calls"}
    ToolCall[]? toolCalls?;
};
```

**Reason:** Sanitization 11's reordering fix (`ToolCallMessage` before `TextMessage`) assumed a provider would
either omit `tool_calls` or send it as `null` when not calling a tool. That assumption broke live, against
Cerebras: a plain-text answer sometimes includes a redundant `"tool_calls": []` (present, but empty)
alongside real `"content"`. Since `ToolCallMessage.toolCalls` only required the array to be *present*, an
empty array still satisfied it, so the union picked `ToolCallMessage` and silently dropped the real answer
text. Adding `@constraint:Array {minLength: 1}` to `toolCalls` was tried and confirmed **not** to fix this —
constraint validation does not participate in union-member candidate selection during JSON data binding;
the structural match still wins regardless of array length, confirmed by reproducing the exact scenario
deterministically against the mock server. Since real providers don't reliably treat `content` and
`tool_calls` as mutually exclusive (Cerebras and Nscale have both been observed sending both together —
once with real tool-call content, once with a redundant empty array), modeling this as a `oneOf` union is
fighting reality. A single permissive type matches what's actually observed and removes the dependency on
union member ordering entirely. Callers now check `toolCalls is ToolCall[] && toolCalls.length() > 0`
instead of `is ToolCallMessage`/`is TextMessage`.

---

## Sanitization 16 - Add `ModelList` and widen `Client->/v1/models()`'s return type (`types.bal`, `client.bal`)

**File:** `ballerina/types.bal`, `ballerina/client.bal`
**Resource:** `get v1/models`

**Before:**
```ballerina
resource isolated function get v1/models(map<string|string[]> headers = {}) returns ModelInfo|error {
```

**After:**
```ballerina
public type ModelList record {
    string 'object;
    ModelInfo[] data;
};

resource isolated function get v1/models(map<string|string[]> headers = {}) returns ModelInfo|ModelList|error {
```

**Reason:** Confirmed live: `GET /v1/models` against a dedicated TGI server returns a single flat
`ModelInfo` object (matching the upstream OpenAPI spec, written for a single-model TGI deployment), but the
same call against `https://router.huggingface.co` returns an OpenAI-style catalog —
`{"object": "list", "data": [ModelInfo, ...]}` — listing every model across every Inference Provider. The
connector only declared the single-object shape, so calling this against the router failed with a payload
binding error (`required field 'created' not present in JSON`). `ModelInfo` is tried first in the union: its
required fields (`created`, `owned_by`, `id`) are absent at the top level of a list response, so it
correctly fails to bind and falls through to `ModelList` — no ordering ambiguity, since the two shapes don't
overlap.

---

## Sanitization 17 - Add `bytes` field to `ChatCompletionLogprob` and `ChatCompletionTopLogprob` (`types.bal`)

**File:** `ballerina/types.bal`
**Records:** `ChatCompletionLogprob`, `ChatCompletionTopLogprob`
**Field:** `bytes` (new)

**Before:**
```ballerina
public type ChatCompletionLogprob record {
    @jsondata:Name {value: "top_logprobs"}
    ChatCompletionTopLogprob[] topLogprobs;
    float logprob;
    string token;
};

public type ChatCompletionTopLogprob record {
    float logprob;
    string token;
};
```

**After:**
```ballerina
public type ChatCompletionLogprob record {
    @jsondata:Name {value: "top_logprobs"}
    ChatCompletionTopLogprob[] topLogprobs;
    float logprob;
    string token;
    int[]? bytes?;
};

public type ChatCompletionTopLogprob record {
    float logprob;
    string token;
    int[]? bytes?;
};
```

**Reason:** Confirmed live against `zai-org/GLM-5.2` via `https://router.huggingface.co`: the provider's
`/v1/chat/completions` response includes a `bytes` field per logprob token entry (e.g. `"bytes": null`),
matching OpenAI's own chat-completions logprobs schema. TGI's upstream OpenAPI spec — which these records
are generated from — doesn't define `bytes` at all, and both records were closed with no rest field, so
binding the response failed entirely as soon as a fully OpenAI-compatible provider populated it. Declaring
`bytes` as an optional, nullable `int[]?` lets the field bind when present (`null` or an array of byte
values) without requiring it from providers that omit it.

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
