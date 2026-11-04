# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- The initial Hugging Face Text Generation Inference (TGI) connector, a `Client` with 12 remote methods for a TGI server:
  - Text generation: `generateCompat`, `generateTokens` and `streamTokens`.
  - OpenAI-compatible endpoints: `createChatCompletion`, `createCompletion` and `listModels`.
  - Tokenization: `tokenizeText` and `tokenizeChat`.
  - Server inspection: `checkHealth`, `getInfo`, `getMetrics` and `invokeSagemaker`.
- Bearer token authentication through `ConnectionConfig.auth` (`http:BearerTokenConfig`).
- A default `serviceUrl` of `http://localhost:8080`, for a locally running TGI server.
