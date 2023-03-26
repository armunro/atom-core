function New-AtomPackage {
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


function Install-AtomPackage {
    Param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    PROCESS {
        
        
        Write-Host $InputObject.Name $InputObject.Provider

        Invoke-AtomExtensionModule `
            -Type "Packages.Providers" -Name $InputObject.Provider `
            -FunctionName "Install-AtomPackageExt" `
            -FunctionArgs @{ PackageName = $InputObject.Name }
    }
}

function Get-AtomPersonaPackages
{
    $persona = Get-AtomCurrentPersona
    foreach ($provider in $persona.Zones.packages ) {
        foreach($package in $provider.packages)
        {
            New-AtomPackage -Name $package -Provider $provider.provider 
        }
    }
}