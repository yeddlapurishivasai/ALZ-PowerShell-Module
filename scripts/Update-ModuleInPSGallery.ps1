<#
.SYNOPSIS
    Updates an existing AMA.ALZ PowerShell module in the PowerShell Gallery.

.DESCRIPTION
    This script updates an existing module in the PowerShell Gallery with a new version.
    It validates the new version is higher than the existing version and handles the update process.

.PARAMETER ModulePath
    The path to the updated module. Defaults to the built module in the Artifacts folder.

.PARAMETER ApiKey
    The API key for PowerShell Gallery authentication. Can be passed as parameter or set as environment variable PSGalleryApiKey.

.PARAMETER Repository
    The repository to update in. Defaults to 'PSGallery'.

.PARAMETER WhatIf
    Shows what would happen without actually updating the module.

.PARAMETER Force
    Forces the update even if validation warnings exist.

.PARAMETER SkipVersionCheck
    Skips the version comparison check (use with caution).

.EXAMPLE
    .\Update-ModuleInPSGallery.ps1 -ApiKey "your-api-key"

    Updates the module in PowerShell Gallery using the specified API key.

.EXAMPLE
    .\Update-ModuleInPSGallery.ps1 -WhatIf

    Shows what would happen without actually updating.

.EXAMPLE
    .\Update-ModuleInPSGallery.ps1 -Force -SkipVersionCheck

    Forces update without version validation (use with caution).

.NOTES
    - Requires PowerShellGet module
    - API key can be obtained from https://www.powershellgallery.com/account/apikeys
    - New version must be higher than the existing published version
    - Set PSGalleryApiKey environment variable to avoid passing API key as parameter
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$ModulePath,

    [Parameter()]
    [string]$ApiKey,

    [Parameter()]
    [string]$Repository = 'PSGallery',

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$SkipVersionCheck
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
function Test-ModuleForUpdate {
    param([string]$Path)

    Write-ColorOutput "Validating module at: $Path" -ForegroundColor Yellow

    # Check if manifest file exists
    $manifestPath = Join-Path -Path $Path -ChildPath 'AMA.ALZ.psd1'
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

        return $manifest
    }
    catch {
        throw "Module manifest validation failed: $($_.Exception.Message)"
    }
}

# Function to get existing module version
function Get-ExistingModuleVersion {
    param(
        [string]$ModuleName,
        [string]$Repository
    )

    try {
        Write-ColorOutput "Checking existing module version in $Repository..." -ForegroundColor Yellow
        $existingModule = Find-Module -Name $ModuleName -Repository $Repository -ErrorAction Stop

        Write-ColorOutput "Found existing module version: $($existingModule.Version)" -ForegroundColor Cyan
        return $existingModule
    }
    catch {
        if ($_.Exception.Message -like "*No match was found*") {
            Write-ColorOutput "Module not found in $Repository. This will be a new publication." -ForegroundColor Yellow
            return $null
        }
        throw "Error checking existing module: $($_.Exception.Message)"
    }
}

# Function to compare versions
function Test-VersionIsNewer {
    param(
        [version]$NewVersion,
        [version]$ExistingVersion
    )

    return $NewVersion -gt $ExistingVersion
}

# Function to get API key
function Get-ApiKey {
    param([string]$ApiKey)

    if ([string]::IsNullOrEmpty($ApiKey)) {
        $ApiKey = $env:PSGalleryApiKey
    }

    if ([string]::IsNullOrEmpty($ApiKey)) {
        throw "API Key is required. Provide it via -ApiKey parameter or set PSGalleryApiKey environment variable."
    }

    return $ApiKey
}

# Main execution
try {
    Write-ColorOutput "Starting PowerShell Gallery module update process..." -ForegroundColor Magenta
    Write-ColorOutput "Repository: $Repository" -ForegroundColor Cyan

    # Test prerequisites
    Test-Prerequisites

    # Resolve module path
    $resolvedModulePath = Resolve-ModulePath -Path $ModulePath
    Write-ColorOutput "Using module path: $resolvedModulePath" -ForegroundColor Cyan

    # Validate module
    $moduleManifest = Test-ModuleForUpdate -Path $resolvedModulePath

    # Get existing module version
    $existingModule = Get-ExistingModuleVersion -ModuleName $moduleManifest.Name -Repository $Repository

    # Version validation
    if ($existingModule -and -not $SkipVersionCheck) {
        $isNewer = Test-VersionIsNewer -NewVersion $moduleManifest.Version -ExistingVersion $existingModule.Version

        if (-not $isNewer) {
            $message = "New version ($($moduleManifest.Version)) must be higher than existing version ($($existingModule.Version))"
            if ($Force) {
                Write-ColorOutput "WARNING: $message. Continuing due to -Force parameter." -ForegroundColor Yellow
            } else {
                throw "$message. Use -Force to override or -SkipVersionCheck to skip this validation."
            }
        } else {
            Write-ColorOutput "Version check passed: $($moduleManifest.Version) > $($existingModule.Version)" -ForegroundColor Green
        }
    } elseif ($SkipVersionCheck) {
        Write-ColorOutput "WARNING: Version check skipped as requested." -ForegroundColor Yellow
    }

    # Get API key
    $galleryApiKey = Get-ApiKey -ApiKey $ApiKey

    # Update/Publish module
    if ($PSCmdlet.ShouldProcess($moduleManifest.Name, "Update in $Repository")) {
        Write-ColorOutput "Updating module in $Repository..." -ForegroundColor Yellow

        # Create clean module structure for publishing (exclude build artifacts)
        $cleanTempPath = Join-Path $env:TEMP "$($moduleManifest.Name).Clean"
        $cleanModulePath = Join-Path $cleanTempPath $moduleManifest.Name

        Write-ColorOutput "Creating clean module structure at: $cleanTempPath" -ForegroundColor Gray

        # Remove old temp if exists
        if (Test-Path $cleanTempPath) {
            Remove-Item $cleanTempPath -Recurse -Force
        }

        # Create clean structure
        New-Item $cleanModulePath -ItemType Directory -Force | Out-Null

        # Copy only essential files (exclude build artifacts like ccReport, testOutput)
        $manifestPath = Join-Path $resolvedModulePath "$($moduleManifest.Name).psd1"
        $moduleFile = Join-Path $resolvedModulePath "$($moduleManifest.Name).psm1"
        $privatePath = Join-Path $resolvedModulePath "Private"
        $publicPath = Join-Path $resolvedModulePath "Public"

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
            NuGetApiKey = $galleryApiKey
            Force       = $true  # Force is needed for updates
            Verbose     = $VerbosePreference -eq 'Continue'
        }

        try {
            Publish-Module @publishParams

            Write-ColorOutput "Module updated successfully!" -ForegroundColor Green
            Write-ColorOutput "Module: $($moduleManifest.Name) v$($moduleManifest.Version)" -ForegroundColor Green

            if ($existingModule) {
                Write-ColorOutput "Updated from version: $($existingModule.Version)" -ForegroundColor Cyan
            }

            Write-ColorOutput "You can view it at: https://www.powershellgallery.com/packages/$($moduleManifest.Name)/$($moduleManifest.Version)" -ForegroundColor Cyan
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
catch {
    Write-ColorOutput "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-ColorOutput "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
