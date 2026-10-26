
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
import ballerina/os;
import ballerina/test;

final boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
final string serviceUrl = isLiveServer ? os:getEnv("TGI_SERVICE_URL") : "http://localhost:9090";
final string token = isLiveServer ? os:getEnv("TGI_TOKEN") : "test_token";

final Client tgiClient = check new ({auth: {token}, httpVersion: http:HTTP_1_1}, serviceUrl);

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCheckHealth() returns error? {
    error? response = tgiClient->checkHealth();
    test:assertTrue(response is ());
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetInfo() returns error? {
    Info response = check tgiClient->getInfo();
    test:assertTrue(response.modelId.length() > 0);
    test:assertTrue(response.maxTotalTokens > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetMetrics() returns error? {
    string response = check tgiClient->getMetrics();
    test:assertTrue(response.length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListModels() returns error? {
    ModelsInfo response = check tgiClient->listModels();
    test:assertTrue(response.data.length() > 0);
    test:assertTrue(response.data[0].id.length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGenerateCompat() returns error? {
    GenerateResponse[] response = check tgiClient->generateCompat({inputs: "What is deep learning?"});
    test:assertTrue(response.length() > 0);
    test:assertTrue(response[0].generatedText.length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGenerateTokens() returns error? {
    GenerateResponse response = check tgiClient->generateTokens({inputs: "What is deep learning?"});
    test:assertTrue(response.generatedText.length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testTokenizeText() returns error? {
    TokenizeResponse response = check tgiClient->tokenizeText({inputs: "What is AI"});
    test:assertTrue(response.length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testTokenizeChat() returns error? {
    ChatTokenizeResponse response = check tgiClient->tokenizeChat({messages: [{role: "user", content: "Hello there"}]});
    test:assertTrue(response.templatedText.length() > 0);
    test:assertTrue(response.tokenizeResponse.length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateChatCompletion() returns error? {
    ChatCompletion response = check tgiClient->createChatCompletion({
        messages: [{role: "user", content: "What is the capital of France?"}],
        maxTokens: 32
    });
    test:assertTrue(response.choices.length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateCompletion() returns error? {
    CompletionFinal response = check tgiClient->createCompletion({prompt: ["Machine learning is"], maxTokens: 32});
    test:assertTrue(response.choices.length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testStreamTokens() returns error? {
    stream<http:SseEvent, error?> response = check tgiClient->streamTokens({inputs: "What is deep learning?"});
    http:SseEvent[] events = check from http:SseEvent event in response
        select event;
    test:assertTrue(events.length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testInvokeSagemaker() returns error? {
    SagemakerResponse response = check tgiClient->invokeSagemaker({
        messages: [{role: "user", content: "Hello"}]
    });
    if response !is ChatCompletion {
        test:assertFail("Expected a ChatCompletion for a chat request");
    }
    test:assertTrue(response.choices.length() > 0);
}
