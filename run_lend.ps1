param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

function Read-DotEnv {
  param([string]$Path)

  $values = @{}

  if (-not (Test-Path -LiteralPath $Path)) {
    return $values
  }

  foreach ($line in Get-Content -LiteralPath $Path) {
    $trimmed = $line.Trim()

    if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) {
      continue
    }

    $parts = $trimmed.Split("=", 2)
    if ($parts.Count -ne 2) {
      continue
    }

    $key = $parts[0].Trim()
    $value = $parts[1].Trim().Trim('"').Trim("'")

    if ($key.Length -gt 0) {
      $values[$key] = $value
    }
  }

  return $values
}

$envValues = Read-DotEnv -Path (Join-Path $PSScriptRoot ".env")
$backendEnvValues = Read-DotEnv -Path (Join-Path $PSScriptRoot "backend\.env")
$localBaseUrl = $envValues["APP_BASE_URL_LOCAL"]
$devBaseUrl = $envValues["APP_BASE_URL_DEV"]
$googleIosClientId = $envValues["GOOGLE_IOS_CLIENT_ID"]
$googleServerClientId = $envValues["GOOGLE_SERVER_CLIENT_ID"]
$googleClientIds = $envValues["GOOGLE_CLIENT_IDS"]
$googleMapsAndroidApiKey = $envValues["GOOGLE_MAPS_ANDROID_API_KEY"]
$googleMapsIosApiKey = $envValues["GOOGLE_MAPS_IOS_API_KEY"]

if ([string]::IsNullOrWhiteSpace($googleIosClientId)) {
  $googleIosClientId = $env:GOOGLE_IOS_CLIENT_ID
}

if ([string]::IsNullOrWhiteSpace($googleServerClientId)) {
  $googleServerClientId = $env:GOOGLE_SERVER_CLIENT_ID
}

if ([string]::IsNullOrWhiteSpace($googleClientIds)) {
  $googleClientIds = $env:GOOGLE_CLIENT_IDS
}

if ([string]::IsNullOrWhiteSpace($googleMapsAndroidApiKey)) {
  $googleMapsAndroidApiKey = $env:GOOGLE_MAPS_ANDROID_API_KEY
}

if ([string]::IsNullOrWhiteSpace($googleMapsIosApiKey)) {
  $googleMapsIosApiKey = $env:GOOGLE_MAPS_IOS_API_KEY
}

if ([string]::IsNullOrWhiteSpace($googleClientIds)) {
  $googleClientIds = $backendEnvValues["GOOGLE_CLIENT_IDS"]
}

$googleIds = @()
if (-not [string]::IsNullOrWhiteSpace($googleClientIds)) {
  $googleIds = $googleClientIds.Split(",") |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_.Length -gt 0 }
}

if ([string]::IsNullOrWhiteSpace($googleIosClientId) -and $googleIds.Count -gt 0) {
  $googleIosClientId = $googleIds[0]
}

if ([string]::IsNullOrWhiteSpace($googleServerClientId) -and $googleIds.Count -gt 0) {
  $googleServerClientId = $googleIds[$googleIds.Count - 1]
}

$googleDartDefines = @()
if (-not [string]::IsNullOrWhiteSpace($googleIosClientId)) {
  $googleDartDefines += "--dart-define=GOOGLE_IOS_CLIENT_ID=$googleIosClientId"
}

if (-not [string]::IsNullOrWhiteSpace($googleServerClientId)) {
  $googleDartDefines += "--dart-define=GOOGLE_SERVER_CLIENT_ID=$googleServerClientId"
}

if (-not [string]::IsNullOrWhiteSpace($googleMapsAndroidApiKey)) {
  $googleDartDefines += "--dart-define=GOOGLE_MAPS_ANDROID_API_KEY=$googleMapsAndroidApiKey"
}

if (-not [string]::IsNullOrWhiteSpace($googleMapsIosApiKey)) {
  $googleDartDefines += "--dart-define=GOOGLE_MAPS_IOS_API_KEY=$googleMapsIosApiKey"
}

if (-not [string]::IsNullOrWhiteSpace($googleMapsAndroidApiKey)) {
  $androidLocalPropertiesPath = Join-Path $PSScriptRoot "android\local.properties"
  $androidLocalProperties = Read-DotEnv -Path $androidLocalPropertiesPath
  $androidLocalProperties["GOOGLE_MAPS_ANDROID_API_KEY"] = $googleMapsAndroidApiKey
  $androidLocalProperties.GetEnumerator() |
    Sort-Object Name |
    ForEach-Object { "$($_.Name)=$($_.Value)" } |
    Set-Content -LiteralPath $androidLocalPropertiesPath
}

if (-not [string]::IsNullOrWhiteSpace($googleMapsIosApiKey)) {
  $iosMapsConfigPath = Join-Path $PSScriptRoot "ios\Flutter\MapsKeys.xcconfig"
  "GOOGLE_MAPS_IOS_API_KEY=$googleMapsIosApiKey" |
    Set-Content -LiteralPath $iosMapsConfigPath
}

if ([string]::IsNullOrWhiteSpace($localBaseUrl)) {
  $localBaseUrl = $env:APP_BASE_URL_LOCAL
}

if ([string]::IsNullOrWhiteSpace($devBaseUrl)) {
  $devBaseUrl = $env:APP_BASE_URL_DEV
}

if ([string]::IsNullOrWhiteSpace($devBaseUrl)) {
  $devBaseUrl = "https://lend.bcmenu.ro"
}

Write-Host ""
Write-Host "Cum vrei sa rulezi Lend Everything?"
Write-Host "1. Local - configuratia existenta (localhost / 10.0.2.2)"
Write-Host "2. Dev   - $devBaseUrl"
Write-Host ""

$choice = Read-Host "Alege varianta (1/2)"

switch ($choice) {
  "1" {
    if ([string]::IsNullOrWhiteSpace($localBaseUrl)) {
      Write-Host "Pornesc Flutter in LOCAL cu fallback-ul din aplicatie..."
      flutter run @googleDartDefines @FlutterArgs
    } else {
      Write-Host "Pornesc Flutter in LOCAL: $localBaseUrl"
      flutter run --dart-define=APP_BASE_URL=$localBaseUrl @googleDartDefines @FlutterArgs
    }
  }
  "2" {
    Write-Host "Pornesc Flutter in DEV: $devBaseUrl"
    flutter run --dart-define=APP_BASE_URL=$devBaseUrl @googleDartDefines @FlutterArgs
  }
  default {
    Write-Host "Varianta invalida. Alege 1 sau 2."
    exit 1
  }
}
