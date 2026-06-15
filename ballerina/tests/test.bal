// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com)
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/io;
import ballerina/test;

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
// Set the TGI service URL via an environment variable or use the default.
// Export TGI_SERVICE_URL=http://<your-host>:8080 before running tests.
// If no live server is available the mock service below will be used instead.
configurable string serviceUrl = "http://localhost:8080";

// HuggingFace client (uses Bearer token auth — set token in Config.toml)
configurable string token = ?;

ConnectionConfig config = {
    auth: {
        token: token
    }
};

Client hfClient = check new (config, "https://api-inference.huggingface.co");

// Mock client (points at the local mock service for unit tests)
Client tgiClient = check new ({}, "http://localhost:9090");

// Health-check
@test:Config {
    groups: ["health"]
}
function testHealthCheck() returns error? {
    error? result = tgiClient->/health();
    test:assertTrue(result is (), "Health check should return nil on success");
}

// Model info  —  GET /info
@test:Config {
    groups: ["info"]
}
function testGetModelInfo() returns error? {
    Info info = check tgiClient->/info();
    test:assertNotEquals(info.modelId, "", "model_id should not be empty");
    test:assertTrue(info.maxConcurrentRequests > 0, "max_concurrent_requests should be positive");
    test:assertTrue(info.maxInputTokens > 0, "max_input_tokens should be positive");
    test:assertTrue(info.maxTotalTokens > 0, "max_total_tokens should be positive");
    io:println("Model info: ", info);
}

// OpenAI model info  —  GET /v1/models
@test:Config {
    groups: ["info"]
}
function testGetOpenAIModelInfo() returns error? {
    ModelInfo modelInfo = check tgiClient->/v1/models();
    test:assertNotEquals(modelInfo.id, "", "model id should not be empty");
    test:assertEquals(modelInfo.'object, "model");
    io:println("OpenAI model info: ", modelInfo);
}

// Token generation  —  POST /generate  (basic)
@test:Config {
    groups: ["generate"]
}
function testGenerateBasic() returns error? {
    GenerateRequest req = {
        inputs: "Once upon a time",
        parameters: {
            maxNewTokens: 20,
            temperature: 0.7,
            doSample: true
        }
    };
    GenerateResponse resp = check tgiClient->/generate.post(req);
    test:assertNotEquals(resp.generatedText, "", "Generated text should not be empty");
    io:println("Generated text: ", resp.generatedText);
}

// Token generation  —  POST /generate  (with details)
@test:Config {
    groups: ["generate"]
}
function testGenerateWithDetails() returns error? {
    GenerateRequest req = {
        inputs: "The capital of France is",
        parameters: {
            maxNewTokens: 10,
            details: true,
            decoderInputDetails: true
        }
    };
    GenerateResponse resp = check tgiClient->/generate.post(req);
    test:assertNotEquals(resp.generatedText, "", "Generated text should not be empty");
}

// Token generation  —  POST /generate  (with sampling params)
@test:Config {
    groups: ["generate"]
}
function testGenerateWithSamplingParams() returns error? {
    GenerateRequest req = {
        inputs: "What is machine learning?",
        parameters: {
            maxNewTokens: 50,
            temperature: 0.5,
            topP: 0.9,
            topK: 50,
            repetitionPenalty: 1.1,
            doSample: true,
            seed: 42
        }
    };
    GenerateResponse resp = check tgiClient->/generate.post(req);
    test:assertNotEquals(resp.generatedText, "", "Generated text should not be empty");
}

// Token generation  —  POST /generate  (stop sequences)
@test:Config {
    groups: ["generate"]
}
function testGenerateWithStopSequences() returns error? {
    GenerateRequest req = {
        inputs: "List three colors: 1.",
        parameters: {
            maxNewTokens: 30,
            stop: ["4.", "\n\n"]
        }
    };
    GenerateResponse resp = check tgiClient->/generate.post(req);
    test:assertNotEquals(resp.generatedText, "", "Generated text should not be empty");
}

// Compat generate  —  POST /
@test:Config {
    groups: ["generate"]
}
function testCompatGenerate() returns error? {
    CompatGenerateRequest req = {
        inputs: "My name is Ballerina and I",
        parameters: {maxNewTokens: 15},
        'stream: false
    };
    GenerateResponse[] responses = check tgiClient->/.post(req);
    test:assertTrue(responses.length() > 0, "Should return at least one response");
    test:assertNotEquals(responses[0].generatedText, "", "Generated text should not be empty");
}

// Streaming  —  POST /generate_stream
@test:Config {
    groups: ["streaming"]
}
function testGenerateStream() returns error? {
    GenerateRequest req = {
        inputs: "Tell me a short story",
        parameters: {maxNewTokens: 30}
    };
    stream<http:SseEvent, error?> sseStream = check tgiClient->/generate_stream.post(req);
    int eventCount = 0;
    check from http:SseEvent event in sseStream
        do {
            eventCount += 1;
            io:println("SSE event: ", event.data);
        };
    test:assertTrue(eventCount > 0, "Should receive at least one SSE event");
}

// Tokenize  —  POST /tokenize
@test:Config {
    groups: ["tokenize"]
}
function testTokenize() returns error? {
    GenerateRequest req = {inputs: "hello world"};
    TokenizeResponse tokens = check tgiClient->/tokenize.post(req);
    test:assertTrue(tokens.length() > 0, "Should return at least one token");
    foreach SimpleToken t in tokens {
        test:assertTrue(t.id >= 0, "Token id should be non-negative");
        test:assertNotEquals(t.text, "", "Token text should not be empty");
        test:assertTrue(t.stop >= t.'start, "Token stop should be >= start");
    }
    io:println("Tokenized: ", tokens);
}

// Chat tokenize  —  POST /chat_tokenize
@test:Config {
    groups: ["tokenize"]
}
function testChatTokenize() returns error? {
    ChatRequest chatReq = {
        messages: [{role: "user", content: "What is Deep Learning?"}],
        model: "tgi"
    };
    ChatTokenizeResponse resp = check tgiClient->/chat_tokenize.post(chatReq);
    test:assertNotEquals(resp.templatedText, "", "Templated text should not be empty");
    test:assertTrue(resp.tokenizeResponse.length() > 0, "Should return tokenized response");
    io:println("Chat tokenize response: ", resp);
}

// Chat completions  —  POST /v1/chat/completions  (basic)
@test:Config {
    groups: ["chat"]
}
function testChatCompletionsBasic() returns error? {
    ChatRequest req = {
        messages: [{role: "user", content: "What is Deep Learning?"}],
        model: "tgi",
        maxTokens: 128,
        temperature: 0.7,
        topP: 0.95
    };
    ChatCompletion completion = check tgiClient->/v1/chat/completions.post(req);
    test:assertNotEquals(completion.id, "", "Completion id should not be empty");
    test:assertTrue(completion.choices.length() > 0, "Should have at least one choice");
    test:assertNotEquals(completion.model, "", "Model should not be empty");
    io:println("Chat completion: ", completion.choices[0].message);
}

// Chat completions  —  multi-turn conversation
@test:Config {
    groups: ["chat"]
}
function testChatCompletionsMultiTurn() returns error? {
    ChatRequest req = {
        messages: [
            {role: "system", content: "You are a helpful assistant."},
            {role: "user", content: "What is the capital of France?"},
            {role: "assistant", content: "The capital of France is Paris."},
            {role: "user", content: "What is it known for?"}
        ],
        model: "tgi",
        maxTokens: 64
    };
    ChatCompletion completion = check tgiClient->/v1/chat/completions.post(req);
    test:assertTrue(completion.choices.length() > 0, "Should have at least one choice");
}

// Chat completions  —  usage stats present
@test:Config {
    groups: ["chat"]
}
function testChatCompletionsUsage() returns error? {
    ChatRequest req = {
        messages: [{role: "user", content: "Say hello."}],
        maxTokens: 10
    };
    ChatCompletion completion = check tgiClient->/v1/chat/completions.post(req);
    test:assertTrue(completion.usage.promptTokens > 0, "Prompt tokens should be positive");
    test:assertTrue(completion.usage.completionTokens > 0, "Completion tokens should be positive");
    test:assertTrue(
        completion.usage.totalTokens == completion.usage.promptTokens + completion.usage.completionTokens,
        "Total tokens should equal prompt + completion tokens"
    );
}

// Chat completions  —  with tools (function calling)
@test:Config {
    groups: ["chat", "tools"]
}
function testChatCompletionsWithTools() returns error? {
    Tool weatherTool = {
        'type: "function",
        'function: {
            name: "get_current_weather",
            description: "Get the current weather in a given location",
            arguments: {
                'type: "object",
                properties: {
                    location: {'type: "string", description: "The city and state, e.g. San Francisco, CA"},
                    unit: {'type: "string", 'enum: ["celsius", "fahrenheit"]}
                },
                required: ["location"]
            }
        }
    };
    ChatRequest req = {
        messages: [{role: "user", content: "What's the weather like in Paris?"}],
        tools: [weatherTool],
        toolChoice: "auto",
        maxTokens: 128
    };
    ChatCompletion completion = check tgiClient->/v1/chat/completions.post(req);
    test:assertTrue(completion.choices.length() > 0, "Should have at least one choice");
}

// Chat completions  —  with logprobs
@test:Config {
    groups: ["chat"]
}
function testChatCompletionsWithLogprobs() returns error? {
    ChatRequest req = {
        messages: [{role: "user", content: "Say one word."}],
        maxTokens: 5,
        logprobs: true,
        topLogprobs: 3
    };
    ChatCompletion completion = check tgiClient->/v1/chat/completions.post(req);
    test:assertTrue(completion.choices.length() > 0, "Should have at least one choice");
}

// Legacy completions  —  POST /v1/completions
@test:Config {
    groups: ["completions"]
}
function testCompletions() returns error? {
    CompletionRequest req = {
        prompt: ["Deep learning is"],
        maxTokens: 20,
        temperature: 0.7
    };
    CompletionFinal resp = check tgiClient->/v1/completions.post(req);
    test:assertNotEquals(resp.id, "", "Completion id should not be empty");
    test:assertTrue(resp.choices.length() > 0, "Should have at least one choice");
    test:assertNotEquals(resp.choices[0].text, "", "Completion text should not be empty");
}

// Legacy completions  —  with stop sequences
@test:Config {
    groups: ["completions"]
}
function testCompletionsWithStop() returns error? {
    CompletionRequest req = {
        prompt: ["The three primary colors are"],
        maxTokens: 30,
        stop: ["\n", "."]
    };
    CompletionFinal resp = check tgiClient->/v1/completions.post(req);
    test:assertTrue(resp.choices.length() > 0, "Should have at least one choice");
}

// Prometheus metrics  —  GET /metrics
@test:Config {
    groups: ["metrics"]
}
function testGetMetrics() returns error? {
    string metrics = check tgiClient->/metrics();
    test:assertNotEquals(metrics, "", "Metrics response should not be empty");
    io:println("Metrics (first 200 chars): ", metrics.substring(0, int:min(200, metrics.length())));
}

// SageMaker invocations  —  POST /invocations
@test:Config {
    groups: ["sagemaker"]
}
function testSagemakerInvocations() returns error? {
    CompatGenerateRequest sagReq = {
        inputs: "SageMaker test input",
        parameters: {maxNewTokens: 10},
        'stream: false
    };
    SagemakerResponse resp = check tgiClient->/invocations.post(sagReq);
    test:assertTrue(resp is GenerateResponse, "Expected SageMaker response to be of type GenerateResponse");
    if resp is GenerateResponse {
        test:assertEquals(resp.generatedText, "sagemaker generated text", "Payload content mismatch");
    }
}

// GenerateParameters defaults validation
@test:Config {
    groups: ["params"]
}
function testGenerateParameterDefaults() returns error? {
    GenerateParameters params = {};
    test:assertFalse(params.doSample, "doSample should default to false");
    test:assertFalse(params.watermark, "watermark should default to false");
    test:assertFalse(params.decoderInputDetails, "decoderInputDetails should default to false");
    test:assertTrue(params.details, "details should default to true");
}

// CompatGenerateRequest stream default
@test:Config {
    groups: ["params"]
}
function testCompatGenerateStreamDefault() returns error? {
    CompatGenerateRequest req = {inputs: "test"};
    test:assertFalse(req.'stream, "stream should default to false");
}

// ChatRequest — frequency & presence penalty range
@test:Config {
    groups: ["params"]
}
function testChatRequestPenalties() returns error? {
    ChatRequest req = {
        messages: [{role: "user", content: "test"}],
        frequencyPenalty: 1.5,
        presencePenalty: -1.0
    };
    test:assertEquals(req?.frequencyPenalty, 1.5);
    test:assertEquals(req?.presencePenalty, -1.0);
}

// Token type fields
@test:Config {
    groups: ["types"]
}
function testTokenTypeFields() {
    Token t = {id: 42, text: "hello", logprob: -0.34, special: false};
    test:assertEquals(t.id, 42);
    test:assertEquals(t.text, "hello");
    test:assertFalse(t.special);
}

// Usage totals
@test:Config {
    groups: ["types"]
}
function testUsageTotals() {
    Usage u = {promptTokens: 10, completionTokens: 20, totalTokens: 30};
    test:assertEquals(u.totalTokens, u.promptTokens + u.completionTokens);
}
