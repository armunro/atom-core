function Get-AtomScopedParamValue {
    Param(
        $AtomKey
    )
    $AtomEnv = Get-AtomCurrentPersona
    $AtomEnv.State.Params[$AtomKey]
}

function Set-AtomScopedParamValue {
    Param(
        $AtomKey,
        $Value
    )
    $AtomEnv = Get-AtomCurrentPersona
    $AtomEnv.State.Params[$AtomKey] = $Value
}