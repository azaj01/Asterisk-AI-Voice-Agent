# Asterisk AI Voice Agent

A powerful, agentic AI voice system that bridges traditional telephony (Asterisk/PJSIP) with modern LLMs (Gemini Live) using AudioSocket and ARI.

## 🏗️ Architecture Overview

- **Asterisk (WSL)**: Handles SIP signaling, RTP media, and dialplan routing. Runs on Ubuntu via WSL2.
- **AI Engine (Docker)**: The core brain. Connects to Asterisk via ARI and AudioSocket. Interfaces with Gemini Live API.
- **Admin UI (Docker)**: Real-time dashboard for call logs, system monitoring, and health checks.

---

## 🚀 How to Start the System

The easiest way to start the system is using the provided script:

```powershell
.\start.ps1
```

Or, follow these steps in order:

### 1. Start Asterisk (WSL)

Open your terminal and run:

```powershell
wsl -u root -d Ubuntu fwconsole start
```

*Wait for "Asterisk Started" message.*

### 2. Start AI Services (Docker)

In the project root directory:

```powershell
docker compose up -d
```

*This starts the `ai_engine`, `admin_ui`, and `local_ai_server`.*

### 3. Connect Softphone (MicroSIP)

To test locally, use **MicroSIP** with these settings:

- **SIP Server / Domain**: `127.0.0.1`
- **Transport**: `TCP`
- **User**: `101`
- **Password**: `azaj12345`
- **Port**: `5060`

---

## 🧪 Testing the Agent

1. Once MicroSIP shows **Online**, dial **888**.
2. You should hear the AI Engine answer.
3. Speak clearly; the agent uses real-time bidirectional streaming.

---

## 🛑 How to Shut Down

The easiest way to shut down is using the provided script:

```powershell
.\stop.ps1
```

Or, follow these steps:

### 1. Stop Docker Containers

```powershell
docker compose down
```

### 2. Stop Asterisk (WSL)

```powershell
wsl -u root -d Ubuntu fwconsole stop
```

---

## 🔍 Troubleshooting

- **MicroSIP "Service Unavailable"**: Ensure Asterisk is running in WSL (`fwconsole status`). Check if another app is using port 5060.
- **Softphone won't register**: Try switching between `127.0.0.1` and your WSL IP (`wsl hostname -I`). Ensure `TCP` transport is enabled in Asterisk.
- **AI Engine Disconnected in Dashboard**: Check ARI credentials in `.env` and restart Docker (`docker compose restart ai_engine`).
- **No Audio**: Check `AUDIOSOCKET_ADVERTISE_HOST` in `.env`. It should typically be your Windows Host IP or `host.docker.internal`.
