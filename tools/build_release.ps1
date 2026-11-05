# بناء نسخ التوزيع (APK + Web) بعنوان خادم محدّد.
# مخرجات واحدة فقط: C:\Users\tahali\Pictures\APK
#
# مثال:
#   powershell -ExecutionPolicy Bypass -File tools\build_release.ps1 -Server https://gold-pulse-api.onrender.com

param(
  [Parameter(Mandatory = $true)][string]$Server,
  [switch]$SkipApk,
  [switch]$SkipWeb
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "flutter\gold_pulse_app"
$target = "C:\Users\tahali\Pictures\APK"
New-Item -ItemType Directory -Force -Path $target | Out-Null

$env:JAVA_HOME = "C:\Android\jdk17"
$env:ANDROID_HOME = "C:\Android\sdk"
$env:ANDROID_SDK_ROOT = "C:\Android\sdk"
$env:Path = "C:\Android\jdk17\bin;C:\src\flutter\bin;" + $env:Path

Push-Location $app
try {
  if (-not $SkipApk) {
    Write-Host "==> بناء APK ..." -ForegroundColor Cyan
    flutter build apk --release --dart-define=API_BASE=$Server
    $apk = Join-Path $app "build\app\outputs\flutter-apk\app-release.apk"
    Copy-Item $apk (Join-Path $target "gold_pulse.apk") -Force
    Write-Host "APK: $target\gold_pulse.apk" -ForegroundColor Green
  }

  if (-not $SkipWeb) {
    Write-Host "==> بناء الويب ..." -ForegroundColor Cyan
    # بدون API_BASE: تطبيق الويب يتصل بالخادم من نفس الأصل تلقائياً.
    flutter build web --release
    $web = Join-Path $app "build\web"

    # نسخة يقدّمها الخادم نفسه على / (مهم للنشر السحابي).
    $cloudWeb = Join-Path $root "webapp"
    if (Test-Path $cloudWeb) { Remove-Item $cloudWeb -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $cloudWeb | Out-Null
    Copy-Item "$web\*" $cloudWeb -Recurse -Force

    $zip = Join-Path $target "gold_pulse_web.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path "$web\*" -DestinationPath $zip -CompressionLevel Optimal
    Write-Host "WEB: $zip" -ForegroundColor Green
  }
}
finally {
  Pop-Location
}

Write-Host "تم. الخادم المستخدم: $Server" -ForegroundColor Yellow
