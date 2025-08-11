<#
.SYNOPSIS
    Example workflow for publishing AMA.ALZ module to PowerShell Gallery.

.DESCRIPTION
    This script demonstrates a complete workflow for publishing the AMA.ALZ module
    to PowerShell Gallery, including validation, status checks, and publishing.

.PARAMETER ApiKey
    PowerShell Gallery API key. If not provided, will use PSGalleryApiKey environment variable.

.PARAMETER Action
    The action to demonstrate. Valid values: 'FirstTimeSetup', 'Publish', 'Update', 'FullWorkflow'.
    Defaults to 'FullWorkflow'.

.EXAMPLE
    .\Example-PSGalleryWorkflow.ps1 -Action FirstTimeSetup

    Demonstrates first-time setup including API key configuration.

.EXAMPLE
    .\Example-PSGalleryWorkflow.ps1 -Action Publish -ApiKey "your-api-key"

    Demonstrates publishing workflow.

.EXAMPLE
    .\Example-PSGalleryWorkflow.ps1 -Action FullWorkflow

    Demonstrates complete workflow from validation to publishing.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ApiKey,

    [Parameter()]
    [ValidateSet('FirstTimeSetup', 'Publish', 'Update', 'FullWorkflow')]
    [string]$Action = 'FullWorkflow'
)

# Get script directory
$scriptDir = $PSScriptRoot
$managementScript = Join-Path -Path $scriptDir -ChildPath 'Manage-PSGalleryModule.ps1'
$setupScript = Join-Path -Path $scriptDir -ChildPath 'Setup-PSGalleryApiKey.ps1'

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$ForegroundColor = 'White'
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Function to write workflow step
function Write-WorkflowStep {
    param(
        [int]$Step,
        [string]$Title,
        [string]$Description
    )

    Write-Host ""
    Write-Host "STEP $Step: $Title" -ForegroundColor Magenta
    Write-Host ("-" * 50) -ForegroundColor Gray
    Write-Host $Description -ForegroundColor Cyan
    Write-Host ""
}

# Function to pause for user input
function Wait-ForUser {
    param([string]$Message = "Press Enter to continue...")

    Write-Host $Message -ForegroundColor Yellow
    Read-Host | Out-Null
}

# First Time Setup Workflow
function Show-FirstTimeSetup {
    Write-Host "FIRST-TIME SETUP WORKFLOW" -ForegroundColor Green
    Write-Host ("=" * 40) -ForegroundColor Green

    Write-WorkflowStep 1 "API Key Setup" "Configure your PowerShell Gallery API key securely"

    if ([string]::IsNullOrEmpty($ApiKey)) {
        Write-ColorOutput "This would show instructions for obtaining an API key:" -ForegroundColor Yellow
        & $setupScript -ShowInstructions

        Write-ColorOutput "To actually set an API key, you would run:" -ForegroundColor Yellow
        Write-ColorOutput "  .\Setup-PSGalleryApiKey.ps1 -ApiKey 'your-actual-api-key'" -ForegroundColor Cyan
    } else {
        Write-ColorOutput "Setting up API key..." -ForegroundColor Yellow
        & $setupScript -ApiKey $ApiKey
    }

    Wait-ForUser

    Write-WorkflowStep 2 "Validate Configuration" "Check that everything is set up correctly"
    & $setupScript -Validate

    Wait-ForUser

    Write-WorkflowStep 3 "Module Validation" "Ensure module is ready for publishing"
    & $managementScript -Action ValidateOnly

    Write-ColorOutput ""
    Write-ColorOutput "✅ First-time setup complete!" -ForegroundColor Green
    Write-ColorOutput "You can now publish your module using:" -ForegroundColor Yellow
    Write-ColorOutput "  .\Manage-PSGalleryModule.ps1 -Action Publish" -ForegroundColor Cyan
}

# Publish Workflow
function Show-PublishWorkflow {
    Write-Host "PUBLISHING WORKFLOW" -ForegroundColor Green
    Write-Host ("=" * 30) -ForegroundColor Green

    Write-WorkflowStep 1 "Pre-Publishing Validation" "Validate module before publishing"
    & $managementScript -Action ValidateOnly

    Wait-ForUser

    Write-WorkflowStep 2 "Check Current Status" "See if module already exists in gallery"
    & $managementScript -Action Status

    Wait-ForUser

    Write-WorkflowStep 3 "Publish Module" "Publish to PowerShell Gallery"

    $publishParams = @{
        Action = 'Publish'
    }

    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $publishParams.ApiKey = $ApiKey
    }

    Write-ColorOutput "Publishing with WhatIf first to show what would happen..." -ForegroundColor Yellow
    & $managementScript @publishParams -WhatIf

    $confirmation = Read-Host "Do you want to proceed with actual publishing? (y/N)"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        & $managementScript @publishParams

        Write-ColorOutput ""
        Write-ColorOutput "✅ Publishing workflow complete!" -ForegroundColor Green
    } else {
        Write-ColorOutput "Publishing cancelled." -ForegroundColor Yellow
    }
}

# Update Workflow
function Show-UpdateWorkflow {
    Write-Host "UPDATE WORKFLOW" -ForegroundColor Green
    Write-Host ("=" * 25) -ForegroundColor Green

    Write-WorkflowStep 1 "Version Check" "Check current and new version"
    & $managementScript -Action Status

    Wait-ForUser

    Write-WorkflowStep 2 "Validate Updated Module" "Ensure updated module is valid"
    & $managementScript -Action ValidateOnly

    Wait-ForUser

    Write-WorkflowStep 3 "Update Module" "Update existing module in gallery"

    $updateParams = @{
        Action = 'Update'
    }

    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $updateParams.ApiKey = $ApiKey
    }

    Write-ColorOutput "Updating with WhatIf first to show what would happen..." -ForegroundColor Yellow
    & $managementScript @updateParams -WhatIf

    $confirmation = Read-Host "Do you want to proceed with actual update? (y/N)"
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        & $managementScript @updateParams

        Write-ColorOutput ""
        Write-ColorOutput "✅ Update workflow complete!" -ForegroundColor Green
    } else {
        Write-ColorOutput "Update cancelled." -ForegroundColor Yellow
    }
}

# Full Workflow
function Show-FullWorkflow {
    Write-Host "COMPLETE POWERSHELL GALLERY WORKFLOW" -ForegroundColor Green
    Write-Host ("=" * 50) -ForegroundColor Green

    Write-WorkflowStep 1 "Environment Check" "Verify prerequisites and configuration"

    # Check if API key is configured
    $hasApiKey = -not [string]::IsNullOrEmpty($env:PSGalleryApiKey) -or -not [string]::IsNullOrEmpty($ApiKey)

    if ($hasApiKey) {
        Write-ColorOutput "✅ API key is available" -ForegroundColor Green
        & $setupScript -Validate
    } else {
        Write-ColorOutput "⚠️  No API key configured" -ForegroundColor Yellow
        Write-ColorOutput "For actual publishing, you would need to set up an API key:" -ForegroundColor Cyan
        Write-ColorOutput "  .\Setup-PSGalleryApiKey.ps1 -ApiKey 'your-api-key'" -ForegroundColor White
    }

    Wait-ForUser

    Write-WorkflowStep 2 "Module Validation" "Ensure module meets PowerShell Gallery requirements"
    & $managementScript -Action ValidateOnly

    Wait-ForUser

    Write-WorkflowStep 3 "Gallery Status Check" "Check current status in PowerShell Gallery"
    & $managementScript -Action Status

    Wait-ForUser

    Write-WorkflowStep 4 "Publishing Decision" "Determine whether to publish or update"

    Write-ColorOutput "Based on the status check above, you would choose to either:" -ForegroundColor Yellow
    Write-ColorOutput "  - Publish (if module doesn't exist)" -ForegroundColor Cyan
    Write-ColorOutput "  - Update (if module exists with older version)" -ForegroundColor Cyan
    Write-ColorOutput "  - Skip (if current version already exists)" -ForegroundColor Cyan

    if ($hasApiKey) {
        $action = Read-Host "Which action would you like to demonstrate? (publish/update/skip)"

        switch ($action.ToLower()) {
            'publish' {
                Write-ColorOutput "Demonstrating publish action with WhatIf..." -ForegroundColor Yellow
                & $managementScript -Action Publish -WhatIf
            }
            'update' {
                Write-ColorOutput "Demonstrating update action with WhatIf..." -ForegroundColor Yellow
                & $managementScript -Action Update -WhatIf
            }
            'skip' {
                Write-ColorOutput "Skipping publishing/update as requested." -ForegroundColor Yellow
            }
            default {
                Write-ColorOutput "Invalid choice. Skipping publishing demonstration." -ForegroundColor Yellow
            }
        }
    } else {
        Write-ColorOutput "Skipping actual publishing demonstration due to missing API key." -ForegroundColor Yellow
    }

    Write-ColorOutput ""
    Write-ColorOutput "✅ Full workflow demonstration complete!" -ForegroundColor Green
    Write-ColorOutput ""
    Write-ColorOutput "Summary of available commands:" -ForegroundColor Yellow
    Write-ColorOutput "  .\Setup-PSGalleryApiKey.ps1 -ApiKey 'key'      # Setup API key" -ForegroundColor Cyan
    Write-ColorOutput "  .\Manage-PSGalleryModule.ps1 -Action Status    # Check status" -ForegroundColor Cyan
    Write-ColorOutput "  .\Manage-PSGalleryModule.ps1 -Action Publish   # Publish module" -ForegroundColor Cyan
    Write-ColorOutput "  .\Manage-PSGalleryModule.ps1 -Action Update    # Update module" -ForegroundColor Cyan
}

# Main execution
try {
    Write-Host "PowerShell Gallery Workflow Examples" -ForegroundColor Magenta
    Write-Host ("=" * 60) -ForegroundColor Magenta
    Write-Host ""

    switch ($Action) {
        'FirstTimeSetup' { Show-FirstTimeSetup }
        'Publish' { Show-PublishWorkflow }
        'Update' { Show-UpdateWorkflow }
        'FullWorkflow' { Show-FullWorkflow }
    }

}
catch {
    Write-ColorOutput "Error in workflow: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
