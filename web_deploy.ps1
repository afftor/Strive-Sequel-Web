[CmdletBinding()]
param(
	[string]$Wrangler = (Join-Path $env:LOCALAPPDATA "Programs\wrangler\node_modules\.bin\wrangler.cmd"),
	[string]$NodeDirectory = (Join-Path $env:LOCALAPPDATA "Programs\node"),
	[string]$ProjectName = "strive-web",
	[string]$OutputDirectory = "build\web"
)

# Uploads the result of web_export.ps1 to Cloudflare Pages. Run `wrangler login`
# once before the first deployment. Unchanged files are not uploaded again.

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputPath = Join-Path $projectRoot $OutputDirectory

if (-not (Test-Path -LiteralPath (Join-Path $outputPath "index.html") -PathType Leaf)) {
	throw "No web export found in $outputPath. Run web_export.ps1 first."
}
if (-not (Test-Path -LiteralPath $Wrangler -PathType Leaf)) {
	throw "wrangler not found: $Wrangler"
}

# wrangler.cmd starts node.exe from PATH.
$env:PATH = "$NodeDirectory;$env:PATH"
$env:WRANGLER_SEND_METRICS = "false"
& $Wrangler pages deploy $outputPath --project-name $ProjectName --branch main --commit-message "Web build"
if ($LASTEXITCODE -ne 0) {
	throw "Cloudflare Pages deployment failed with exit code $LASTEXITCODE."
}
