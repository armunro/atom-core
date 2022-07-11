function Get-AtomCommandKey ()
{
    [Alias("ampkey")]
    Param(
        [Parameter(ValueFromPipeline=$true)]
        $Command,
        [Parameter(Position=0)]
        $ParamName
    )
    
    $zone = (Get-Item $Command.Module.Path).Directory.Parent.Parent.Name

    $commandKey = "$Zone $($Command.Module) $($Command.Name)"
    if($ParamName)
    {
        $commandKey += " $ParamName"
    }
    
    return $commandKey
}

function Split-AtomKey {
    Param(
        [Parameter(ValueFromPipeline=$true)]
        $AtomKey
    )
    $comps = $AtomKey -split " "
    return @{
        Zone = $comps[0]
        Module = $comps[1]
        Function = $comps[2]
        ParamName = $comps[3]
    }
}   