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

// # Token Counter
//
// This example demonstrates how to use the `/tokenize` and `/info` endpoints
// to count tokens before sending a request, check against the model's context
// window, and decide whether to truncate or chunk the input. This is a
// critical pattern for production systems to avoid unexpected 422 errors.
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

// Result type for token analysis
type TokenAnalysis record {|
    int tokenCount;
    int maxInputTokens;
    boolean fitsInContext;
    string recommendation;
|};

// Analyse whether a prompt fits within the model's context window
function analysePrompt(tgi:Client tgiClient, string prompt) returns TokenAnalysis|error {

    // Fetch server limits
    tgi:Info info = check tgiClient->/info();
    int maxInputTokens = info.maxInputTokens;

    // Tokenize the prompt
    tgi:GenerateRequest tokenReq = {inputs: prompt};
    tgi:TokenizeResponse tokens = check tgiClient->/tokenize.post(tokenReq);
    int tokenCount = tokens.length();

    boolean fits = tokenCount <= maxInputTokens;
    string recommendation;
    if fits && tokenCount < maxInputTokens * 80 / 100 {
        recommendation = "Fits comfortably (" + tokenCount.toString() +
                         "/" + maxInputTokens.toString() + " tokens)";
    } else if fits {
        recommendation = "Fits but close to limit (" + tokenCount.toString() +
                         "/" + maxInputTokens.toString() + " tokens). Consider shortening.";
    } else {
        recommendation = "Exceeds context window by " +
                         (tokenCount - maxInputTokens).toString() + " tokens. Must truncate.";
    }

    return {tokenCount, maxInputTokens, fitsInContext: fits, recommendation};
}

// Print a visual breakdown of the tokens
function printTokenBreakdown(tgi:TokenizeResponse tokens) {
    io:println("Token breakdown:");
    foreach int i in 0 ..< int:min(10, tokens.length()) {
        tgi:SimpleToken t = tokens[i];
        io:println(string `  [${i}] id=${t.id}  text="${t.text}"  chars=${t.'start}-${t.stop}`);
    }
    if tokens.length() > 10 {
        io:println("  ... and " + (tokens.length() - 10).toString() + " more tokens");
    }
}

public function main() returns error? {
    tgi:Client tgiClient = check new ({}, serviceUrl);

    io:println("=== HuggingFace TGI Token Counter ===\n");

    // Fetch and display model info
    tgi:Info info = check tgiClient->/info();
    io:println("Model       : " + info.modelId);
    io:println("Max input   : " + info.maxInputTokens.toString() + " tokens");
    io:println("Max total   : " + info.maxTotalTokens.toString() + " tokens");
    io:println("Version     : " + info.version);
    io:println("");

    // --- Test 1: Short prompt ---
    string shortPrompt = "What is Ballerina?";
    io:println("--- Test 1: Short prompt ---");
    io:println("Prompt: \"" + shortPrompt + "\"");
    TokenAnalysis result1 = check analysePrompt(tgiClient, shortPrompt);
    io:println(result1.recommendation);

    tgi:TokenizeResponse tokens1 = check tgiClient->/tokenize.post({inputs: shortPrompt});
    printTokenBreakdown(tokens1);
    io:println("");

    // --- Test 2: Medium prompt ---
    string mediumPrompt = "Explain the concept of service mesh in cloud-native architecture, " +
                          "including its main components like the control plane, data plane, " +
                          "sidecar proxies, and how they interact with microservices.";
    io:println("--- Test 2: Medium prompt ---");
    io:println("Prompt: \"" + mediumPrompt.substring(0, 60) + "...\"");
    TokenAnalysis result2 = check analysePrompt(tgiClient, mediumPrompt);
    io:println(result2.recommendation);
    io:println("");

    // --- Test 3: Chat template tokenization ---
    io:println("--- Test 3: Chat template tokenization ---");
    tgi:ChatRequest chatReq = {
        messages: [
            {role: "system", content: "You are a helpful assistant."},
            {role: "user", content: "Summarise the Ballerina language in 3 bullet points."}
        ]
    };
    tgi:ChatTokenizeResponse chatTokens = check tgiClient->/chat_tokenize.post(chatReq);
    io:println("Templated text preview: " +
               chatTokens.templatedText.substring(0, int:min(80, chatTokens.templatedText.length())) + "...");
    io:println("Total tokens after chat template: " + chatTokens.tokenizeResponse.length().toString());
}
