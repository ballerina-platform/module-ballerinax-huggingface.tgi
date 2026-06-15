// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com)
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific
// language governing permissions and limitations under the License.

// # Text Generation
//
// This example demonstrates how to use the TGI native `/generate` endpoint
// to perform raw text completion with fine-grained sampling control
// (temperature, top-k, top-p, repetition penalty). This is useful when you
// need maximum control over the generation process beyond the chat interface.
//
// ## Prerequisites
// - A running TGI instance
// - Set `serviceUrl` in Config.toml
//
// ## Run the example
// ```bash
// bal run
// ```

import ballerina/io;
import ballerinax/huggingface.tgi;

configurable string serviceUrl = "http://localhost:8080";

// Generates text for a given prompt with configurable parameters
function generateText(tgi:Client tgiClient, string prompt,
        int maxTokens = 100, float temperature = 0.8,
        float topP = 0.95, int topK = 50,
        float repetitionPenalty = 1.1) returns string|error {

    tgi:GenerateRequest req = {
        inputs: prompt,
        parameters: {
            maxNewTokens: maxTokens,
            temperature: temperature,
            topP: topP,
            topK: topK,
            repetitionPenalty: repetitionPenalty,
            doSample: true,
            returnFullText: false
        }
    };

    tgi:GenerateResponse response = check tgiClient->/generate.post(req);
    return response.generatedText;
}

public function main() returns error? {
    tgi:Client tgiClient = check new ({}, serviceUrl);

    io:println("=== HuggingFace TGI Text Generation ===\n");

    // --- Use case 1: Creative writing with high temperature ---
    string creativePrompt = "In the year 2150, the first Ballerina program ran on Mars.";
    io:println("Prompt: " + creativePrompt);
    string creativeOutput = check generateText(
        tgiClient, creativePrompt,
        maxTokens = 120,
        temperature = 0.9,
        topK = 60
    );
    io:println("Output (creative): " + creativeOutput);
    io:println("---\n");

    // --- Use case 2: Factual completion with low temperature ---
    string factualPrompt = "The main benefits of the Ballerina programming language are:";
    io:println("Prompt: " + factualPrompt);
    string factualOutput = check generateText(
        tgiClient, factualPrompt,
        maxTokens = 80,
        temperature = 0.2,
        topP = 0.9
    );
    io:println("Output (factual): " + factualOutput);
    io:println("---\n");

    // --- Use case 3: Code generation with stop sequence ---
    tgi:GenerateRequest codeReq = {
        inputs: "# Ballerina function to fetch data from an HTTP endpoint\nfunction",
        parameters: {
            maxNewTokens: 100,
            temperature: 0.2,
            stop: ["# End", "\n\n\n"],
            returnFullText: false
        }
    };
    tgi:GenerateResponse codeResponse = check tgiClient->/generate.post(codeReq);
    io:println("Code generation output:");
    io:println("function" + codeResponse.generatedText);
}
