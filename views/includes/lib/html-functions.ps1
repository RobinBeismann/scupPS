function Replace-HTMLVariables($Value){
    $Value = $Value.Replace("&","&amp;")
    $Value = $Value.Replace("`n","</br>")
    $Value = $Value.Replace("`t", "&emsp;")
    $Value = $Value.Replace("ä","&auml;")
    $Value = $Value.Replace("Ä","&Auml;")
    $Value = $Value.Replace("ö","&ouml;")
    $Value = $Value.Replace("Ö","&Ouml;")
    $Value = $Value.Replace("ü","&uuml;")
    $Value = $Value.Replace("Ü","&Uuml;")
    $Value = $Value.Replace("ß","&szlig;")
    $Value = $Value.Replace("€","&euro;")
    $Value = $Value.Replace("§","&sect;")
    return $Value
}