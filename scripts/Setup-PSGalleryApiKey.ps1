<#
.SYNOPSIS
    Sets up PowerShell Gallery API key configuration for the AMA.ALZ module.

.DESCRIPTION
    This script helps configure the PowerShell Gallery API key for publishing operations.
    It can set the key as an environment variable or validate an existing configuration.

.PARAMETER ApiKey
    The PowerShell Gallery API key to configure.

.PARAMETER Scope
    The scope for setting the environment variable. Valid values: 'User', 'Machine', 'Process'. Defaults to 'User'.

.PARAMETER Validate
    Validates the current API key configuration without setting a new one.

.PARAMETER ShowInstructions
    Shows detailed instructions for obtaining and using PowerShell Gallery API keys.

.PARAMETER Remove
    Removes the currently configured API key.

.EXAMPLE
    .\Setup-PSGalleryApiKey.ps1 -ApiKey "your-api-key-here"

    Sets the API key as a user environment variable.

.EXAMPLE
    .\Setup-PSGalleryApiKey.ps1 -Validate

    Validates the current API key configuration.

.EXAMPLE
    .\Setup-PSGalleryApiKey.ps1 -ShowInstructions

    Shows instructions for obtaining and using API keys.

.EXAMPLE
    .\Setup-PSGalleryApiKey.ps1 -Remove

    Removes the currently configured API key.

.NOTES
    - API keys can be obtained from https://www.powershellgallery.com/account/apikeys
    - Requires appropriate permissions for the AMA.ALZ module
    - Environment variables set with 'User' scope persist across sessions
#>

[CmdletBinding(DefaultParameterSetName = 'SetKey')]
param(
    [Parameter(ParameterSetName = 'SetKey', Mandatory = $true)]
    [string]$ApiKey,

    [Parameter(ParameterSetName = 'SetKey')]
    [ValidateSet('User', 'Machine', 'Process')]
    [string]$Scope = 'User',

    [Parameter(ParameterSetName = 'Validate')]
    [switch]$Validate,

    [Parameter(ParameterSetName = 'Instructions')]
    [switch]$ShowInstructions,

    [Parameter(ParameterSetName = 'Remove')]
    [switch]$Remove
)

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

# Function to show instructions
function Show-Instructions {
    Write-SectionHeader "POWERSHELL GALLERY API KEY SETUP INSTRUCTIONS"

    Write-ColorOutput "To obtain a PowerShell Gallery API key:" -ForegroundColor Yellow
    Write-ColorOutput ""
    Write-ColorOutput "1. Visit: https://www.powershellgallery.com" -ForegroundColor Cyan
    Write-ColorOutput "2. Sign in with your Microsoft account" -ForegroundColor Cyan
    Write-ColorOutput "3. Go to your account page" -ForegroundColor Cyan
    Write-ColorOutput "4. Click 'API Keys' in the menu" -ForegroundColor Cyan
    Write-ColorOutput "5. Click 'Create' to generate a new API key" -ForegroundColor Cyan
    Write-ColorOutput "6. Configure the key with appropriate permissions:" -ForegroundColor Cyan
    Write-ColorOutput "   - Package name pattern: AMA.ALZ*" -ForegroundColor White
    Write-ColorOutput "   - Allow Push new packages and package versions: Yes" -ForegroundColor White
    Write-ColorOutput "   - Allow Push only new package versions: Yes" -ForegroundColor White
    Write-ColorOutput "   - Allow Unlist packages: Yes (if needed)" -ForegroundColor White
    Write-ColorOutput "7. Copy the generated API key" -ForegroundColor Cyan
    Write-ColorOutput ""
    Write-ColorOutput "Usage examples:" -ForegroundColor Yellow
    Write-ColorOutput ""
    Write-ColorOutput "  # Set API key (recommended method)" -ForegroundColor Green
    Write-ColorOutput "  .\Setup-PSGalleryApiKey.ps1 -ApiKey 'your-api-key-here'" -ForegroundColor White
    Write-ColorOutput ""
    Write-ColorOutput "  # Validate current configuration" -ForegroundColor Green
    Write-ColorOutput "  .\Setup-PSGalleryApiKey.ps1 -Validate" -ForegroundColor White
    Write-ColorOutput ""
    Write-ColorOutput "  # Use in publishing scripts" -ForegroundColor Green
    Write-ColorOutput "  .\Publish-ModuleToPSGallery.ps1  # Uses environment variable" -ForegroundColor White
    Write-ColorOutput "  .\Update-ModuleInPSGallery.ps1   # Uses environment variable" -ForegroundColor White
    Write-ColorOutput ""
    Write-ColorOutput "Security Notes:" -ForegroundColor Red
    Write-ColorOutput "- Keep your API key secure and never commit it to source control" -ForegroundColor Yellow
    Write-ColorOutput "- Use environment variables instead of hardcoding keys in scripts" -ForegroundColor Yellow
    Write-ColorOutput "- Consider using different keys for different environments" -ForegroundColor Yellow
    Write-ColorOutput "- Rotate your API keys periodically" -ForegroundColor Yellow
}

# Function to validate API key configuration
function Test-ApiKeyConfiguration {
    Write-SectionHeader "VALIDATING API KEY CONFIGURATION"

    $apiKey = $env:PSGalleryApiKey

    if ([string]::IsNullOrEmpty($apiKey)) {
        Write-ColorOutput "❌ No API key found in PSGalleryApiKey environment variable." -ForegroundColor Red
        Write-ColorOutput ""
        Write-ColorOutput "To set an API key, use:" -ForegroundColor Yellow
        Write-ColorOutput "  .\Setup-PSGalleryApiKey.ps1 -ApiKey 'your-api-key-here'" -ForegroundColor Cyan
        return $false
    }

    # Basic validation of API key format
    if ($apiKey.Length -lt 30) {
        Write-ColorOutput "⚠️  API key seems too short. PowerShell Gallery API keys are typically longer." -ForegroundColor Yellow
    }

    # Check if it looks like a GUID or typical API key format
    if ($apiKey -match '^[0-9a-fA-F-]{36}$') {
        Write-ColorOutput "✅ API key format appears valid (GUID format)." -ForegroundColor Green
    } elseif ($apiKey -match '^[a-zA-Z0-9+/]+=*$') {
        Write-ColorOutput "✅ API key format appears valid (Base64 format)." -ForegroundColor Green
    } else {
        Write-ColorOutput "⚠️  API key format is unusual. Verify it's correct." -ForegroundColor Yellow
    }

    Write-ColorOutput ""
    Write-ColorOutput "Configuration Details:" -ForegroundColor Cyan
    Write-ColorOutput "  Environment Variable: PSGalleryApiKey" -ForegroundColor White
    Write-ColorOutput "  Key Length: $($apiKey.Length) characters" -ForegroundColor White
    Write-ColorOutput "  Key Preview: $($apiKey.Substring(0, [Math]::Min(10, $apiKey.Length)))..." -ForegroundColor White

    Write-ColorOutput ""
    Write-ColorOutput "To test the API key functionality, try:" -ForegroundColor Yellow
    Write-ColorOutput "  .\Manage-PSGalleryModule.ps1 -Action Status" -ForegroundColor Cyan

    return $true
}

# Function to set API key
function Set-ApiKey {
    param(
        [string]$ApiKey,
        [string]$Scope
    )

    Write-SectionHeader "SETTING POWERSHELL GALLERY API KEY"

    if ([string]::IsNullOrEmpty($ApiKey)) {
        throw "API key cannot be empty."
    }

    try {
        # Set environment variable
        [Environment]::SetEnvironmentVariable('PSGalleryApiKey', $ApiKey, $Scope)

        # Also set for current session
        $env:PSGalleryApiKey = $ApiKey

        Write-ColorOutput "✅ API key set successfully!" -ForegroundColor Green
        Write-ColorOutput "  Scope: $Scope" -ForegroundColor Cyan
        Write-ColorOutput "  Environment Variable: PSGalleryApiKey" -ForegroundColor Cyan

        if ($Scope -eq 'User') {
            Write-ColorOutput "  The key will persist across PowerShell sessions." -ForegroundColor Yellow
        } elseif ($Scope -eq 'Process') {
            Write-ColorOutput "  The key is only available in this PowerShell session." -ForegroundColor Yellow
        } elseif ($Scope -eq 'Machine') {
            Write-ColorOutput "  The key is available to all users on this machine." -ForegroundColor Yellow
        }

        Write-ColorOutput ""
        Write-ColorOutput "You can now use the publishing scripts without specifying the API key:" -ForegroundColor Green
        Write-ColorOutput "  .\Publish-ModuleToPSGallery.ps1" -ForegroundColor Cyan
        Write-ColorOutput "  .\Update-ModuleInPSGallery.ps1" -ForegroundColor Cyan
        Write-ColorOutput "  .\Manage-PSGalleryModule.ps1 -Action Publish" -ForegroundColor Cyan
    }
    catch {
        Write-ColorOutput "❌ Failed to set API key: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Function to remove API key
function Remove-ApiKey {
    Write-SectionHeader "REMOVING POWERSHELL GALLERY API KEY"

    $currentKey = $env:PSGalleryApiKey

    if ([string]::IsNullOrEmpty($currentKey)) {
        Write-ColorOutput "No API key currently configured." -ForegroundColor Yellow
        return
    }

    # Confirm removal
    Write-ColorOutput "Current API key preview: $($currentKey.Substring(0, [Math]::Min(10, $currentKey.Length)))..." -ForegroundColor Cyan
    $confirmation = Read-Host "Are you sure you want to remove the API key? (y/N)"

    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-ColorOutput "Operation cancelled." -ForegroundColor Yellow
        return
    }

    try {
        # Remove from all scopes
        [Environment]::SetEnvironmentVariable('PSGalleryApiKey', $null, 'User')
        [Environment]::SetEnvironmentVariable('PSGalleryApiKey', $null, 'Process')

        # Try to remove from machine scope (may require elevation)
        try {
            [Environment]::SetEnvironmentVariable('PSGalleryApiKey', $null, 'Machine')
        }
        catch {
            Write-ColorOutput "Could not remove from Machine scope (may require administrator privileges)." -ForegroundColor Yellow
        }

        # Remove from current session
        Remove-Item Env:PSGalleryApiKey -ErrorAction SilentlyContinue

        Write-ColorOutput "✅ API key removed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "❌ Failed to remove API key: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Main execution
try {
    switch ($PSCmdlet.ParameterSetName) {
        'SetKey' {
            Set-ApiKey -ApiKey $ApiKey -Scope $Scope
        }
        'Validate' {
            Test-ApiKeyConfiguration | Out-Null
        }
        'Instructions' {
            Show-Instructions
        }
        'Remove' {
            Remove-ApiKey
        }
    }

    Write-ColorOutput ""
    Write-ColorOutput "For more help with PowerShell Gallery operations, use:" -ForegroundColor Green
    Write-ColorOutput "  Get-Help .\Manage-PSGalleryModule.ps1 -Detailed" -ForegroundColor Cyan
}
catch {
    Write-ColorOutput ""
    Write-ColorOutput "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
