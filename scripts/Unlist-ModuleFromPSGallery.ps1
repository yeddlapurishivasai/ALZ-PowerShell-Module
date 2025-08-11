<#
.SYNOPSIS
    Unlists a specific version of the AMA.ALZ PowerShell module from the PowerShell Gallery.

.DESCRIPTION
    This script unlists a specific version of the module from the PowerShell Gallery.
    Unlisting removes the module from search results but keeps it available for direct download
    by users who already have dependencies on that specific version.

.PARAMETER ModuleName
    The name of the module to unlist. Defaults to 'AMA.ALZ'.

.PARAMETER Version
    The specific version to unlist. This parameter is mandatory.

.PARAMETER ApiKey
    The API key for PowerShell Gallery authentication. Can be passed as parameter or set as environment variable PSGalleryApiKey.

.PARAMETER Repository
    The repository to unlist from. Defaults to 'PSGallery'.

.PARAMETER WhatIf
    Shows what would happen without actually unlisting the module.

.PARAMETER Force
    Forces the unlisting without confirmation prompts.

.EXAMPLE
    .\Unlist-ModuleFromPSGallery.ps1 -Version "0.1.0" -ApiKey "your-api-key"

    Unlists version 0.1.0 of the AMA.ALZ module from PowerShell Gallery.

.EXAMPLE
    .\Unlist-ModuleFromPSGallery.ps1 -Version "0.1.0" -WhatIf

    Shows what would happen without actually unlisting.

.EXAMPLE
    .\Unlist-ModuleFromPSGallery.ps1 -ModuleName "AMA.ALZ" -Version "0.1.0" -Force

    Forces unlisting without confirmation prompts.

.NOTES
    - Requires PowerShellGet module and appropriate API permissions
    - API key can be obtained from https://www.powershellgallery.com/account/apikeys
    - API key must have 'Unlist Package' permissions
    - Unlisted packages are still available for download but not in search results
    - Set PSGalleryApiKey environment variable to avoid passing API key as parameter
    - You must be the owner or have permissions to unlist the module
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$ModuleName = 'AMA.ALZ',

    [Parameter(Mandatory = $true)]
    [string]$Version,

    [Parameter()]
    [string]$ApiKey,

    [Parameter()]
    [string]$Repository = 'PSGallery',

    [Parameter()]
    [switch]$Force
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

# Function to validate version format
function Test-VersionFormat {
    param([string]$Version)

    try {
        [version]$versionObject = $Version
        return $true
    }
    catch {
        return $false
    }
}

# Function to check if module version exists
function Test-ModuleVersionExists {
    param(
        [string]$ModuleName,
        [string]$Version,
        [string]$Repository
    )

    try {
        Write-ColorOutput "Checking if module version exists in $Repository..." -ForegroundColor Yellow
        $existingModule = Find-Module -Name $ModuleName -RequiredVersion $Version -Repository $Repository -ErrorAction Stop

        Write-ColorOutput "Found module: $($existingModule.Name) v$($existingModule.Version)" -ForegroundColor Green
        Write-ColorOutput "  Author: $($existingModule.Author)" -ForegroundColor Cyan
        Write-ColorOutput "  Published: $($existingModule.PublishedDate)" -ForegroundColor Cyan
        Write-ColorOutput "  Description: $($existingModule.Description)" -ForegroundColor Cyan

        return $existingModule
    }
    catch {
        if ($_.Exception.Message -like "*No match was found*") {
            throw "Module '$ModuleName' version '$Version' not found in $Repository."
        }
        throw "Error checking module existence: $($_.Exception.Message)"
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

# Function to confirm unlisting
function Confirm-Unlisting {
    param(
        [string]$ModuleName,
        [string]$Version,
        [bool]$Force
    )

    if ($Force) {
        return $true
    }

    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "WARNING: You are about to unlist the following module:" -ForegroundColor Red
    Write-ColorOutput "  Module: $ModuleName" -ForegroundColor Yellow
    Write-ColorOutput "  Version: $Version" -ForegroundColor Yellow
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Unlisting will:" -ForegroundColor Yellow
    Write-ColorOutput "  - Remove the module from PowerShell Gallery search results" -ForegroundColor Cyan
    Write-ColorOutput "  - Keep the module available for direct download (existing dependencies)" -ForegroundColor Cyan
    Write-ColorOutput "  - This action cannot be easily reversed" -ForegroundColor Red
    Write-ColorOutput "" -ForegroundColor White

    $confirmation = Read-Host "Do you want to continue? (y/N)"
    return ($confirmation -eq 'y' -or $confirmation -eq 'Y' -or $confirmation -eq 'yes' -or $confirmation -eq 'Yes')
}

# Function to unlist module using REST API
function Unlist-ModuleVersion {
    param(
        [string]$ModuleName,
        [string]$Version,
        [string]$ApiKey
    )

    try {
        Write-ColorOutput "Unlisting module using PowerShell Gallery API..." -ForegroundColor Yellow

        # PowerShell Gallery API endpoint for unlisting
        $apiUrl = "https://www.powershellgallery.com/api/v2/package/$ModuleName/$Version"

        # Create headers
        $headers = @{
            'X-NuGet-ApiKey' = $ApiKey
            'Content-Type' = 'application/json'
        }

        # Make DELETE request to unlist the package
        $response = Invoke-RestMethod -Uri $apiUrl -Method Delete -Headers $headers -ErrorAction Stop

        Write-ColorOutput "Module unlisted successfully via API." -ForegroundColor Green
        return $true
    }
    catch {
        Write-ColorOutput "API unlisting failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-ColorOutput "Note: PowerShell Gallery may not support direct unlisting via API for all scenarios." -ForegroundColor Yellow
        Write-ColorOutput "You may need to use the PowerShell Gallery web interface to unlist packages." -ForegroundColor Yellow
        return $false
    }
}

# Main execution
try {
    Write-ColorOutput "Starting PowerShell Gallery module unlisting process..." -ForegroundColor Magenta
    Write-ColorOutput "Module: $ModuleName" -ForegroundColor Cyan
    Write-ColorOutput "Version: $Version" -ForegroundColor Cyan
    Write-ColorOutput "Repository: $Repository" -ForegroundColor Cyan

    # Validate version format
    if (-not (Test-VersionFormat -Version $Version)) {
        throw "Invalid version format: $Version. Please provide a valid version (e.g., '1.0.0')."
    }

    # Test prerequisites
    Test-Prerequisites

    # Check if module version exists
    $existingModule = Test-ModuleVersionExists -ModuleName $ModuleName -Version $Version -Repository $Repository

    # Get API key
    $galleryApiKey = Get-ApiKey -ApiKey $ApiKey

    # Confirm unlisting
    if (-not (Confirm-Unlisting -ModuleName $ModuleName -Version $Version -Force $Force)) {
        Write-ColorOutput "Unlisting cancelled by user." -ForegroundColor Yellow
        return
    }

    # Perform unlisting
    if ($PSCmdlet.ShouldProcess("$ModuleName v$Version", "Unlist from $Repository")) {

        # Try to unlist using API
        $apiSuccess = Unlist-ModuleVersion -ModuleName $ModuleName -Version $Version -ApiKey $galleryApiKey

        if ($apiSuccess) {
            Write-ColorOutput "Module unlisted successfully!" -ForegroundColor Green
            Write-ColorOutput "Module: $ModuleName v$Version" -ForegroundColor Green
            Write-ColorOutput "" -ForegroundColor White
            Write-ColorOutput "The module has been unlisted from PowerShell Gallery." -ForegroundColor Cyan
            Write-ColorOutput "It will no longer appear in search results but remains available for direct download." -ForegroundColor Cyan
        } else {
            Write-ColorOutput "" -ForegroundColor White
            Write-ColorOutput "Alternative unlisting methods:" -ForegroundColor Yellow
            Write-ColorOutput "1. Visit https://www.powershellgallery.com/packages/$ModuleName/$Version" -ForegroundColor Cyan
            Write-ColorOutput "2. Sign in with your account" -ForegroundColor Cyan
            Write-ColorOutput "3. Click 'Manage' and then 'Unlist'" -ForegroundColor Cyan
            Write-ColorOutput "" -ForegroundColor White
            Write-ColorOutput "Or use the PowerShell Gallery management interface if available." -ForegroundColor Cyan
        }
    }
}
catch {
    Write-ColorOutput "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-ColorOutput "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}
