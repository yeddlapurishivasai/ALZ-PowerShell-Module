# PowerShell Gallery Publishing Guide

This guide provides comprehensive instructions for publishing, updating, and managing the AMA.ALZ PowerShell module in the PowerShell Gallery using the provided scripts.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Available Scripts](#available-scripts)
- [Step-by-Step Publishing Guide](#step-by-step-publishing-guide)
- [WhatIf Testing](#whatif-testing)
- [API Key Management](#api-key-management)
- [Common Workflows](#common-workflows)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

The AMA.ALZ module includes a comprehensive set of PowerShell scripts for managing module publication to the PowerShell Gallery. These scripts provide:

- ✅ **Secure API key management**
- 🔍 **Module validation and status checking**
- 📦 **Publishing new modules**
- 🔄 **Updating existing modules**
- 🚫 **Unlisting problematic versions**
- 🎨 **Rich colored output and user experience**

## How It Works

The publishing scripts use a clean module structure approach to ensure compatibility with PowerShell Gallery:

1. **Build Process**: The `Invoke-Build` process creates module files in `src\Artifacts` including test artifacts and build outputs
2. **Clean Structure**: Publishing scripts create a temporary clean module structure containing only essential files:
   - Module manifest (`.psd1`)
   - Module script file (`.psm1`)
   - `Private\` folder with private functions
   - `Public\` folder with public functions
   - Excludes build artifacts like `ccReport\`, `testOutput\`, etc.
3. **Publishing**: `Publish-Module` uses this clean structure to publish to PowerShell Gallery
4. **Cleanup**: Temporary directory is automatically cleaned up after publishing

This approach ensures that only the necessary module files are published, avoiding issues with build artifacts that can cause PowerShell Gallery publishing failures.

## Prerequisites

### Software Requirements
1. **PowerShell 7.4+** (as specified in module manifest)
2. **PowerShellGet module**:
   ```powershell
   Install-Module PowerShellGet -Force
   ```

### PowerShell Gallery Setup
1. **PowerShell Gallery Account**: Sign up at [PowerShell Gallery](https://www.powershellgallery.com)
2. **API Key**: Generate from [API Keys Management](https://www.powershellgallery.com/account/apikeys)

### Module Build
Ensure the module is built and available in the `src/Artifacts` directory:
```powershell
# From the root directory
Invoke-Build -File .\src\AMA.ALZ.build.ps1
```

## Quick Start

```powershell
# 1. Validate your module is ready (from root directory)
.\scripts\Manage-PSGalleryModule.ps1 -Action ValidateOnly

# 2. Check if module already exists
.\scripts\Manage-PSGalleryModule.ps1 -Action Status

# 3. Test the publication safely (recommended)
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key" -WhatIf

# 4. Publish the module
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key"
```

## Available Scripts

### Core Management Scripts

| Script | Purpose | Description |
|--------|---------|-------------|
| `Manage-PSGalleryModule.ps1` | **Main Interface** | Unified script for all PowerShell Gallery operations |
| `Publish-ModuleToPSGallery.ps1` | **Initial Publishing** | Dedicated script for first-time module publication |
| `Update-ModuleInPSGallery.ps1` | **Module Updates** | Update existing module versions with validation |
| `Unlist-ModuleFromPSGallery.ps1` | **Version Management** | Remove specific versions from search results |

### Support Scripts

| Script | Purpose | Description |
|--------|---------|-------------|
| `Example-PSGalleryWorkflow.ps1` | **Demonstration** | Interactive workflow examples |

## Step-by-Step Publishing Guide

### Step 1: Prepare Your Environment

1. **Obtain PowerShell Gallery API Key**:
   - Visit [PowerShell Gallery](https://www.powershellgallery.com)
   - Sign in with your Microsoft account
   - Navigate to Account → API Keys
   - Click "Create" and configure permissions:
     - Package name pattern: `AMA.ALZ*`
     - Allow Push new packages: ✅
     - Allow Push new package versions: ✅
     - Allow Unlist packages: ✅ (optional)

2. **Keep your API key secure** - you'll pass it as a parameter to the scripts

### Step 2: Prepare Your Module

1. **Build the Module**:
   ```powershell
   # From root directory
   Invoke-Build -File .\src\AMA.ALZ.build.ps1
   ```

2. **Validate Module for Publishing**:
   ```powershell
   .\scripts\Manage-PSGalleryModule.ps1 -Action ValidateOnly
   ```

### Step 3: Check Current Status

```powershell
# Check if module exists in PowerShell Gallery
.\scripts\Manage-PSGalleryModule.ps1 -Action Status
```

### Step 4: Test with WhatIf (Recommended)

Before performing actual operations, always test with `-WhatIf` to preview what will happen:

```powershell
# Test publish operation (safe - no actual changes)
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key" -WhatIf

# Test update operation (safe - no actual changes)
.\scripts\Manage-PSGalleryModule.ps1 -Action Update -ApiKey "your-api-key" -WhatIf
```

### Step 5: Publish or Update

#### For New Module (First Publication):
```powershell
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key"
```

#### For Existing Module (Update):
```powershell
.\scripts\Manage-PSGalleryModule.ps1 -Action Update -ApiKey "your-api-key"
```

## WhatIf Testing

The `-WhatIf` parameter allows you to safely test all operations before executing them. This is **highly recommended** for all PowerShell Gallery operations to prevent accidental publications or updates.

### What WhatIf Does

- ✅ **Shows exactly what would happen** without making any changes
- ✅ **Validates all parameters and prerequisites**
- ✅ **Checks module existence and version conflicts**
- ✅ **Displays the exact PowerShell Gallery operation** that would be performed
- ✅ **Safe to run multiple times** without side effects

### WhatIf Examples

#### Testing All Operations
```powershell
# Test operations safely (from root directory)
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key" -WhatIf
.\scripts\Manage-PSGalleryModule.ps1 -Action Update -ApiKey "your-api-key" -WhatIf
.\scripts\Manage-PSGalleryModule.ps1 -Action Unlist -Version "0.1.0" -ApiKey "your-api-key" -WhatIf

# Test with individual scripts
.\scripts\Publish-ModuleToPSGallery.ps1 -ApiKey "your-api-key" -WhatIf
.\scripts\Update-ModuleInPSGallery.ps1 -ApiKey "your-api-key" -WhatIf
.\scripts\Unlist-ModuleFromPSGallery.ps1 -Version "0.1.0" -ApiKey "your-api-key" -WhatIf
```

### Interpreting WhatIf Output

When you run with `-WhatIf`, you'll see output like:

```
===============================================================
 PUBLISHING MODULE
===============================================================
Module found in PSGallery:
  Latest Version: 0.1.0
  Total Versions: 1
  Download Count: 25
What if: Performing the operation "Publish to PSGallery" on target "AMA.ALZ".
Publishing module to PSGallery...
Path: C:\Path\To\Module\AMA.ALZ.psd1
Repository: PSGallery
NuGetApiKey: [PROTECTED]
```

This tells you:
- ✅ **Current state** of the module in PowerShell Gallery
- ✅ **Exact operation** that would be performed
- ✅ **Parameters** that would be used
- ✅ **File paths** that would be processed

### Best Practice WhatIf Workflow

Always follow this pattern:

```powershell
# 1. Validate → 2. Check Status → 3. Test with WhatIf → 4. Review → 5. Execute
.\scripts\Manage-PSGalleryModule.ps1 -Action ValidateOnly
.\scripts\Manage-PSGalleryModule.ps1 -Action Status
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key" -WhatIf
# Review the WhatIf output carefully before proceeding
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key"
```

### WhatIf Limitations

**Important**: WhatIf cannot test:
- ❌ **Actual API key validity** (requires real API call)
- ❌ **Network connectivity** to PowerShell Gallery
- ❌ **PowerShell Gallery service availability**
- ❌ **Detailed permission validation**

However, it **will** validate:
- ✅ **Module structure and manifest**
- ✅ **Version formatting and conflicts**
- ✅ **File paths and accessibility**
- ✅ **Parameter validation**
- ✅ **Script logic and flow**

## API Key Management

All scripts accept API keys directly as parameters for maximum flexibility and security.

### Using API Key as Parameter (Recommended)
```powershell
# Pass API key directly to scripts (from root directory)
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key"
.\scripts\Publish-ModuleToPSGallery.ps1 -ApiKey "your-api-key"
.\scripts\Update-ModuleInPSGallery.ps1 -ApiKey "your-api-key"
.\scripts\Unlist-ModuleFromPSGallery.ps1 -Version "1.0.0" -ApiKey "your-api-key"
```

### Environment Variable Fallback (Optional)
```powershell
# Set environment variable as fallback
$env:PSGalleryApiKey = "your-api-key"

# Then run without -ApiKey parameter (from root directory)
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish
```

## Common Workflows

### Workflow 1: First-Time Publishing

```powershell
# 1. Build module (from root directory)
Invoke-Build -File .\src\AMA.ALZ.build.ps1

# 2. Validate module
.\scripts\Manage-PSGalleryModule.ps1 -Action ValidateOnly

# 3. Check gallery status
.\scripts\Manage-PSGalleryModule.ps1 -Action Status

# 4. Test publish operation (safe - no actual changes)
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key" -WhatIf

# 5. Publish module with API key (after reviewing WhatIf output)
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key"
```

### Workflow 2: Updating Existing Module

```powershell
# 1. Build updated module (from root directory)
Invoke-Build -File .\src\AMA.ALZ.build.ps1

# 2. Check current status
.\scripts\Manage-PSGalleryModule.ps1 -Action Status

# 3. Test update operation (safe - no actual changes)
.\scripts\Manage-PSGalleryModule.ps1 -Action Update -ApiKey "your-api-key" -WhatIf

# 4. Update module with API key (after reviewing WhatIf output)
.\scripts\Manage-PSGalleryModule.ps1 -Action Update -ApiKey "your-api-key"
```

### Workflow 3: Safe Testing with WhatIf

```powershell
# Test all operations safely before executing (from root directory)
.\scripts\Manage-PSGalleryModule.ps1 -Action ValidateOnly
.\scripts\Manage-PSGalleryModule.ps1 -Action Status
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key" -WhatIf
.\scripts\Manage-PSGalleryModule.ps1 -Action Update -ApiKey "your-api-key" -WhatIf
.\scripts\Manage-PSGalleryModule.ps1 -Action Unlist -Version "0.1.0" -ApiKey "your-api-key" -WhatIf
```

### Workflow 4: Emergency Unlisting

```powershell
# Test unlist operation first (from root directory)
.\scripts\Unlist-ModuleFromPSGallery.ps1 -Version "0.1.0" -ApiKey "your-api-key" -WhatIf

# Unlist a problematic version (after reviewing WhatIf output)
.\scripts\Unlist-ModuleFromPSGallery.ps1 -Version "0.1.0" -ApiKey "your-api-key"

.\scripts\Manage-PSGalleryModule.ps1 -Action Unlist -Version "0.1.0" -ApiKey "your-api-key"
```

## Troubleshooting

### Common Issues and Solutions

#### Issue: "PowerShellGet module not found"
```powershell
# Solution: Install PowerShellGet
Install-Module PowerShellGet -Force -AllowClobber
```

#### Issue: "API Key is required"
```powershell
# Solution: Pass API key as parameter (from root directory)
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key"

# Or set environment variable
$env:PSGalleryApiKey = "your-api-key"
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish
```

#### Issue: "Module manifest validation failed"
```powershell
# Solution: Check manifest file
Test-ModuleManifest .\src\AMA.ALZ\AMA.ALZ.psd1
```

#### Issue: "Version must be higher than existing version"
```powershell
# Check current version in gallery (from root directory)
.\scripts\Manage-PSGalleryModule.ps1 -Action Status

# Update version in manifest file, then rebuild
Invoke-Build -File .\src\AMA.ALZ.build.ps1
```

#### Issue: "Module path not found"
```powershell
# Solution: Build module first
Invoke-Build -File .\src\AMA.ALZ.build.ps1
```

### Debug Mode
Run scripts with `-Verbose` for detailed output:
```powershell
# From root directory
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -Verbose
```

## Best Practices

### Security
- ✅ **Never commit API keys** to source control
- ✅ **Pass API keys as parameters** for better security
- ✅ **Use environment variables as fallback** only when needed
- ✅ **Rotate API keys periodically**
- ✅ **Use principle of least privilege** for API key permissions
- ✅ **Consider separate keys** for different environments

### Version Management
- ✅ **Follow semantic versioning** (Major.Minor.Patch)
- ✅ **Update module version** before publishing
- ✅ **Test thoroughly** before publishing
- ✅ **Use preview/beta tags** for pre-release versions

### Publishing Process
- ✅ **Always validate** before publishing
- ✅ **Check status first** to understand current state
- ✅ **Use WhatIf mode** to preview changes before execution
- ✅ **Review WhatIf output carefully** before proceeding
- ✅ **Test with WhatIf** in CI/CD pipelines before actual deployment
- ✅ **Keep release notes** updated
- ✅ **Test installation** after publishing

### Automation
- ✅ **Integrate with CI/CD** pipelines
- ✅ **Use build tasks** for consistency
- ✅ **Automate validation** checks
- ✅ **Set up monitoring** for published modules

## Command Reference

### Quick Commands

```powershell
# All commands from root directory

# Safe operations (no API key needed)
.\scripts\Manage-PSGalleryModule.ps1 -Action Status
.\scripts\Manage-PSGalleryModule.ps1 -Action ValidateOnly

# Test operations with WhatIf (safe - preview only)
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key" -WhatIf
.\scripts\Manage-PSGalleryModule.ps1 -Action Update -ApiKey "your-api-key" -WhatIf
.\scripts\Manage-PSGalleryModule.ps1 -Action Unlist -Version "1.0.0" -ApiKey "your-api-key" -WhatIf

# Actual operations (after reviewing WhatIf output)
.\scripts\Manage-PSGalleryModule.ps1 -Action Publish -ApiKey "your-api-key"
.\scripts\Manage-PSGalleryModule.ps1 -Action Update -ApiKey "your-api-key"
.\scripts\Manage-PSGalleryModule.ps1 -Action Unlist -Version "1.0.0" -ApiKey "your-api-key"

# Individual scripts with WhatIf testing
.\scripts\Publish-ModuleToPSGallery.ps1 -ApiKey "your-api-key" -WhatIf
.\scripts\Update-ModuleInPSGallery.ps1 -ApiKey "your-api-key" -WhatIf
.\scripts\Unlist-ModuleFromPSGallery.ps1 -Version "1.0.0" -ApiKey "your-api-key" -WhatIf

# Individual scripts for actual operations
.\scripts\Publish-ModuleToPSGallery.ps1 -ApiKey "your-api-key" [-DryRun]
.\scripts\Update-ModuleInPSGallery.ps1 -ApiKey "your-api-key" [-Force] [-SkipVersionCheck]
.\scripts\Unlist-ModuleFromPSGallery.ps1 -Version "1.0.0" -ApiKey "your-api-key" [-Force]
```

## Getting Help

### Script Help
```powershell
# From root directory
Get-Help .\scripts\Manage-PSGalleryModule.ps1 -Detailed
Get-Help .\scripts\Manage-PSGalleryModule.ps1 -Examples
```

### Interactive Examples
```powershell
# From root directory
.\scripts\Example-PSGalleryWorkflow.ps1 -Action FullWorkflow
```

### Additional Resources
- [PowerShell Gallery Documentation](https://docs.microsoft.com/en-us/powershell/scripting/gallery/overview)
- [PowerShellGet Documentation](https://docs.microsoft.com/en-us/powershell/module/powershellget/)
- [Module Publishing Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/gallery/concepts/publishing-guidelines)

---

**Last Updated**: August 11, 2025
**Module**: AMA.ALZ
**Version**: Compatible with all module versions
