function Import-AtomPersona {
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
            Zones      = [System.IO.Path]::Combine($PSScriptRoot, "Zones")
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

function Start-Atom {
    [Alias("atomstart")]
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Persona,
        [Switch]
        $NoStartupCommands
    )
    
    $Global:AtomPersona = $Persona

    Write-AtomBanner -Verb "Framework" -Type "Disovery"
    Import-AtomFramework -Persona $Persona
    
    Write-AtomBanner -Verb "Adapter" -Type "Param.Scopes" -Icon "ﮣ"
    Register-AtomAdapters -Persona $Persona -Name Params.Scopes
    
    Write-AtomBanner -Verb "Adapter" -Type "Packages.Providers" -Icon "ﮣ"
    Register-AtomAdapters -Persona $Persona -Name Packages.Providers 

    $Persona | Import-AtomPersonaModules
    
    if (-not $NoStartupCommands) {
        #Write-AtomStageHeader -Message "Run Persona Startup Commands"
        $Persona | Invoke-AtomStartupCommands
    }
    
}

function Get-AtomCurrentPersona {
    [Alias("persona")]
    Param()
    $Global:AtomPersona
}


function Import-AtomFramework {
    Param(
        $Persona
    )

    Get-ChildItem $Persona.Paths.Frameworks | ForEach-Object {
        Write-AtomListItem -File $_ -NoNewline
        New-Module -ScriptBlock ([scriptblock]::Create((Get-Content $_ -Raw))) -Name "AtomPS.Frameworks.$([System.IO.Path]::GetFileNameWithoutExtension($_.Name))" | Import-Module -Scope Global -Force
     }
     Write-Host
}

function Import-AtomPersonaModules {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $Persona
    )
    BEGIN{
        
    }
    PROCESS {
        $Persona.Zones | ForEach-Object {
            $zone = $_
            Write-AtomBanner -Type "$($zone.name.ToString().ToUpper())" -Depth 0 -Verb "Zone" -Icon '' -SecondaryColor $zone.color -PrimaryColor "Dark$($zone.color)"
            $imports = $_.modules | ForEach-Object {"$_.psm1"}
            $zonePath = (Get-AtomCurrentPersona).Paths.Zones | Join-Path -ChildPath $zone.name
            if($_.path) {
                $zonePath = $_.path
            }
            
            $moduleFiles = Get-ChildItem $zonePath -Recurse -Include $imports
                        
            $moduleFiles | ForEach-Object {
                $zoneModule = Import-Module $_ -Scope Global -Force -PassThru
                $functions = $zoneModule.ExportedFunctions.Keys -join ", "
                Write-AtomListItem -File $_.FullName -Depth 0 -Icon 'ﰩ' 
                if ($functions) {
                    Write-AtomListItem -Text $functions -Depth 1 -Icon ' ' -TextColor Magenta                    
                }
            }
        }
    }
}

function Register-AtomAdapters {
    Param (
        [Parameter(ValueFromPipeline = $true)]
        $Persona,
        $Name
    )
    $path = [System.IO.Path]::Combine($Persona.Paths.Adapters, $Name )
    $adapterFiles = Get-ChildItem -File -Path $path -Recurse
    $adapterFiles | ForEach-Object {
        $environment = Get-AtomCurrentPersona
        if (-not $environment.Adapters.ContainsKey($Name)) {
            $environment.Adapters.Add($Name, @{})
        }
        $adapterName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)  
        $environment.Adapters[$Name][$adapterName] = $_.FullName
        Write-AtomListItem -File $_  -Icon 'ﮣ' -NoNewline
    }
    Write-Host
    
}

function Get-AtomAdapterPath {
    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $Type,
        [string]
        [Parameter(Mandatory = $true)]
        $Name
    )
    $extensionPath = Invoke-Expression "(Get-AtomCurrentPersona).Adapters['$Type']['$Name']"
    if (-not $extensionPath) {
        throw "An adapter with the type '$Type' could not be resolved with name '$Name'"
    }
    return $extensionPath
}

function Get-AtomManifestFile{
    Param(
        $Zone,
        $Component,
        $Name
    )
    $path = (Get-AtomCurrentPersona).Paths.Zones | Join-Path -ChildPath $Zone -AdditionalChildPath "Manifest",$Component,$Name
    $path
}

function Invoke-AtomExtensionModule {
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

    $extensionModulePath = Get-AtomAdapterPath -Type $Type -Name $Name
    $module = Import-Module $extensionModulePath -Scope Local -PassThru -Force
    $command = $module.ExportedCommands[$FunctionName].ScriptBlock

    return & $command @FunctionArgs

}
function Update-AtomPersona {
    [Alias("atup")]
    Param(
        [Switch]
        $StartupCommands
    )
    $starterPath = Join-Path -Path $PSScriptRoot -ChildPath "AtomPS.ps1"
    & $starterPath -PersonaFile (Get-AtomCurrentPersona).Source -NoStartupCommands:(-not $StartupCommands)
}


function Invoke-AtomStartupCommands {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $Persona
    )

    $Persona.StartupCommands | ForEach-Object {
        
        Write-AtomBanner -Verb "Start" -Type $_.name -Icon ""
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
            Invoke-Expression "$($_.command)"
        }
    }
}



function Write-AtomBanner {
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

function Write-AtomListItem {
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
        $TextColor = [System.ConsoleColor]::White,
        $Kind = ""
    )
    $padding = (" " * $Depth)
    $finalItemText = ""
    
    Write-Host  "$padding $Icon " -ForegroundColor $IconColor -NoNewline

    if ($Text) {
        $finalItemText = $Text
    }
    else {
        $finalItemText = if ($ShowExtension) { $_.Name } else {
            [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        }
    }
    Write-Host $finalItemText -NoNewline:$NoNewLine -ForegroundColor $TextColor
}