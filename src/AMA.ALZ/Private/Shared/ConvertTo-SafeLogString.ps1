function ConvertTo-SafeLogString {
    <#
    .SYNOPSIS
    Converts an object to a safe JSON string for logging by masking sensitive properties.
    
    .DESCRIPTION
    A lightweight function that masks sensitive properties in objects before converting to JSON for logging.
    Much simpler and more performant than the previous ConvertTo-SafeJson function.
    
    .PARAMETER InputObject
    The object to convert to a safe JSON string.
    
    .PARAMETER SensitiveProperties
    Array of property name patterns that should be masked.
    
    .EXAMPLE
    ConvertTo-SafeLogString $inputConfig
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object] $InputObject,
        
        [Parameter(Mandatory = $false)]
        [string[]] $SensitiveProperties = @('github_token', 'githubToken', 'token', 'password', 'secret', 'key', 'credential', 'auth')
    )
    
    if ($null -eq $InputObject) {
        return "null"
    }
    
    try {
        # Convert to JSON first to get a deep copy, then back to object
        $jsonString = $InputObject | ConvertTo-Json -Depth 100 -ErrorAction Stop
        $safeCopy = $jsonString | ConvertFrom-Json -ErrorAction Stop
        
        # Simple recursive function to mask sensitive properties
        function Hide-SensitiveData {
            param($obj)
            
            if ($null -eq $obj -or $obj -is [string] -or $obj -is [int] -or $obj -is [bool]) {
                return
            }
            
            if ($obj -is [PSCustomObject]) {
                $obj.PSObject.Properties | ForEach-Object {
                    $propName = $_.Name
                    $propValue = $_.Value
                    
                    # Check if property name matches sensitive patterns
                    $isSensitive = $SensitiveProperties | Where-Object { $propName -like "*$_*" }
                    
                    if ($isSensitive -and $null -ne $propValue -and $propValue -ne "") {
                        if ($propValue -is [PSCustomObject] -and $propValue.PSObject.Properties['Value']) {
                            # Handle inputConfig structure with Value property
                            if ($null -ne $propValue.Value -and $propValue.Value -ne "") {
                                $propValue.Value = "***MASKED***"
                            }
                        } else {
                            # Direct property assignment
                            $obj.$propName = "***MASKED***"
                        }
                    } else {
                        # Recursively process nested objects
                        Hide-SensitiveData $propValue
                    }
                }
            }
        }
        
        Hide-SensitiveData $safeCopy
        return ($safeCopy | ConvertTo-Json -Depth 100)
        
    } catch {
        return "Unable to convert object to safe JSON: $($_.Exception.Message)"
    }
}