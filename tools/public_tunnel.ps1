# نشر الخادم مؤقتاً على الإنترنت عبر نفق Cloudflare (بدون حساب).
# الاستخدام:
#   powershell -ExecutionPolicy Bypass -File tools\public_tunnel.ps1
# النتيجة: رابط عام مؤقت https://xxxx.trycloudflare.com يفتح من أي شبكة.
# ملاحظة: الرابط يتغيّر عند كل تشغيل، والحاسبة يجب أن تبقى شغّالة.

param(
  [int]$Port = 8010,
  [string]$Cloudflared = "C:\Program Files (x86)\cloudflared\cloudflared.exe"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$log = Join-Path $env:TEMP "gold-pulse-tunnel.log"

if (-not (Test-Path $Cloudflared)) {
  throw "cloudflared غير مثبّت. ثبّته بالأمر: winget install Cloudflare.cloudflared"
}

$listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if (-not $listening) {
  Write-Host "==> تشغيل خادم نبض الذهب على المنفذ $Port ..." -ForegroundColor Cyan
  $env:PYTHONIOENCODING = "utf-8"
  Start-Process -FilePath "python" `
    -ArgumentList "-m", "uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "$Port" `
    -WorkingDirectory $root -WindowStyle Hidden
  Start-Sleep -Seconds 8
}

if (Test-Path $log) { Remove-Item $log -Force }
Write-Host "==> فتح النفق العام ..." -ForegroundColor Cyan
Start-Process -FilePath $Cloudflared -ArgumentList @(
  "tunnel", "--url", "http://127.0.0.1:$Port", "--no-autoupdate", "--logfile", $log
) -WindowStyle Hidden

$url = $null
for ($i = 0; $i -lt 40; $i++) {
  Start-Sleep -Seconds 1
  if (Test-Path $log) {
    $m = Select-String -Path $log -Pattern "https://[a-z0-9-]+\.trycloudflare\.com" -AllMatches |
      Select-Object -First 1
    if ($m) { $url = $m.Matches[0].Value; break }
  }
}

if (-not $url) { throw "لم يتم الحصول على رابط النفق. راجع السجل: $log" }

Write-Host ""
Write-Host "الرابط العام (يعمل من أي شبكة):" -ForegroundColor Green
Write-Host "  $url" -ForegroundColor Yellow
Write-Host ""
Write-Host "اختبار سريع:" -ForegroundColor Cyan
Write-Host "  $url/health"
Write-Host "  $url/docs"
Write-Host ""
Write-Host "للتطبيق: الإعدادات ← عنوان الخادم ← $url" -ForegroundColor Cyan
Write-Host "ملاحظة: الرابط مؤقت ويتغيّر عند إعادة التشغيل." -ForegroundColor DarkYellow
