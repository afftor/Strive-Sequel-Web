[CmdletBinding()]
param(
	[string]$Godot = "C:\Users\1\Desktop\godot\Godot_v3.5.3-stable_win64.exe",
	[string]$OutputDirectory = "build\web",
	[string]$GodotTemplateVersion = "3.5.3.stable"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputPath = Join-Path $projectRoot $OutputDirectory
$systemAppData = $env:APPDATA
$godotUserCache = Join-Path $projectRoot "build\godot-user"
$templateSource = Join-Path $systemAppData "Godot\templates\$GodotTemplateVersion"
$templateDestination = Join-Path $godotUserCache "Godot\templates\$GodotTemplateVersion"

if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
	throw "Godot executable not found: $Godot"
}

New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
if (-not (Test-Path -LiteralPath $templateSource -PathType Container)) {
	throw "Godot web templates not found: $templateSource"
}
New-Item -ItemType Directory -Force -Path $templateDestination | Out-Null
foreach ($template in @("webassembly_debug.zip", "webassembly_release.zip", "version.txt")) {
	Copy-Item -LiteralPath (Join-Path $templateSource $template) -Destination $templateDestination -Force
}

$env:APPDATA = $godotUserCache
$env:LOCALAPPDATA = $godotUserCache
$webEntryPoint = Join-Path $outputPath "index.html"
& $Godot --path $projectRoot --export "Web" $webEntryPoint
$exportExitCode = $LASTEXITCODE
if ($null -ne $exportExitCode -and $exportExitCode -ne 0) {
	throw "Godot web export failed with exit code $exportExitCode."
}
if (-not (Test-Path -LiteralPath $webEntryPoint -PathType Leaf) -or -not (Test-Path -LiteralPath (Join-Path $outputPath "index.pck") -PathType Leaf)) {
	throw "Godot web export did not produce index.html and index.pck."
}

$loadingArtSource = Join-Path $projectRoot "loadart.png"
$loadingArtDestination = Join-Path $outputPath "web-loading-art.png"
Copy-Item -LiteralPath $loadingArtSource -Destination $loadingArtDestination -Force

$imageRoot = Join-Path $projectRoot "assets\images"
$streamRoot = Join-Path $outputPath "cg-assets\assets\images"
New-Item -ItemType Directory -Force -Path $streamRoot | Out-Null
foreach ($folder in @("fullscreen scenes", "scenes")) {
	$sourceFolder = Join-Path $imageRoot $folder
	Get-ChildItem -LiteralPath $sourceFolder -Recurse -File -Filter "*.png" | ForEach-Object {
		$relativePath = $_.FullName.Substring($imageRoot.Length + 1)
		$destination = Join-Path $streamRoot $relativePath
		New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
		Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
	}
}

Write-Host "Web export ready: $outputPath"
Write-Host "CG assets are served from: $(Join-Path $outputPath 'cg-assets')"
