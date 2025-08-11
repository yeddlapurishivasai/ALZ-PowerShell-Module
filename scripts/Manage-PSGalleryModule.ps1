<#
.SYNOPSIS
    Comprehensive PowerShell Gallery management script for the AMA.ALZ module.

.DESCRIPTION
    This script provides a unified interface for managing the AMA.ALZ module in PowerShell Gallery.
    It supports publishing, updating, unlisting, and checking status of the module.

.PARAMETER Action
    The action to perform. Valid values: 'Publish', 'Update', 'Unlist', 'Status', 'ValidateOnly'.

.PARAMETER ModulePath
    The path to the module. Defaults to the built module in the Artifacts folder.

.PARAMETER ApiKey
    The API key for PowerShell Gallery authentication. Can be passed as parameter or set as environment variable PSGalleryApiKey.

.PARAMETER Repository
    The repository to work with. Defaults to 'PSGallery'.

.PARAMETER Version
    Specific version for unlisting operations. Required only for 'Unlist' action.

.PARAMETER WhatIf
    Shows what would happen without actually performing the action.

.PARAMETER Force
    Forces the action without additional confirmation prompts.

.PARAMETER ModuleName
    The name of the module. Defaults to 'AMA.ALZ'.

.EXAMPLE
    .\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key"

    Publishes the module to PowerShell Gallery.

.EXAMPLE
    .\Manage-PSGalleryModule.ps1 -Action Update -ApiKey "your-api-key"

    Updates an existing module in PowerShell Gallery.

.EXAMPLE
    .\Manage-PSGalleryModule.ps1 -Action Unlist -Version "0.1.0" -ApiKey "your-api-key"

    Unlists a specific version from PowerShell Gallery.

.EXAMPLE
    .\Manage-PSGalleryModule.ps1 -Action Status

    Checks the current status of the module in PowerShell Gallery.

.EXAMPLE
    .\Manage-PSGalleryModule.ps1 -Action ValidateOnly -ModulePath "C:\Path\To\Module"

    Only validates the module without performing any Gallery operations.

.NOTES
    - Requires PowerShellGet module
    - API key can be obtained from https://www.powershellgallery.com/account/apikeys
    - Set PSGalleryApiKey environment variable to avoid passing API key as parameter
    - For unlisting, you must be the owner or have appropriate permissions
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Publish', 'Update', 'Unlist', 'Status', 'ValidateOnly')]
    [string]$Action,

    [Parameter()]
    [string]$ModulePath,

    [Parameter()]
    [string]$ApiKey,

    [Parameter()]
    [string]$Repository = 'PSGallery',

    [Parameter()]
    [string]$Version,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [string]$ModuleName = 'AMA.ALZ'
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$ForegroundColor = 'White'
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Function to write section header
function Write-SectionHeader {
    param([string]$Title)

    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Magenta
    Write-Host " $Title" -ForegroundColor Magenta
    Write-Host ("=" * 60) -ForegroundColor Magenta
}

# Function to validate prerequisites
function Test-Prerequisites {
    Write-ColorOutput "Validating prerequisites..." -ForegroundColor Yellow

    # Check PowerShellGet module
    if (-not (Get-Module -Name PowerShellGet -ListAvailable)) {
        throw "PowerShellGet module is required. Please install it using: Install-Module PowerShellGet -Force"
    }

    # Import PowerShellGet if not already loaded
    if (-not (Get-Module -Name PowerShellGet)) {
        Import-Module PowerShellGet -Force
    }

    Write-ColorOutput "Prerequisites validated successfully." -ForegroundColor Green
}

# Function to resolve module path
function Resolve-ModulePath {
    param([string]$Path)

    if ([string]::IsNullOrEmpty($Path)) {
        $scriptRoot = Split-Path -Parent $PSScriptRoot
        $artifactsPath = Join-Path -Path $scriptRoot -ChildPath 'src\Artifacts'

        if (-not (Test-Path $artifactsPath)) {
            throw "Default module path not found: $artifactsPath. Please build the module first or specify -ModulePath parameter."
        }

        return $artifactsPath
    }

    if (-not (Test-Path $Path)) {
        throw "Specified module path not found: $Path"
    }

    return $Path
}

# Function to validate module
function Test-ModuleValidation {
    param([string]$Path)

    Write-ColorOutput "Validating module at: $Path" -ForegroundColor Yellow

    # Check if manifest file exists
    $manifestPath = Join-Path -Path $Path -ChildPath "$ModuleName.psd1"
    if (-not (Test-Path $manifestPath)) {
        throw "Module manifest file not found: $manifestPath"
    }

    # Test module manifest
    try {
        $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
        Write-ColorOutput "Module manifest validation successful." -ForegroundColor Green
        Write-ColorOutput "  Module Name: $($manifest.Name)" -ForegroundColor Cyan
        Write-ColorOutput "  Version: $($manifest.Version)" -ForegroundColor Cyan
        Write-ColorOutput "  Author: $($manifest.Author)" -ForegroundColor Cyan
        Write-ColorOutput "  Description: $($manifest.Description)" -ForegroundColor Cyan
        Write-ColorOutput "  Functions to Export: $($manifest.ExportedFunctions.Count)" -ForegroundColor Cyan
        Write-ColorOutput "  PowerShell Version: $($manifest.PowerShellVersion)" -ForegroundColor Cyan

        return $manifest
    }
    catch {
        throw "Module manifest validation failed: $($_.Exception.Message)"
    }
}

# Function to get module status in gallery
function Get-ModuleGalleryStatus {
    param(
        [string]$ModuleName,
        [string]$Repository
    )

    try {
        Write-ColorOutput "Checking module status in $Repository..." -ForegroundColor Yellow

        # Get all versions
        $allVersions = Find-Module -Name $ModuleName -Repository $Repository -AllVersions -ErrorAction Stop
        $latestVersion = Find-Module -Name $ModuleName -Repository $Repository -ErrorAction Stop

        Write-ColorOutput "Module found in ${Repository}:" -ForegroundColor Green
        Write-ColorOutput "  Latest Version: $($latestVersion.Version)" -ForegroundColor Cyan
        Write-ColorOutput "  Total Versions: $($allVersions.Count)" -ForegroundColor Cyan
        Write-ColorOutput "  Download Count: $($latestVersion.DownloadCount)" -ForegroundColor Cyan
        Write-ColorOutput "  Published Date: $($latestVersion.PublishedDate)" -ForegroundColor Cyan
        Write-ColorOutput "  Author: $($latestVersion.Author)" -ForegroundColor Cyan
        Write-ColorOutput "  Tags: $($latestVersion.Tags -join ', ')" -ForegroundColor Cyan

        Write-ColorOutput "All available versions:" -ForegroundColor Yellow
        foreach ($version in $allVersions | Sort-Object Version -Descending) {
            Write-ColorOutput "  v$($version.Version) (Published: $($version.PublishedDate.ToString('yyyy-MM-dd')))" -ForegroundColor White
        }

        return @{
            LatestVersion = $latestVersion
            AllVersions = $allVersions
            Found = $true
        }
    }
    catch {
        if ($_.Exception.Message -like "*No match was found*") {
            Write-ColorOutput "Module '$ModuleName' not found in $Repository." -ForegroundColor Yellow
            return @{
                LatestVersion = $null
                AllVersions = @()
                Found = $false
            }
        }
        throw "Error checking module status: $($_.Exception.Message)"
    }
}

# Function to get API key
function Get-ApiKey {
    param([string]$ApiKey, [bool]$Required = $true)

    if ([string]::IsNullOrEmpty($ApiKey)) {
        $ApiKey = $env:PSGalleryApiKey
    }

    if ([string]::IsNullOrEmpty($ApiKey) -and $Required) {
        throw "API Key is required for this operation. Provide it via -ApiKey parameter or set PSGalleryApiKey environment variable."
    }

    return $ApiKey
}

# Function to perform publish action
function Invoke-PublishAction {
    param(
        [string]$ModulePath,
        [string]$ApiKey,
        [string]$Repository,
        [object]$ModuleManifest,
        [bool]$Force
    )

    Write-SectionHeader "PUBLISHING MODULE"

    # Check if module already exists
    $galleryStatus = Get-ModuleGalleryStatus -ModuleName $ModuleManifest.Name -Repository $Repository

    if ($galleryStatus.Found) {
        if ($galleryStatus.LatestVersion.Version -eq $ModuleManifest.Version) {
            Write-ColorOutput "Module version $($ModuleManifest.Version) already exists in $Repository." -ForegroundColor Yellow
            if (-not $Force) {
                throw "Use -Force parameter to override existing version (if supported by repository)."
            }
            Write-ColorOutput "Proceeding with Force option..." -ForegroundColor Yellow
        }
    }

    if ($PSCmdlet.ShouldProcess($ModuleManifest.Name, "Publish to $Repository")) {
        Write-ColorOutput "Publishing module to $Repository..." -ForegroundColor Yellow

        # Create clean module structure for publishing (exclude build artifacts)
        $cleanTempPath = Join-Path $env:TEMP "$($ModuleManifest.Name).Clean"
        $cleanModulePath = Join-Path $cleanTempPath $ModuleManifest.Name

        Write-ColorOutput "Creating clean module structure at: $cleanTempPath" -ForegroundColor Gray

        # Remove old temp if exists
        if (Test-Path $cleanTempPath) {
            Remove-Item $cleanTempPath -Recurse -Force
        }

        # Create clean structure
        New-Item $cleanModulePath -ItemType Directory -Force | Out-Null

        # Copy only essential files (exclude build artifacts like ccReport, testOutput)
        $manifestPath = Join-Path $ModulePath "$($ModuleManifest.Name).psd1"
        $moduleFile = Join-Path $ModulePath "$($ModuleManifest.Name).psm1"
        $privatePath = Join-Path $ModulePath "Private"
        $publicPath = Join-Path $ModulePath "Public"

        Copy-Item $manifestPath -Destination $cleanModulePath
        if (Test-Path $moduleFile) {
            Copy-Item $moduleFile -Destination $cleanModulePath
        }
        if (Test-Path $privatePath) {
            Copy-Item $privatePath -Destination $cleanModulePath -Recurse
        }
        if (Test-Path $publicPath) {
            Copy-Item $publicPath -Destination $cleanModulePath -Recurse
        }

        Write-ColorOutput "Using clean module path: $cleanModulePath" -ForegroundColor Gray

        $publishParams = @{
            Path        = $cleanModulePath
            Repository  = $Repository
            NuGetApiKey = $ApiKey
            Verbose     = $VerbosePreference -eq 'Continue'
        }

        if ($Force -and $galleryStatus.Found) {
            $publishParams['Force'] = $true
        }

        try {
            Publish-Module @publishParams
            Write-ColorOutput "Module published successfully!" -ForegroundColor Green
        }
        finally {
            # Clean up temporary directory
            if (Test-Path $cleanTempPath) {
                Remove-Item $cleanTempPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-ColorOutput "Cleaned up temporary directory." -ForegroundColor Gray
            }
        }
    }
}

# Function to perform update action
function Invoke-UpdateAction {
    param(
        [string]$ModulePath,
        [string]$ApiKey,
        [string]$Repository,
        [object]$ModuleManifest,
        [bool]$Force
    )

    Write-SectionHeader "UPDATING MODULE"

    # Check existing version
    $galleryStatus = Get-ModuleGalleryStatus -ModuleName $ModuleManifest.Name -Repository $Repository

    if (-not $galleryStatus.Found) {
        Write-ColorOutput "Module not found in $Repository. This will be a new publication." -ForegroundColor Yellow
    } else {
        $isNewer = $ModuleManifest.Version -gt $galleryStatus.LatestVersion.Version
        if (-not $isNewer -and -not $Force) {
            throw "New version ($($ModuleManifest.Version)) must be higher than existing version ($($galleryStatus.LatestVersion.Version)). Use -Force to override."
        }

        if ($isNewer) {
            Write-ColorOutput "Version update: $($galleryStatus.LatestVersion.Version) -> $($ModuleManifest.Version)" -ForegroundColor Green
        } else {
            Write-ColorOutput "WARNING: Forcing update without version increment." -ForegroundColor Yellow
        }
    }

    if ($PSCmdlet.ShouldProcess($ModuleManifest.Name, "Update in $Repository")) {
        Write-ColorOutput "Updating module in $Repository..." -ForegroundColor Yellow

        # Create clean module structure for publishing (exclude build artifacts)
        $cleanTempPath = Join-Path $env:TEMP "$($ModuleManifest.Name).Clean"
        $cleanModulePath = Join-Path $cleanTempPath $ModuleManifest.Name

        Write-ColorOutput "Creating clean module structure at: $cleanTempPath" -ForegroundColor Gray

        # Remove old temp if exists
        if (Test-Path $cleanTempPath) {
            Remove-Item $cleanTempPath -Recurse -Force
        }

        # Create clean structure
        New-Item $cleanModulePath -ItemType Directory -Force | Out-Null

        # Copy only essential files (exclude build artifacts like ccReport, testOutput)
        $manifestPath = Join-Path $ModulePath "$($ModuleManifest.Name).psd1"
        $moduleFile = Join-Path $ModulePath "$($ModuleManifest.Name).psm1"
        $privatePath = Join-Path $ModulePath "Private"
        $publicPath = Join-Path $ModulePath "Public"

        Copy-Item $manifestPath -Destination $cleanModulePath
        if (Test-Path $moduleFile) {
            Copy-Item $moduleFile -Destination $cleanModulePath
        }
        if (Test-Path $privatePath) {
            Copy-Item $privatePath -Destination $cleanModulePath -Recurse
        }
        if (Test-Path $publicPath) {
            Copy-Item $publicPath -Destination $cleanModulePath -Recurse
        }

        Write-ColorOutput "Using clean module path: $cleanModulePath" -ForegroundColor Gray

        try {
            Publish-Module -Path $cleanModulePath -Repository $Repository -NuGetApiKey $ApiKey -Force -Verbose:($VerbosePreference -eq 'Continue')
            Write-ColorOutput "Module updated successfully!" -ForegroundColor Green
        }
        finally {
            # Clean up temporary directory
            if (Test-Path $cleanTempPath) {
                Remove-Item $cleanTempPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-ColorOutput "Cleaned up temporary directory." -ForegroundColor Gray
            }
        }
    }
}

# Function to perform unlist action
function Invoke-UnlistAction {
    param(
        [string]$ModuleName,
        [string]$Version,
        [string]$ApiKey,
        [string]$Repository,
        [bool]$Force
    )

    Write-SectionHeader "UNLISTING MODULE"

    if ([string]::IsNullOrEmpty($Version)) {
        throw "Version parameter is required for Unlist action."
    }

    # Validate version format
    try {
        [version]$versionObj = $Version
    }
    catch {
        throw "Invalid version format: $Version"
    }

    # Check if version exists
    try {
        $existingModule = Find-Module -Name $ModuleName -RequiredVersion $Version -Repository $Repository -ErrorAction Stop
        Write-ColorOutput "Found module to unlist: $($existingModule.Name) v$($existingModule.Version)" -ForegroundColor Cyan
    }
    catch {
        throw "Module '$ModuleName' version '$Version' not found in $Repository."
    }

    # Confirm action
    if (-not $Force) {
        Write-ColorOutput "WARNING: This will unlist $ModuleName v$Version from $Repository" -ForegroundColor Red
        $confirmation = Read-Host "Continue? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-ColorOutput "Operation cancelled." -ForegroundColor Yellow
            return
        }
    }

    if ($PSCmdlet.ShouldProcess("$ModuleName v$Version", "Unlist from $Repository")) {
        Write-ColorOutput "Note: PowerShell Gallery unlisting typically requires web interface access." -ForegroundColor Yellow
        Write-ColorOutput "Visit: https://www.powershellgallery.com/packages/$ModuleName/$Version" -ForegroundColor Cyan
        Write-ColorOutput "Sign in and use the 'Manage' -> 'Unlist' option." -ForegroundColor Cyan
    }
}

# Main execution
try {
    Write-SectionHeader "POWERSHELL GALLERY MANAGEMENT - AMA.ALZ MODULE"
    Write-ColorOutput "Action: $Action" -ForegroundColor Magenta
    Write-ColorOutput "Repository: $Repository" -ForegroundColor Cyan
    Write-ColorOutput "Module: $ModuleName" -ForegroundColor Cyan

    # Test prerequisites (except for Status action)
    if ($Action -ne 'Status') {
        Test-Prerequisites
    } else {
        # For status, just try to import PowerShellGet
        Import-Module PowerShellGet -Force -ErrorAction SilentlyContinue
    }

    # Handle Status action (no module path needed)
    if ($Action -eq 'Status') {
        Write-SectionHeader "MODULE STATUS"
        Get-ModuleGalleryStatus -ModuleName $ModuleName -Repository $Repository | Out-Null
        return
    }

    # Resolve and validate module (for other actions)
    $resolvedModulePath = Resolve-ModulePath -Path $ModulePath
    Write-ColorOutput "Module Path: $resolvedModulePath" -ForegroundColor Cyan

    $moduleManifest = Test-ModuleValidation -Path $resolvedModulePath

    # Handle ValidateOnly action
    if ($Action -eq 'ValidateOnly') {
        Write-ColorOutput "Validation completed successfully. No further actions performed." -ForegroundColor Green
        return
    }

    # Get API key for actions that need it
    $galleryApiKey = Get-ApiKey -ApiKey $ApiKey -Required ($Action -ne 'Status')

    # Execute the requested action
    switch ($Action) {
        'Publish' {
            Invoke-PublishAction -ModulePath $resolvedModulePath -ApiKey $galleryApiKey -Repository $Repository -ModuleManifest $moduleManifest -Force $Force
        }
        'Update' {
            Invoke-UpdateAction -ModulePath $resolvedModulePath -ApiKey $galleryApiKey -Repository $Repository -ModuleManifest $moduleManifest -Force $Force
        }
        'Unlist' {
            Invoke-UnlistAction -ModuleName $ModuleName -Version $Version -ApiKey $galleryApiKey -Repository $Repository -Force $Force
        }
    }

    Write-SectionHeader "OPERATION COMPLETED SUCCESSFULLY"
    Write-ColorOutput "Action '$Action' completed for $ModuleName" -ForegroundColor Green

    if ($Action -in @('Publish', 'Update')) {
        Write-ColorOutput "View your module at: https://www.powershellgallery.com/packages/$ModuleName" -ForegroundColor Cyan
    }
}
catch {
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($VerbosePreference -eq 'Continue') {
        Write-ColorOutput "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    }
    exit 1
}
