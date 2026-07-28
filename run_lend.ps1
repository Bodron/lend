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
$localBaseUrl = $envValues["APP_BASE_URL_LOCAL"]
$devBaseUrl = $envValues["APP_BASE_URL_DEV"]

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
      flutter run @FlutterArgs
    } else {
      Write-Host "Pornesc Flutter in LOCAL: $localBaseUrl"
      flutter run --dart-define=APP_BASE_URL=$localBaseUrl @FlutterArgs
    }
  }
  "2" {
    Write-Host "Pornesc Flutter in DEV: $devBaseUrl"
    flutter run --dart-define=APP_BASE_URL=$devBaseUrl @FlutterArgs
  }
  default {
    Write-Host "Varianta invalida. Alege 1 sau 2."
    exit 1
  }
}
