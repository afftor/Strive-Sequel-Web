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
# The cuts are placed by the contents too: a part ends where a rolling hash of
# its last 64 bytes matches a fixed pattern. A file that grows or shrinks
# shifts every byte after it, but the cuts move along with those bytes, so only
# the parts around the change get new names. The file table at the start of
# the pack changes with every update, so it is cut off into a part of its own.
$packPartMinSize = 512KB
$packPartMaxSize = 24MB
# After the minimum size, a cut comes on average every 2^21 bytes (2 MiB).
$packPartMaskBits = 21
Add-Type -TypeDefinition @'
using System.Collections.Generic;
using System.IO;

public static class StrivePackCutter
{
	// Must never change: a different table would move every cut, and players
	// would download the whole pack again.
	static readonly ulong[] Gear = MakeGear();

	static ulong[] MakeGear()
	{
		var gear = new ulong[256];
		ulong state = 0;
		for (int i = 0; i < gear.Length; i++)
		{
			// splitmix64
			state += 0x9E3779B97F4A7C15UL;
			ulong z = state;
			z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9UL;
			z = (z ^ (z >> 27)) * 0x94D049BB133111EBUL;
			gear[i] = z ^ (z >> 31);
		}
		return gear;
	}

	// Where the file table of a Godot 3 pack ends. The table holds the offset
	// and MD5 of every file, so any change rewrites it.
	public static long TableEnd(string path)
	{
		using (var reader = new BinaryReader(File.OpenRead(path)))
		{
			if (reader.ReadUInt32() != 0x43504447 || reader.ReadUInt32() != 1)
			{
				throw new InvalidDataException("Not a Godot 3 pack: " + path);
			}
			// After the engine version and 16 reserved words.
			reader.BaseStream.Position = 84;
			int count = reader.ReadInt32();
			for (int i = 0; i < count; i++)
			{
				int pathLength = reader.ReadInt32();
				// Path, offset, size and MD5.
				reader.BaseStream.Position += pathLength + 8 + 8 + 16;
			}
			return reader.BaseStream.Position;
		}
	}

	// Returns the length of each part, in order. One part always ends at
	// firstCut.
	public static int[] Cut(string path, long firstCut, int minSize, int maskBits, int maxSize)
	{
		// Bit k of the gear hash depends on the last k + 1 bytes only, so the
		// top bits cover the last 64 bytes.
		ulong mask = ~0UL << (64 - maskBits);
		var lengths = new List<int>();
		var buffer = new byte[1 << 20];
		long position = 0;
		int length = 0;
		ulong hash = 0;
		using (var stream = File.OpenRead(path))
		{
			int read;
			while ((read = stream.Read(buffer, 0, buffer.Length)) > 0)
			{
				for (int i = 0; i < read; i++)
				{
					hash = (hash << 1) + Gear[buffer[i]];
					length++;
					position++;
					if (position == firstCut || (length >= minSize && (hash & mask) == 0) || length >= maxSize)
					{
						lengths.Add(length);
						length = 0;
						hash = 0;
					}
				}
			}
		}
		if (length > 0)
		{
			lengths.Add(length);
		}
		return lengths.ToArray();
	}
}
'@
$packName = "$versionedBase.pck"
$packPath = Join-Path $outputPath $packName
$packSize = (Get-Item -LiteralPath $packPath).Length
$packParts = @()
$packTableEnd = [StrivePackCutter]::TableEnd($packPath)
$partLengths = [StrivePackCutter]::Cut($packPath, $packTableEnd, $packPartMinSize, $packPartMaskBits, $packPartMaxSize)
$partBuffer = New-Object byte[] $packPartMaxSize
$packStream = [IO.File]::OpenRead($packPath)
$hashAlgorithm = [Security.Cryptography.SHA256]::Create()
try {
	foreach ($partLength in $partLengths) {
		$filled = 0
		while ($filled -lt $partLength) {
			$read = $packStream.Read($partBuffer, $filled, $partLength - $filled)
			if ($read -le 0) {
				throw "The main pack ended before its last part: $packPath"
			}
			$filled += $read
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
Write-Host "Main pack: $($packParts.Count) parts of up to $($packPartMaxSize / 1MB) MiB"
Write-Host "Engine version: $releaseId"
