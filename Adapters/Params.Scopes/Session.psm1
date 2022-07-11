function Get-CasaScopedParamValue {
    Param(
        $CasaKey
    )
    $CasaEnv = Get-CasaCurrentPersona
    $CasaEnv.State.Params[$CasaKey]
}

function Set-CasaScopedParamValue {
    Param(
        $CasaKey,
        $Value
    )
    $CasaEnv = Get-CasaCurrentPersona
    $CasaEnv.State.Params[$CasaKey] = $Value
}