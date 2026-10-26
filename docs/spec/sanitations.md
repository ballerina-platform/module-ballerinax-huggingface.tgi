_Author_:  @DimuthuMadushan \
_Created_: 2026/10/26 \
_Updated_: 2026/10/26 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Hugging Face Text Generation Inference.
The OpenAPI specification is obtained from https://github.com/wso2/api-specs/blob/main/openapi/huggingface/tgi/3.3.6-dev0/openapi.json.
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

1. Added a `BearerAuth` security scheme (`http`, `bearer`) under `components.securitySchemes` and a top-level `security` requirement, because the original spec declares no authentication. The change was made in the original spec `docs/spec/openapi.json`.

2. Added a `servers` entry (`http://localhost:8080`) so the client has a default service URL, because the original spec declares none. The change was made in the original spec `docs/spec/openapi.json`.

3. Rewrote `info.description` as a short plain-text summary of what the connector does, since it becomes the `Client` class documentation. The change was made in the original spec `docs/spec/openapi.json`.

4. Added missing descriptions to 54 schemas, 137 properties, 8 request bodies and 12 operations (summary and description); the filled text is listed in `docs/spec/description-decisions.json`. This keeps `bal build` free of `undocumented field` warnings. The change was made in the original spec `docs/spec/openapi.json`.

5. Made the operation summaries of `POST /v1/chat/completions` ("Create a chat completion") and `POST /v1/completions` ("Create a text completion") distinct; both were "Generate tokens", as was `POST /generate`. The change was made in the original spec `docs/spec/openapi.json`.

6. Removed `default: "null"` from every nullable property (for example `GenerateParameters.adapter_id`, `GenerateParameters.grammar`, `ChatRequest.response_format`). The string default generated `string? adapterId = "null"` and assigned a string to `GrammarType?` fields, which does not compile. The change was made in the original spec `docs/spec/openapi.json`.

7. Replaced the `allOf` member `$ref: MessageBody` (a `oneOf` of content or tool calls) in the `Message` schema with an inline object holding optional `content` and `tool_calls` properties, because a record cannot include a union type. The change was made in the original spec `docs/spec/openapi.json`.

8. Renamed the operations and the union member schemas through `ai-mappings.json`. Operations: `compat_generate` to `generateCompat`, `get_chat_tokenize` to `tokenizeChat`, `generate` to `generateTokens`, `generate_stream` to `streamTokens`, `health` to `checkHealth`, `get_model_info` to `getInfo`, `sagemaker_compatibility` to `invokeSagemaker`, `metrics` to `getMetrics`, `tokenize` to `tokenizeText`, `chat_completions` to `createChatCompletion`, `completions` to `createCompletion`, `openai_get_model_info` to `listModels`. Schemas: the generated `*OneOf*` names became `JsonGrammar`, `RegexGrammar`, `JsonSchemaGrammar`, `MessageContentBody`, `MessageToolCallsBody`, `TextMessageChunk`, `ImageUrlMessageChunk`, `MessageContentText`, `MessageContentChunks`, `ToolChoiceAuto`, `ToolChoiceNone`, `ToolChoiceRequired`, `ToolChoiceFunction`, `CompletionChunk`, `CompletionFinalResponse`, `MessageContentFields` and `MessageRoleFields`.

9. Added a `ModelsInfo` schema (`object` plus a `data` array of `ModelInfo`) and made it the `200` response of `GET /v1/models`, which the original spec declared as a single `ModelInfo` although the server returns the OpenAI-style list wrapper. The change was made in the original spec `docs/spec/openapi.json`, and also made by hand in `docs/spec/aligned_ballerina_openapi.json`; re-apply it there after a re-align if alignment does not carry it.

## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
bal openapi -i docs/spec/aligned_ballerina_openapi.json -o ballerina --mode client --client-methods remote --license docs/license.txt
```

Note: The license year is hardcoded to 2024, change if necessary.
