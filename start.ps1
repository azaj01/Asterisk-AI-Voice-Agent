# Start Asterisk AI Voice Agent
Write-Host "🚀 Starting Asterisk in WSL..." -ForegroundColor Cyan
wsl -u root -d Ubuntu fwconsole start

Write-Host "`n🐳 Starting Docker Services (AI Engine, Admin UI)..." -ForegroundColor Cyan
docker compose up -d

Write-Host "`n✅ System is coming online!" -ForegroundColor Green
Write-Host "  - Asterisk: Running (WSL)"
Write-Host "  - AI Engine: Starting (Docker)"
Write-Host "  - Admin UI: http://localhost:3003"
Write-Host "`nDial 888 from your softphone to test."
