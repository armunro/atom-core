function Get-CasaScopedParamValue {
    Param(
        $CasaKey
    )
    $CasaEnv = Get-CasaCurrentPersona
    $CasaEnv.State.InvokeParams[$CasaKey]
}

function Set-CasaScopedParamValue {
    Param(
        $CasaKey,
        $Value
    )
    $CasaEnv = Get-CasaCurrentPersona
    $CasaEnv.State.InvokeParams[$CasaKey] = $Value
}