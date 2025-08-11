<#
.SYNOPSIS
    Publishes the AMA.ALZ PowerShell module to the PowerShell Gallery.

.DESCRIPTION
    This script publishes the AMA.ALZ module to the PowerShell Gallery using the module manifest file.
    It validates the module before publishing and handles authentication using API keys.

.PARAMETER ModulePath
    The path to the module to publish. Defaults to the built module in the Artifacts folder.

.PARAMETER ApiKey
    The API key for PowerShell Gallery authentication. Can be passed as parameter or set as environment variable PSGalleryApiKey.

.PARAMETER Repository
    The repository to publish to. Defaults to 'PSGallery'.

.PARAMETER WhatIf
    Shows what would happen without actually publishing the module.

.PARAMETER Force
    Forces the publication even if the module already exists (for updates).

.PARAMETER DryRun
    Performs a dry run to validate the module without publishing.

.EXAMPLE
    .\Publish-ModuleToPSGallery.ps1 -ApiKey "your-api-key"

    Publishes the module to PowerShell Gallery using the specified API key.

.EXAMPLE
    .\Publish-ModuleToPSGallery.ps1 -WhatIf

    Shows what would happen without actually publishing.

.EXAMPLE
    .\Publish-ModuleToPSGallery.ps1 -DryRun

    Performs validation checks without publishing.

.NOTES
    - Requires PowerShellGet module
    - API key can be obtained from https://www.powershellgallery.com/account/apikeys
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
    [switch]$DryRun
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
function Test-ModuleForPublishing {
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

# Function to check if module version already exists
function Test-ModuleVersionExists {
    param(
        [string]$ModuleName,
        [version]$Version,
        [string]$Repository
    )

    try {
        $existingModule = Find-Module -Name $ModuleName -RequiredVersion $Version -Repository $Repository -ErrorAction SilentlyContinue
        return $null -ne $existingModule
    }
    catch {
        return $false
    }
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
    Write-ColorOutput "Starting PowerShell Gallery publishing process..." -ForegroundColor Magenta
    Write-ColorOutput "Repository: $Repository" -ForegroundColor Cyan

    # Test prerequisites
    Test-Prerequisites

    # Resolve module path
    $resolvedModulePath = Resolve-ModulePath -Path $ModulePath
    Write-ColorOutput "Using module path: $resolvedModulePath" -ForegroundColor Cyan

    # Validate module
    $moduleManifest = Test-ModuleForPublishing -Path $resolvedModulePath

    # Check if this is a dry run
    if ($DryRun) {
        Write-ColorOutput "DRY RUN: Module validation completed successfully. No publishing performed." -ForegroundColor Yellow
        return
    }

    # Get API key
    $galleryApiKey = Get-ApiKey -ApiKey $ApiKey

    # Check if module version already exists
    $moduleExists = Test-ModuleVersionExists -ModuleName $moduleManifest.Name -Version $moduleManifest.Version -Repository $Repository

    if ($moduleExists -and -not $Force) {
        Write-ColorOutput "Module version $($moduleManifest.Version) already exists in $Repository." -ForegroundColor Yellow
        Write-ColorOutput "Use -Force parameter to update an existing version (if allowed by the repository)." -ForegroundColor Yellow
        return
    }

    if ($moduleExists -and $Force) {
        Write-ColorOutput "Module version $($moduleManifest.Version) already exists. Force publishing..." -ForegroundColor Yellow
    }

    # Publish module
    if ($PSCmdlet.ShouldProcess($moduleManifest.Name, "Publish to $Repository")) {
        Write-ColorOutput "Publishing module to $Repository..." -ForegroundColor Yellow

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
            Verbose     = $VerbosePreference -eq 'Continue'
        }

        if ($Force -and $moduleExists) {
            $publishParams['Force'] = $true
        }

        try {
            Publish-Module @publishParams

            Write-ColorOutput "Module published successfully!" -ForegroundColor Green
            Write-ColorOutput "Module: $($moduleManifest.Name) v$($moduleManifest.Version)" -ForegroundColor Green
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
