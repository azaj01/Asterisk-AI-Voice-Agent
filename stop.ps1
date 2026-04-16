# Stop Asterisk AI Voice Agent
Write-Host "🛑 Stopping Docker Services..." -ForegroundColor Yellow
docker compose down

Write-Host "`n📉 Stopping Asterisk in WSL..." -ForegroundColor Yellow
wsl -u root -d Ubuntu fwconsole stop

Write-Host "`n💤 System shut down successfully." -ForegroundColor Gray
