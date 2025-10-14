function Convert-ParametersToInputConfig {
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject] $inputConfig,
        [Parameter(Mandatory = $false)]
        [hashtable] $parameters
    )

    foreach ($parameterKey in $parameters.Keys) {
        $parameter = $parameters[$parameterKey]

        # Create a safe copy of the parameter for logging
        $safeParameter = $parameter.PSObject.Copy()

        # Check if this parameter contains sensitive information and mask it
        $isSensitive = $false
        foreach ($sensitivePattern in @('github_token', 'githubToken', 'token', 'password', 'secret', 'key', 'credential', 'auth')) {
            if ($parameterKey -like "*$sensitivePattern*") {
                $isSensitive = $true
                break
            }
        }

        if ($isSensitive -and $null -ne $safeParameter.value -and $safeParameter.value -ne "") {
            $safeParameter.value = "***MASKED***"
        }

        Write-Verbose "Processing parameter $parameterKey $(ConvertTo-Json $safeParameter -Depth 100)"

        foreach ($parameterAlias in $parameter.aliases) {
            if ($inputConfig.PsObject.Properties.Name -contains $parameterAlias) {
                Write-Verbose "Alias $parameterAlias exists in input config, renaming..."
                $configItem = $inputConfig.PSObject.Properties | Where-Object { $_.Name -eq $parameterAlias }
                $inputConfig | Add-Member -NotePropertyName $parameterKey -NotePropertyValue @{
                    Value  = $configItem.Value.Value
                    Source = $configItem.Value.Source
                }
                $inputConfig.PSObject.Properties.Remove($configItem.Name)
                continue
            }
        }

        if ($inputConfig.PsObject.Properties.Name -notcontains $parameterKey) {
            $variableValue = [Environment]::GetEnvironmentVariable("ALZ_$($parameterKey)")
            if ($null -eq $variableValue) {
                if ($parameter.type -eq "SwitchParameter") {
                    $variableValue = $parameter.value.IsPresent
                } else {
                    $variableValue = $parameter.value
                }
            }

            if ($parameter.type -eq "SwitchParameter") {
                $variableValue = [bool]::Parse($variableValue)
            }

            # Use safe logging to prevent sensitive data exposure
            $maskedValue = $variableValue
            foreach ($sensitivePattern in @('github_token', 'githubToken', 'token', 'password', 'secret', 'key', 'credential', 'auth')) {
                if ($parameterKey -like "*$sensitivePattern*" -and $null -ne $variableValue -and $variableValue -ne "") {
                    $maskedValue = "***MASKED***"
                    break
                }
            }
            Write-Verbose "Adding parameter $parameterKey with value $maskedValue"

            $inputConfig | Add-Member -NotePropertyName $parameterKey -NotePropertyValue @{
                Value  = $variableValue
                Source = "parameter"
            }
        }
    }

    return $inputConfig
}
