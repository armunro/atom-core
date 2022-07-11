function Import-CasaPersona {
    [CmdletBinding()]
    param(
        $File
    )
    
    $config = (Get-Content $File | ConvertFrom-Yaml)
    return [PSCustomObject]@{
        # Core details
        Name            = $config.name
        Source          = (Get-Item $File).FullName
        Paths           = @{
            Base       = $PSScriptRoot
            Frameworks = [System.IO.Path]::Combine($PSScriptRoot, "Frameworks")
            Adapters   = [System.IO.Path]::Combine($PSScriptRoot, "Adapters")
        }
        # Low-level stuff
        State           = @{ 
            Params       = @{ }
            InvokeParams = @{ }
        }
        Adapters      = @{}
        #User space
        Zones           = $config.zones
        Description     = $config.description
        StartupCommands = $config.startupCommands
    }
}

function Start-Casa {
    [Alias("casatart")]
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Persona,
        [Switch]
        $NoStartupCommands
    )
    
    $Global:CasaPersona = $Persona

    Write-CasaBanner -Verb "Framework" -Type "Disovery"
    Import-CasaFramework -Persona $Persona
    
    Write-CasaBanner -Verb "Adapter" -Type "Param.Scopes" -Icon "ﮣ"
    Register-CasaAdapters -Persona $Persona -Name Params.Scopes
    
    Write-CasaBanner -Verb "Adapter" -Type "Packages.Providers" -Icon "ﮣ"
    Register-CasaAdapters -Persona $Persona -Name Packages.Providers 

    Write-CasaBanner -Type "Zones" -Depth 0
    $Persona | Import-CasaPersonaModules
    
    if (-not $NoStartupCommands) {
        #Write-CasaStageHeader -Message "Run Persona Startup Commands"
        $Persona | Invoke-CasaStartupCommands
    }
    
}

function Get-CasaCurrentPersona {
    [Alias("persona")]
    Param()
    $Global:CasaPersona
}


function Import-CasaFramework {
    Param(
        $Persona
    )

    Get-ChildItem $Persona.Paths.Frameworks | ForEach-Object {
        Write-CasaListItem -File $_
        New-Module -ScriptBlock ([scriptblock]::Create((Get-Content $_ -Raw))) -Name "CasaPS.Frameworks.$([System.IO.Path]::GetFileNameWithoutExtension($_.Name))" | Import-Module -Scope Global -Force
     }
}

function Register-CasaAdapters {
    Param (
        [Parameter(ValueFromPipeline = $true)]
        $Persona,
        $Name
    )
    $path = [System.IO.Path]::Combine($Persona.Paths.Adapters, $Name )
    $adapterFiles = Get-ChildItem -File -Path $path -Recurse
    $adapterFiles | ForEach-Object {
        $environment = Get-CasaCurrentPersona
        if (-not $environment.Adapters.ContainsKey($Name)) {
            $environment.Adapters.Add($Name, @{})
        }
        $adapterName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)  
        $environment.Adapters[$Name][$adapterName] = $_.FullName
        Write-CasaListItem -File $_  -Icon 'ﮣ'
    }
}

function Get-CasaAdapterPath {
    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $Type,
        [string]
        [Parameter(Mandatory = $true)]
        $Name
    )
    $extensionPath = Invoke-Expression "(Get-CasaCurrentPersona).Adapters['$Type']['$Name']"
    if (-not $extensionPath) {
        throw "An adapter with the type '$Type' could not be resolved with name '$Name'"
    }
    return $extensionPath
}


function Invoke-CasaExtensionModule {
    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $Type,
        [Parameter(Mandatory = $true)]
        [string]
        $Name,
        [String]
        [Parameter(Mandatory = $true)]
        $FunctionName,
        [Hashtable] $FunctionArgs
    )

    $extensionModulePath = Get-CasaAdapterPath -Type $Type -Name $Name
    $module = Import-Module $extensionModulePath -Scope Local -PassThru -Force
    $command = $module.ExportedCommands[$FunctionName].ScriptBlock

    return & $command @FunctionArgs

}
function Update-CasaPersona {
    [Alias("casaupdate")]
    Param(
        [Switch]
        $StartupCommands
    )
    $starterPath = Join-Path -Path $PSScriptRoot -ChildPath "CasaPS.ps1"
    & $starterPath -PersonaFile (Get-CasaCurrentPersona).Source -NoStartupCommands:(-not $StartupCommands)
}


function Invoke-CasaStartupCommands {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $Persona
    )

    $Persona.StartupCommands | ForEach-Object {
        
        Write-Host -ForegroundColor DarkBlue "Startup $($_.name) "
        $shouldInvoke = $true


        if ($_.prompt) {
            $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Run $($_.name)."
            $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Skip it this time."
            $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
            
            ## Use the following each time your want to prompt the use
            $title = "Startup command '$($_.name)' is configured to prompt before running."
            $message = "Do you want to run '$($_.name)'?"
            $result = $host.ui.PromptForChoice($title, $message, $options, 1)
            
            if ($result -eq 1) {
                $shouldInvoke = $false
            }
        }

        if ($shouldInvoke) {
            & "$($_.command)"
        }
    }
}

function Install-CasaPersonaPackages {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Persona,
        $Provider
    )
    foreach ($pack in $Persona.Zones.packages ) {

        if (($null -eq $Provider) -or ($Provider -and ($pack.provider -eq $Provider))) {
            New-CasaPackage -Name $pack.package -Provider $pack.provider | Install-CasaPackage
        }
    }    
}

function Write-CasaBanner {
    Param(
        $Type,
        $Depth = 0,
        $Verb = "Discovering",
        $Icon = '',
        $PrimaryColor = [ConsoleColor]::DarkBlue,
        $SecondaryColor = [ConsoleColor]::Blue,
        $ForegroundColor = [ConsoleColor]::White
    )
    $padding = (" " * $Depth)
    $bgList = @(
        $PrimaryColor
        $PrimaryColor
        $PrimaryColor
        $PrimaryColor
        $SecondaryColor
        $SecondaryColor
        $SecondaryColor
        [System.ConsoleColor]::Black
    )
    $fgList = @(
        $PrimaryColor
        $ForegroundColor
        $ForegroundColor
        $ForegroundColor
        $PrimaryColor
        $ForegroundColor
        $ForegroundColor
        $SecondaryColor
    )
    $chars = $("$padding", ' ', "$Icon ", "$Verb", '', " $Type" , ' ', "")
    Write-Color -Text $chars -BackGroundColor $bgList -Color $fgList
}

function Write-CasaListItem {
    Param(
        $File,
        $Text,
        [switch]
        $ShowExtension,
        $Depth = 0,
        $Icon = '',
        [Switch]
        $NoNewLine,
        [ConsoleColor]
        $IconColor = [System.ConsoleColor]::Blue,
        $Kind = ""
    )
    $padding = (" " * $Depth)
    $finalItemText = ""
    $chars = $("$padding", ' ', "$Icon ", "$Verb", '', " $Type" , ' ', "")
    Write-Host  "$padding  $Icon " -ForegroundColor $IconColor -NoNewline

    if ($Text) {
        $finalItemText = $Text
    }
    else {
        $finalItemText = if ($ShowExtension) { $_.Name } else {
            [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        }
    }
    Write-Host $finalItemText -NoNewline:$NoNewLine
}

function Import-CasaPersonaModules {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Persona
    )
    PROCESS {
        $Persona.Zones | ForEach-Object {
            $zone = $_
            Write-CasaBanner -Type "$($zone.name.ToString().ToUpper())" -Depth 1 -Verb "Import Zone" -Icon ''
            $moduleFiles = Get-ChildItem $_.path -Recurse -Include "*.psm1"
            $moduleFiles | ForEach-Object {
                $zoneModule = Import-Module $_ -Scope Global -Force -PassThru
                $aliases = $zoneModule.ExportedAliases.Keys -join " ﴞ "
                Write-CasaListItem -File $_.FullName -Depth 1 -Icon 'ﰩ' 
                if ($aliases) {
                  
                    Write-CasaListItem -Text $aliases -Depth 2 -Icon 'ﴞ'                     
                }
            }
        }
    }
}