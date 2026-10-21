[CmdletBinding()]
param(
	[string]$Godot = "C:\Users\nomer\OneDrive\Desktop\godot\Godot_v3.5.1-stable_win64.exe",
	[string]$OutputDirectory = "build\web",
	[string]$GodotTemplateVersion = "3.5.1.stable"
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
# Keep the Godot editor from importing the export output as project assets.
$buildIgnore = Join-Path $projectRoot "build\.gdignore"
if (-not (Test-Path -LiteralPath $buildIgnore)) {
	New-Item -ItemType File -Path $buildIgnore | Out-Null
}
$resolvedOutputPath = (Resolve-Path -LiteralPath $outputPath).Path.TrimEnd([IO.Path]::DirectorySeparatorChar)
Get-ChildItem -LiteralPath $resolvedOutputPath -File | Where-Object {
	$_.Name -match '^index\.[0-9a-f]{12}\.(?:js|wasm|pck|[0-9]{3}\.pck|audio\.worklet\.js)$' -or $_.Name -like '*.import'
} | ForEach-Object {
	$resolvedRuntimeFile = $_.FullName
	if (-not $resolvedRuntimeFile.StartsWith($resolvedOutputPath + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
		throw "Refusing to remove a runtime file outside the web export: $resolvedRuntimeFile"
	}
	Remove-Item -LiteralPath $resolvedRuntimeFile -Force
}
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

# Godot 3 can otherwise export stale compiled scripts from its project cache
# when a source file changed outside the editor.
# Windows PowerShell 5.1 joins -ArgumentList without quoting, so paths with
# spaces must be quoted explicitly.
$importProcess = Start-Process -FilePath $Godot -ArgumentList "--path `"$projectRoot`" --editor --quit" -WindowStyle Hidden -Wait -PassThru
if ($importProcess.ExitCode -ne 0) {
	throw "Godot import refresh failed with exit code $($importProcess.ExitCode)."
}

$exportLog = Join-Path $projectRoot "build\godot-export.log"
$exportErrorLog = Join-Path $projectRoot "build\godot-export.err.log"
$exportProcess = Start-Process -FilePath $Godot -ArgumentList "--path `"$projectRoot`" --export `"Web`" `"$webEntryPoint`"" -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $exportLog -RedirectStandardError $exportErrorLog
if ($exportProcess.ExitCode -ne 0) {
	$exportErrors = (Get-Content -LiteralPath $exportErrorLog -Encoding UTF8 -Tail 20 -ErrorAction SilentlyContinue) -join [Environment]::NewLine
	throw "Godot web export failed with exit code $($exportProcess.ExitCode). Log: $exportErrorLog$([Environment]::NewLine)$exportErrors"
}
if (-not (Test-Path -LiteralPath $webEntryPoint -PathType Leaf) -or -not (Test-Path -LiteralPath (Join-Path $outputPath "index.pck") -PathType Leaf)) {
	throw "Godot web export did not produce index.html and index.pck."
}

$loadingArtSource = Join-Path $projectRoot "loadart.png"
$loadingArtDestination = Join-Path $outputPath "web-loading-art.png"
Copy-Item -LiteralPath $loadingArtSource -Destination $loadingArtDestination -Force

$imageRoot = Join-Path $projectRoot "assets\images"
# Start from an empty folder, so images removed from the project disappear from
# the upload as well.
$cgRoot = Join-Path $resolvedOutputPath "cg-assets"
if (Test-Path -LiteralPath $cgRoot) {
	Remove-Item -LiteralPath $cgRoot -Recurse -Force
}
$streamRoot = Join-Path $cgRoot "assets\images"
New-Item -ItemType Directory -Force -Path $streamRoot | Out-Null
foreach ($folder in @("fullscreen scenes", "scenes")) {
	$sourceFolder = Join-Path $imageRoot $folder
	# -Filter "*.png" also matches the "*.png.import" files next to the images.
	Get-ChildItem -LiteralPath $sourceFolder -Recurse -File | Where-Object { $_.Extension -eq ".png" } | ForEach-Object {
		$relativePath = $_.FullName.Substring($imageRoot.Length + 1)
		$destination = Join-Path $streamRoot $relativePath
		New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
		Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
	}
}

# Give the engine files a name of their own contents. They change only with the
# Godot version, so a game update keeps their URL and the browser keeps using
# the cached copy. The main pack parts are named by their own contents below.
$runtimeSuffixes = @("js", "wasm", "pck", "audio.worklet.js")
$engineSuffixes = @("js", "wasm", "audio.worklet.js")
$runtimeHashes = foreach ($suffix in $engineSuffixes) {
	$runtimeFile = Join-Path $outputPath "index.$suffix"
	if (-not (Test-Path -LiteralPath $runtimeFile -PathType Leaf)) {
		throw "Godot web runtime file not found: $runtimeFile"
	}
	(Get-FileHash -LiteralPath $runtimeFile -Algorithm SHA256).Hash
}
$hashInput = [Text.Encoding]::UTF8.GetBytes(($runtimeHashes -join ""))
$hashAlgorithm = [Security.Cryptography.SHA256]::Create()
try {
	$releaseId = ([BitConverter]::ToString($hashAlgorithm.ComputeHash($hashInput))).Replace("-", "").Substring(0, 12).ToLowerInvariant()
}
finally {
	$hashAlgorithm.Dispose()
}
$versionedBase = "index.$releaseId"

foreach ($suffix in $runtimeSuffixes) {
	Move-Item -LiteralPath (Join-Path $outputPath "index.$suffix") -Destination (Join-Path $outputPath "$versionedBase.$suffix") -Force
}

# Static hosts such as Cloudflare Pages reject files over 25 MiB, so the main
# pack is published in parts. The loading shell downloads them and joins them
# again in the browser before the engine starts. Each part is named by its own
# contents, so after an update players download only the parts that changed.
# Godot packs the images first and the game scripts (gui_modules, src) at the
# end, so a code change touches only the first part (the file table) and the
# last few.
$packPartSize = 20MB
$packName = "$versionedBase.pck"
$packPath = Join-Path $outputPath $packName
$packSize = (Get-Item -LiteralPath $packPath).Length
$packParts = @()
$partBuffer = New-Object byte[] $packPartSize
$packStream = [IO.File]::OpenRead($packPath)
$hashAlgorithm = [Security.Cryptography.SHA256]::Create()
try {
	while ($packStream.Position -lt $packSize) {
		$partLength = 0
		while ($partLength -lt $packPartSize) {
			$read = $packStream.Read($partBuffer, $partLength, $packPartSize - $partLength)
			if ($read -le 0) {
				break
			}
			$partLength += $read
		}
		$partHash = ([BitConverter]::ToString($hashAlgorithm.ComputeHash($partBuffer, 0, $partLength))).Replace("-", "").Substring(0, 12).ToLowerInvariant()
		$partName = "index.$partHash.pck"
		$partStream = [IO.File]::Create((Join-Path $outputPath $partName))
		try {
			$partStream.Write($partBuffer, 0, $partLength)
		}
		finally {
			$partStream.Dispose()
		}
		$packParts += [ordered]@{ file = $partName; size = $partLength }
	}
}
finally {
	$packStream.Dispose()
	$hashAlgorithm.Dispose()
}
Remove-Item -LiteralPath $packPath -Force
$packManifest = [ordered]@{ path = $packName; size = $packSize; parts = $packParts } | ConvertTo-Json -Compress -Depth 3

# Windows PowerShell 5.1 reads and writes the system ANSI code page by default,
# which can corrupt the UTF-8 characters of the loading shell.
$utf8NoBom = New-Object Text.UTF8Encoding $false
$html = [IO.File]::ReadAllText($webEntryPoint, $utf8NoBom)
$expectedRuntimeReferences = @("src='index.js'", '"executable":"index"', '"index.pck":', '"index.wasm":', '/*STRIVE_PCK_PARTS*/null')
foreach ($reference in $expectedRuntimeReferences) {
	if (-not $html.Contains($reference)) {
		throw "Godot export HTML is missing the expected runtime reference: $reference"
	}
}
$html = $html.Replace("src='index.js'", "src='$versionedBase.js'")
$html = $html.Replace('"executable":"index"', '"executable":"' + $versionedBase + '"')
$html = $html.Replace('"index.pck":', '"' + $versionedBase + '.pck":')
$html = $html.Replace('"index.wasm":', '"' + $versionedBase + '.wasm":')
$html = $html.Replace('/*STRIVE_PCK_PARTS*/null', $packManifest)
foreach ($reference in $expectedRuntimeReferences) {
	if ($html.Contains($reference)) {
		throw "Failed to version the runtime reference in Godot export HTML: $reference"
	}
}
[IO.File]::WriteAllText($webEntryPoint, $html, $utf8NoBom)

# Cache rules for Cloudflare Pages (Firebase uses firebase.json instead).
Copy-Item -LiteralPath (Join-Path $projectRoot "web\_headers") -Destination (Join-Path $outputPath "_headers") -Force

Write-Host "Web export ready: $outputPath"
Write-Host "CG assets are served from: $(Join-Path $outputPath 'cg-assets')"
Write-Host "Main pack: $($packParts.Count) parts of up to $($packPartSize / 1MB) MiB"
Write-Host "Engine version: $releaseId"
