function New-CasaPackage {
    Param(
        [string]
        [Parameter(Mandatory = $true)]
        $Name,
        [string]
        [Parameter(Mandatory = $true)]
        $Provider
    )

    return [PSCustomObject]@{
        Name     = $Name
        Provider = $Provider
    }
}


function Install-CasaPackage {
    Param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    PROCESS {
        Write-Host $InputObject.Name $InputObject.Provider

        Invoke-CasaExtensionModule `
            -Type "Packages.Providers" -Name $InputObject.Provider `
            -FunctionName "Install-CasaPackageExt" `
            -FunctionArgs @{ PackageName = $InputObject.Name }
    }
}
