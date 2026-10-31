[CmdletBinding()]
param(
	[string]$Wrangler = (Join-Path $env:LOCALAPPDATA "Programs\wrangler\node_modules\.bin\wrangler.cmd"),
	[string]$NodeDirectory = (Join-Path $env:LOCALAPPDATA "Programs\node")
)

# Uploads the result of web_export.ps1 to Cloudflare Pages, together with the
# statistics function in web\cloudflare\functions. The project, the output
# folder and the D1 database are configured in web\cloudflare\wrangler.toml.
# Run `wrangler login` once before the first deployment. Unchanged files are
# not uploaded again.

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$cloudflareRoot = Join-Path $projectRoot "web\cloudflare"

if (-not (Test-Path -LiteralPath (Join-Path $projectRoot "build\web\index.html") -PathType Leaf)) {
	throw "No web export found in build\web. Run web_export.ps1 first."
}
if (-not (Test-Path -LiteralPath $Wrangler -PathType Leaf)) {
	throw "wrangler not found: $Wrangler"
}

# wrangler.cmd starts node.exe from PATH.
$env:PATH = "$NodeDirectory;$env:PATH"
$env:WRANGLER_SEND_METRICS = "false"
# wrangler reads wrangler.toml and the functions folder from the working directory.
Push-Location -LiteralPath $cloudflareRoot
try {
	& $Wrangler pages deploy --branch main --commit-message "Web build"
	if ($LASTEXITCODE -ne 0) {
		throw "Cloudflare Pages deployment failed with exit code $LASTEXITCODE."
	}
}
finally {
	Pop-Location
}
