function New-AtomCommandProxy{
    Param(
        [Parameter(mandatory = $true, ValueFromPipeline = $true)]
        $Command,
        $Scope = "global",
        $Prefix = "",
        $Suffix = "-Proxy"
    )

    PROCESS{
        $metadata = New-Object System.Management.Automation.CommandMetaData $Command

        $metadata.Parameters.Keys | ForEach-Object {
            $param = $metadata.Parameters[$_]
            $param.Attributes | ForEach-Object {
                if( $_.PSObject.Properties | Where-Object {$_.Name -eq "Mandatory"})
                {
                    $_.Mandatory = $false
                }
                
            }
            
        }
        
        $proxyParamBlock = [System.Management.Automation.ProxyCommand]::GetParamBlock($metadata)
        $final =
@"
        Param(
            $proxyParamBlock
        )
        Invoke-AtomCommand -Command (Get-Command $($Command.Name) )
"@
   


        $final | Out-File proxy.ps1
        $null = New-Item -Path function: -Name "$($Scope):$($prefix)$($Command.Name)$Suffix" -Value $final
        
    }
}