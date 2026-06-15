// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;

listener http:Listener mockListener = new (9090);

service "/" on mockListener {

    // POST /  (compat generate)
    resource function post .(http:Caller caller, http:Request req) returns error? {
        json payload = [{generated_text: "test output from compat generate"}];
        check caller->respond(payload);
    }

    // POST /generate
    resource function post generate(http:Caller caller, http:Request req) returns error? {
        json payload = {generated_text: "once upon a time"};
        check caller->respond(payload);
    }

    // POST /generate_stream  — returns a minimal SSE response
    resource function post generate_stream(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("Content-Type", "text/event-stream");
        res.setTextPayload(
            "data: {\"index\":0,\"token\":{\"id\":1,\"text\":\" hello\",\"logprob\":-0.5,\"special\":false}}\n\n" +
            "data: {\"index\":1,\"token\":{\"id\":2,\"text\":\" world\",\"logprob\":-0.3,\"special\":false},\"generated_text\":\" hello world\"}\n\n"
        );
        check caller->respond(res);
    }

    // GET /health
    resource function get health(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.statusCode = http:STATUS_OK;
        check caller->respond(res);
    }

    // GET /info
    resource function get info(http:Caller caller, http:Request req) returns error? {
        json payload = {
            model_id: "mock-model",
            max_concurrent_requests: 128,
            max_best_of: 2,
            max_stop_sequences: 4,
            max_input_tokens: 1024,
            max_total_tokens: 2048,
            validation_workers: 2,
            max_client_batch_size: 32,
            router: "text-generation-router",
            version: "3.3.6-dev0"
        };
        check caller->respond(payload);
    }

    // POST /tokenize
    resource function post tokenize(http:Caller caller, http:Request req) returns error? {
        json payload = [
            {id: 1, text: "hello", 'start: 0, stop: 5},
            {id: 2, text: " world", 'start: 5, stop: 11}
        ];
        check caller->respond(payload);
    }

    // POST /chat_tokenize
    resource function post chat_tokenize(http:Caller caller, http:Request req) returns error? {
        json payload = {
            templated_text: "<s>[INST] What is Deep Learning? [/INST]",
            tokenize_response: [
                {id: 1, text: "<s>", 'start: 0, stop: 3},
                {id: 2, text: "[INST]", 'start: 3, stop: 9}
            ]
        };
        check caller->respond(payload);
    }

    // POST /v1/chat/completions
    resource function post v1/chat/completions(http:Caller caller, http:Request req) returns error? {
        json payload = {
            id: "chatcmpl-mock-001",
            created: 1706270835,
            model: "mock-model",
            system_fingerprint: "mock-fp",
            choices: [{
                index: 0,
                message: {role: "assistant", content: "Deep Learning is a subset of machine learning."},
                finish_reason: "stop"
            }],
            usage: {prompt_tokens: 10, completion_tokens: 20, total_tokens: 30}
        };
        check caller->respond(payload);
    }

    // POST /v1/completions
    resource function post v1/completions(http:Caller caller, http:Request req) returns error? {
        json payload = {
            id: "cmpl-mock-001",
            created: 1706270835,
            model: "mock-model",
            system_fingerprint: "mock-fp",
            choices: [{index: 0, text: "deep learning rocks", finish_reason: "stop"}],
            usage: {prompt_tokens: 5, completion_tokens: 10, total_tokens: 15}
        };
        check caller->respond(payload);
    }

    // GET /v1/models
    resource function get v1/models(http:Caller caller, http:Request req) returns error? {
        json payload = {
            id: "mock-model",
            'object: "model",
            created: 1686935002,
            owned_by: "huggingface"
        };
        check caller->respond(payload);
    }

    // GET /metrics
    resource function get metrics(http:Caller caller, http:Request req) returns error? {
        check caller->respond("# HELP tgi_requests_total Total number of requests\n# TYPE tgi_requests_total counter\ntgi_requests_total 42\n");
    }

    // POST /invocations  (SageMaker compat)
    resource function post invocations(http:Caller caller, http:Request req) returns error? {
        json payload = {generated_text: "sagemaker generated text"};
        check caller->respond(payload);
    }
}
