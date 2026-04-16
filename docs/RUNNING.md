# Running the Asterisk AI Voice Agent

A quick-reference guide for starting, stopping, and verifying the system.

---

## Quick Commands

| Action | Command |
|---|---|
| **Start everything** | `.\start.ps1` |
| **Stop everything** | `.\stop.ps1` |
| **Rebuild after code changes** | `docker compose up -d --build` |
| **View running containers** | `docker ps` |
| **View AI Engine logs** | `docker logs ai_engine --tail 100 -f` |
| **View Admin UI logs** | `docker logs admin_ui --tail 100 -f` |

---

## Starting the System

### Option 1: One-Command Start

```powershell
.\start.ps1
```

This runs two steps automatically:

1. Starts Asterisk/FreePBX in WSL (`fwconsole start`)
2. Starts Docker containers (`docker compose up -d`)

### Option 2: Manual Step-by-Step

```powershell
# 1. Start Asterisk PBX in WSL
wsl -u root -d Ubuntu fwconsole start

# 2. Start Docker services
docker compose up -d
```

### First-Time or After Code Changes (Rebuild)

```powershell
# 1. Start Asterisk PBX
wsl -u root -d Ubuntu fwconsole start

# 2. Build and start Docker services
docker compose up -d --build
```

> **Lean Build Tip:** If you only use cloud providers (Gemini, OpenAI, Deepgram), set these in `.env` to skip heavy local AI models and save 10+ minutes of build time:
>
> ```
> INCLUDE_KOKORO=false
> INCLUDE_LLAMA=false
> ```

---

## Stopping the System

### Option 1: One-Command Stop

```powershell
.\stop.ps1
```

### Option 2: Manual Step-by-Step

```powershell
# 1. Stop Docker containers
docker compose down

# 2. Stop Asterisk PBX
wsl -u root -d Ubuntu fwconsole stop
```

---

## Verifying the System

### 1. Check Docker Containers

```powershell
docker ps
```

**Expected output** — all 3 containers running:

| Container | Status | Port |
|---|---|---|
| `admin_ui` | Up | `0.0.0.0:3003 → 3003` |
| `ai_engine` | Up | `8090`, `15000`, `9000` |
| `local_ai_server` | Up (healthy) | — |

### 2. Check Asterisk PBX

```powershell
wsl -u root -d Ubuntu service asterisk status
```

Or test the ARI endpoint directly:

```powershell
curl -I http://localhost:8088/ari/api-docs/resources.json
```

A `401 Unauthorized` response means Asterisk is running (it just needs credentials).

### 3. Check Admin UI

Open **<http://localhost:3003>** in your browser.

### 4. Check AI Engine Logs

```powershell
docker logs ai_engine --tail 50
```

Look for: `ARI connected` and `Listening for calls`.

---

## Making a Test Call

1. Register a SIP softphone (e.g., Zoiper, Linphone) to your FreePBX
2. Dial **888** — routes to the **Google Gemini Live** AI agent
3. Dial **999** — routes to the default provider

These extensions are configured in `/etc/asterisk/extensions_custom.conf` (inside WSL):

```asterisk
[from-internal-custom]
exten => 888,1,NoOp(AI Voice Agent Test)
 same => n,Answer()
 same => n,Set(AI_PROVIDER=google_live)
 same => n,Stasis(asterisk-ai-voice-agent)
 same => n,Hangup()

exten => 999,1,NoOp(Route to AI Agent)
 same => n,Stasis(asterisk-ai-voice-agent)
 same => n,Hangup()
```

---

## Troubleshooting

### Container Won't Start

```powershell
# Check container logs for errors
docker logs admin_ui --tail 50
docker logs ai_engine --tail 50
docker logs local_ai_server --tail 50
```

### `entrypoint.sh: no such file or directory`

This is a Windows line-ending issue. Fix it:

```powershell
# Convert CRLF to LF
$content = Get-Content -Path "admin_ui\entrypoint.sh" -Raw
$content = $content -replace "`r`n", "`n"
[System.IO.File]::WriteAllText("$PWD\admin_ui\entrypoint.sh", $content, [System.Text.UTF8Encoding]::new($false))

# Rebuild
docker compose up -d --build admin_ui
```

### Build Takes Too Long (20+ minutes)

You're probably building local AI models you don't need. If you use cloud providers only:

```env
# In .env
INCLUDE_KOKORO=false
INCLUDE_LLAMA=false
```

Then rebuild: `docker compose up -d --build`

### Asterisk Not Responding

```powershell
# Check if Asterisk service is running
wsl -u root -d Ubuntu service asterisk status

# Restart Asterisk
wsl -u root -d Ubuntu fwconsole restart

# Check critical dependencies
wsl -u root -d Ubuntu service mariadb status
```

### AI Engine Can't Connect to Asterisk

Check `.env` for correct ARI settings:

```env
ASTERISK_HOST=host.docker.internal
ASTERISK_ARI_PORT=8088
ASTERISK_ARI_USERNAME=asterisk
ASTERISK_ARI_PASSWORD=asterisk
```

---

## Service Architecture

```
┌──────────────────────────────────────────────────────┐
│  Windows Host                                        │
│                                                      │
│  ┌───────────────────────────────────────────────┐   │
│  │  WSL (Ubuntu)                                 │   │
│  │  ├── Asterisk PBX     (port 8088 ARI)         │   │
│  │  ├── FreePBX           (web UI)               │   │
│  │  └── MariaDB           (FreePBX data)         │   │
│  └───────────────────────────────────────────────┘   │
│                                                      │
│  ┌───────────────────────────────────────────────┐   │
│  │  Docker                                       │   │
│  │  ├── ai_engine         (port 8090, 15000)     │   │
│  │  ├── local_ai_server   (port 8765)            │   │
│  │  └── admin_ui          (port 3003)            │   │
│  └───────────────────────────────────────────────┘   │
│                                                      │
│  SIP Phone ──dial 888──► Asterisk ──► AI Engine      │
│                              ▲              │        │
│                              │              ▼        │
│                         ARI (8088)    Google Gemini   │
└──────────────────────────────────────────────────────┘
```
