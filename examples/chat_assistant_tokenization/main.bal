// Sends a question to a chat model, after checking how many tokens the templated prompt uses.

import ballerina/io;
import ballerinax/huggingface.tgi;

configurable string serviceUrl = ?;
configurable string token = ?;
configurable string question = "What is the capital of France?";
configurable int:Signed32 maxTokens = 128;

public function main() returns error? {
    tgi:Client tgiClient = check new ({auth: {token}}, serviceUrl);

    // Step 1: Find the model served by the endpoint
    tgi:ModelsInfo models = check tgiClient->listModels();
    if models.data.length() == 0 {
        return error("The endpoint serves no model");
    }
    io:println("Serving model: ", models.data[0].id);

    // Step 2: Apply the chat template and count the prompt tokens
    tgi:Message[] messages = [{role: "user", content: question}];
    tgi:ChatTokenizeResponse tokenized = check tgiClient->tokenizeChat({messages});
    io:println("Prompt tokens: ", tokenized.tokenizeResponse.length());

    // Step 3: Ask the model for a chat completion
    tgi:ChatCompletion completion = check tgiClient->createChatCompletion({messages, maxTokens});
    foreach tgi:ChatCompletionComplete choice in completion.choices {
        tgi:OutputMessage message = choice.message;
        if message is tgi:TextMessage {
            io:println("Assistant: ", message.content);
        }
    }
    io:println("Total tokens used: ", completion.usage.totalTokens);
}
