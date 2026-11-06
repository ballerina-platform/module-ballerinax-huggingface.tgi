
// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.


import ballerina/http;

listener http:Listener ep0 = new (9090);

@http:ServiceConfig {treatNilableAsOptional: true}
service / on ep0 {
    # Health check method
    #
    # + return - Everything is working fine
    resource function get health() returns http:Ok {
        return http:OK;
    }

    # Text Generation Inference endpoint info
    #
    # + return - Served model info
    resource function get info() returns Info {
        return {
            modelId: "bigscience/blomm-560m",
            version: "3.3.6",
            sha: "d5e4f3a1b2c3",
            router: "text-generation-router",
            maxConcurrentRequests: 128,
            maxBestOf: 2,
            maxStopSequences: 4,
            maxInputTokens: 1024,
            maxTotalTokens: 2048,
            maxClientBatchSize: 4,
            validationWorkers: 2,
            modelPipelineTag: "text-generation",
            modelSha: "e985a63cdc139290c5f700ff1929f0b5942cced2",
            dockerLabel: "sha-d5e4f3a"
        };
    }

    # Prometheus metrics scrape endpoint
    #
    # + return - Prometheus Metrics
    resource function get metrics() returns string {
        return "# HELP tgi_request_count Total number of requests\n# TYPE tgi_request_count counter\ntgi_request_count 42\n";
    }

    # Get model info
    #
    # + return - Served model info
    resource function get v1/models() returns ModelsInfo {
        return {
            'object: "list",
            data: [
                {
                    id: "bigscience/blomm-560m",
                    'object: "model",
                    created: 1727000000,
                    ownedBy: "bigscience"
                }
            ]
        };
    }

    # Generate tokens in compatibility mode
    #
    # + payload - Input text and parameters for token generation
    # + return - Generated text
    resource function post .(@http:Payload CompatGenerateRequest payload) returns GenerateResponse[] {
        return [
            {
                generatedText: "Deep learning is a subset of machine learning.",
                details: {
                    finishReason: "length",
                    generatedTokens: 3,
                    seed: 42,
                    prefill: [],
                    tokens: [
                        {id: 1234, text: " Deep", logprob: -0.5, special: false},
                        {id: 5678, text: " learning", logprob: -0.25, special: false},
                        {id: 91011, text: " rocks", logprob: -0.75, special: false}
                    ]
                }
            }
        ];
    }

    # Template and tokenize a chat request
    #
    # + payload - Chat messages and options to template and tokenize
    # + return - Templated and tokenized chat request
    resource function post chat_tokenize(@http:Payload ChatRequest payload) returns ChatTokenizeResponse {
        return {
            templatedText: "<|user|>Hello there<|assistant|>",
            tokenizeResponse: [
                {id: 1, text: "<|user|>", 'start: 0, stop: 8},
                {id: 2, text: "Hello", 'start: 8, stop: 13},
                {id: 3, text: " there", 'start: 13, stop: 19}
            ]
        };
    }

    # Generate tokens
    #
    # + payload - Input text and parameters for token generation
    # + return - Generated text
    resource function post generate(@http:Payload GenerateRequest payload) returns GenerateResponse {
        return {
            generatedText: "Deep learning is a subset of machine learning.",
            details: {
                finishReason: "eos_token",
                generatedTokens: 2,
                seed: 7,
                prefill: [{id: 100, text: "What", logprob: -1.5}],
                tokens: [
                    {id: 1234, text: " Deep", logprob: -0.5, special: false},
                    {id: 5678, text: " learning", logprob: -0.25, special: false}
                ]
            }
        };
    }

    # Stream generated tokens
    #
    # + payload - Input text and parameters for streamed token generation
    # + return - Server-sent events carrying the generated tokens
    resource function post generate_stream(@http:Payload GenerateRequest payload) returns stream<http:SseEvent, error?> {
        http:SseEvent[] events = [
            {data: "{\"index\":0,\"token\":{\"id\":1234,\"text\":\" Deep\",\"logprob\":-0.5,\"special\":false}}"},
            {data: "{\"index\":1,\"token\":{\"id\":5678,\"text\":\" learning\",\"logprob\":-0.25,\"special\":false},\"generated_text\":\" Deep learning\"}"}
        ];
        return events.toStream();
    }

    # Generate tokens from a Sagemaker request
    #
    # + payload - Sagemaker style request for token generation
    # + return - Generated chat completion
    resource function post invocations(@http:Payload SagemakerRequest payload) returns ChatCompletion {
        return {
            id: "cmpl-sm-001",
            created: 1727000000,
            model: "bigscience/blomm-560m",
            systemFingerprint: "3.3.6-sha-d5e4f3a",
            choices: [
                {
                    index: 0,
                    finishReason: "stop",
                    message: <TextMessage>{role: "assistant", content: "Hello from the Sagemaker endpoint."}
                }
            ],
            usage: {promptTokens: 8, completionTokens: 7, totalTokens: 15}
        };
    }

    # Tokenize input text
    #
    # + payload - Input text and parameters to tokenize
    # + return - Tokenized ids
    resource function post tokenize(@http:Payload GenerateRequest payload) returns TokenizeResponse {
        return [
            {id: 11, text: "What", 'start: 0, stop: 4},
            {id: 12, text: " is", 'start: 4, stop: 7},
            {id: 13, text: " AI", 'start: 7, stop: 10}
        ];
    }

    # Create a chat completion
    #
    # + payload - Chat messages and options for the chat completion
    # + return - Generated chat completion
    resource function post v1/chat/completions(@http:Payload ChatRequest payload) returns ChatCompletion {
        return {
            id: "chatcmpl-001",
            created: 1727000000,
            model: "bigscience/blomm-560m",
            systemFingerprint: "3.3.6-sha-d5e4f3a",
            choices: [
                {
                    index: 0,
                    finishReason: "stop",
                    message: <TextMessage>{role: "assistant", content: "Paris is the capital of France."}
                }
            ],
            usage: {promptTokens: 14, completionTokens: 7, totalTokens: 21}
        };
    }

    # Create a text completion
    #
    # + payload - Prompt and options for the text completion
    # + return - Generated text completion
    resource function post v1/completions(@http:Payload CompletionRequest payload) returns CompletionFinal {
        return {
            id: "cmpl-001",
            created: 1727000000,
            model: "bigscience/blomm-560m",
            systemFingerprint: "3.3.6-sha-d5e4f3a",
            choices: [
                {
                    index: 0,
                    finishReason: "length",
                    text: " a field of study within artificial intelligence."
                }
            ],
            usage: {promptTokens: 5, completionTokens: 8, totalTokens: 13}
        };
    }
}
