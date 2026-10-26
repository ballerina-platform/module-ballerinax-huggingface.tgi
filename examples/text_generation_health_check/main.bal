// Verifies that a Text Generation Inference server is healthy, reports the loaded model,
// and generates text from a prompt.

import ballerina/io;
import ballerinax/huggingface.tgi;

configurable string serviceUrl = ?;
configurable string token = ?;
configurable string prompt = "What is deep learning?";
configurable int:Signed32 maxNewTokens = 64;

public function main() returns error? {
    tgi:Client tgiClient = check new ({auth: {token}}, serviceUrl);

    // Step 1: Check that the server is ready to accept requests
    check tgiClient->checkHealth();
    io:println("The server is healthy.");

    // Step 2: Read the model and limits of the running server
    tgi:Info info = check tgiClient->getInfo();
    io:println("Model: ", info.modelId, ", version: ", info.version);
    io:println("Maximum total tokens: ", info.maxTotalTokens);

    // Step 3: Generate text for the prompt
    tgi:GenerateResponse response = check tgiClient->generateTokens({
        inputs: prompt,
        parameters: {maxNewTokens}
    });
    io:println("Generated text: ", response.generatedText);
}
