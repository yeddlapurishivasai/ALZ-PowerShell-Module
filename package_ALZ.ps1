param(
    [string]$version,
    [string]$prerelease = ""
)

New-Item "AMA.ALZ" -ItemType Directory -Force
Copy-Item -Path "./src/Artifacts/*" -Destination "./AMA.ALZ" -Recurse -Exclude "ccReport", "testOutput"  -Force

Update-ModuleManifest -Path "./AMA.ALZ/AMA.ALZ.psd1" -ModuleVersion $version -Prerelease $prerelease

