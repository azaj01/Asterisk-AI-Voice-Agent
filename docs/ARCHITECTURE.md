# Asterisk AI Voice Agent - Architecture Guide

## Overview

The **Asterisk AI Voice Agent** is a production-ready, open-source telephony integration framework enabling real-time, bidirectional voice conversations between callers and AI providers through Asterisk/FreePBX.

### Key Capabilities

- **Asterisk-Native Integration**: Uses ARI (Asterisk REST Interface) and AudioSocket/ExternalMedia RTP.
- **Dual Architecture**: Supports both **Full Agents** (e.g., OpenAI Realtime) and **Modular Pipelines** (STT + LLM + TTS).
- **Tool Calling**: AI-powered telephony actions (transfer, hangup, email summaries).
- **Privacy-First**: Options for on-premises audio handling with cloud LLM inference.
- **Observability**: SQLite call history, Prometheus metrics, and structured logging.

---

## System Architecture

The system consists of three containerized services interacting with an external Asterisk/FreePBX server:

1. **AI Engine (`ai_engine`)**: The core orchestrator. Handles call control, audio processing, and provider integration.
2. **Local AI Server (`local_ai_server`)**: Optional container for on-premises STT/LLM/TTS (e.g., Whisper, Ollama) when privacy or cost are concerns.
3. **Admin UI (`admin_ui`)**: Web-based management interface for configuration and monitoring.

### Shared State vs. Separation

- **Configuration**: All services mount `config/`.
- **Data**: All share `data/` (SQLite database).
- **Media**: All share `asterisk_media/ai-generated/` for playback consistency.

---

## Core Components

- **Engine**: The main controller maintaining `SessionStore` (call state), `ARIClient` (Asterisk control), and `StreamingPlaybackManager` (audio output).
- **SessionStore**: Manages typed call state (`CallSession`) and persists it to `call_history.db`.
- **Audio Processing**: Negotiates formats via `TransportOrchestrator`. Converts between Asterisk wire formats (ulaw/slin16) and provider native formats.

---

## Integration Patterns

### 1. Full Agent Providers

*Single WebSocket connection handling STT → LLM → TTS.*

- **Examples**: OpenAI Realtime, Deepgram Voice Agent.
- **Pros**: Lowest latency, integrated barge-in, simpler architecture.
- **Flow**: Engine streams raw audio -> Provider returns audio chunks.

### 2. Modular Pipelines

*Composed adapters for distinct stages.*

- **Components**: STT Adapter (Transcribe) -> LLM Adapter (Generate) -> TTS Adapter (Synthesize).
- **Pros**: Mix-and-match providers, cost control, data privacy.
- **Flow**: Turn-based. STT waits for silence -> LLM generates text -> TTS creates audio files for playback.

---

## Call Lifecycle

1. **StasisStart**: Call enters the ARI application.
2. **CallSession**: Engine creates a session and resolves the provider/pipeline configuration.
3. **AI_PROVIDER**:
    - *Full Agent*: WebSocket established, audio streams bi-directionally.
    - *Pipeline*: STT starts listening.
4. **Interaction**: User speaks -> Agent responds (streaming or file playback).
5. **Tool Execution**: Agent may trigger telephony tools (e.g., transfer).
6. **StasisEnd**: Call hangs up, session data persisted.

---

## Configuration

Configuration is split between:

- **Logic**: `config/ai-agent.yaml` (Providers, pipelines, contexts).
- **Secrets**: `.env` (API keys, credentials).

**Routing Precedence**:

1. `AI_CONTEXT` channel variable.
2. `AI_PROVIDER` channel variable.
3. `contexts.<name>.provider` in YAML.
4. `default_provider` in YAML.
