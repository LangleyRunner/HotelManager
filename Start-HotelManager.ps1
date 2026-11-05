param([switch]$Verify,[int]$Port=8081)
$ErrorActionPreference='Stop'
Set-Location $PSScriptRoot

function Secret($prompt) {
    $secure=Read-Host $prompt -AsSecureString
    $ptr=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}
if(-not $env:DB_PASSWORD){$env:DB_PASSWORD=Secret 'Contrasena PostgreSQL (DB_PASSWORD)'}
if(-not $env:ADMIN_PASSWORD){$env:ADMIN_PASSWORD=Secret 'Contrasena de admin existente, o nueva si todavia no existe'}
if([string]::IsNullOrWhiteSpace($env:DB_PASSWORD) -or [string]::IsNullOrWhiteSpace($env:ADMIN_PASSWORD)){
    throw 'Debes proporcionar ambas contrasenas; no se guardan en archivos.'
}
$env:SERVER_PORT=[string]$Port
$env:PORT=[string]$Port
if(-not $env:DB_USER){$env:DB_USER='hotelmanager'}
$jar=Join-Path $PSScriptRoot 'backend\target\backend-0.0.1-SNAPSHOT.jar'
if(-not (Test-Path -LiteralPath $jar)){
    & "$PSScriptRoot\Maven.ps1" package
    if($LASTEXITCODE -ne 0){throw 'Fallo la compilacion.'}
}
if(-not $Verify){
    Write-Host "HotelManager: http://localhost:$Port/login.html | usuario admin"
    try { & java -jar $jar }
    finally { Remove-Item Env:DB_PASSWORD,Env:ADMIN_PASSWORD -ErrorAction SilentlyContinue }
    exit
}

Add-Type -AssemblyName System.Net.Http
$base="http://localhost:$Port"
$ownProcess=$null
$client=$null
$handler=$null
$fixtureRoom=$null
$fixtureFloor=$null
$token=$null
$logFile=Join-Path $PSScriptRoot "backend\runtime-$Port.log"
$errorFile=Join-Path $PSScriptRoot "backend\runtime-error-$Port.log"

function NewClient {
    if($script:client){$script:client.Dispose()}
    if($script:handler){$script:handler.Dispose()}
    $script:handler=[Net.Http.HttpClientHandler]::new()
    $script:handler.AllowAutoRedirect=$false
    $script:client=[Net.Http.HttpClient]::new($script:handler)
}
function Request($path,$method='GET',$data=$null,$csrf=$null,$form=$false){
    $req=[Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::new($method),"$base$path")
    if($csrf){$req.Headers.Add('X-CSRF-TOKEN',$csrf)}
    if($null -ne $data){
        if($form){
            $fields=[Collections.Generic.Dictionary[string,string]]::new()
            foreach($key in $data.Keys){$fields.Add([string]$key,[string]$data[$key])}
            $req.Content=[Net.Http.FormUrlEncodedContent]::new($fields)
        }else{
            $req.Content=[Net.Http.StringContent]::new(($data|ConvertTo-Json -Compress),[Text.Encoding]::UTF8,'application/json')
        }
    }
    try {
        $res=$client.SendAsync($req).GetAwaiter().GetResult()
        $text=$res.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        return @{Status=[int]$res.StatusCode;Body=$text;Location=[string]$res.Headers.Location}
    }finally{$req.Dispose()}
}
function Expect($result,$status){
    if($result.Status -ne $status){throw "HTTP esperado $status, recibido $($result.Status). $($result.Body)"}
}
function Launch {
    $script:ownProcess=Start-Process java -ArgumentList '-jar', ('"'+$jar+'"') -WindowStyle Hidden -PassThru -RedirectStandardOutput $logFile -RedirectStandardError $errorFile
    for($attempt=0;$attempt -lt 90;$attempt++){
        if($script:ownProcess.HasExited){throw "El backend no inicio. Revisa $logFile y $errorFile."}
        try {if((Request '/health').Status -eq 200){return}}catch{}
        Start-Sleep -Seconds 1
    }
    throw 'El backend no respondio en 90 segundos.'
}
function Login {
    $csrf=(Request '/api/csrf').Body|ConvertFrom-Json
    $r=Request '/login' 'POST' @{username='admin';password=$env:ADMIN_PASSWORD;_csrf=$csrf.token} $null $true
    Expect $r 302
    if($r.Location -match 'error'){throw 'Usuario o contrasena del administrador incorrectos.'}
    Expect (Request '/api/habitaciones') 200
    return ((Request '/api/csrf').Body|ConvertFrom-Json).token
}
function Rooms { return @((Request '/api/habitaciones').Body|ConvertFrom-Json) }
function RoomData($number,$floor,$capacity=2) {
    return @{numero=$number;tipo='Doble';precio=55.00;disponible=$true;capacidad=$capacity;pisoId=$floor;estadoOperativo='HABILITADA'}
}
try{
    $tcp=[Net.Sockets.TcpClient]::new()
    try{$tcp.Connect('localhost',$Port);throw "Puerto $Port ocupado. Usa otro con -Port; no se detuvo ningun proceso."}
    catch [Net.Sockets.SocketException]{}finally{$tcp.Dispose()}
    NewClient
    Launch
    Expect (Request '/api/habitaciones') 401
    Expect (Request '/api/pisos') 401
    $token=Login
    $roomsBefore=Rooms
    $original101=@($roomsBefore|Where-Object numero -eq 101)
    $baseline101=if($original101.Count){$original101[0]|ConvertTo-Json -Compress -Depth 6}else{$null}

    $created=Request '/api/pisos' 'POST' @{nombre=('Prueba MVC '+[guid]::NewGuid().ToString('N').Substring(0,8))} $token
    Expect $created 201
    $fixtureFloor=($created.Body|ConvertFrom-Json).id
    $number=Get-Random -Minimum 1000000 -Maximum 2000000
    while(@($roomsBefore|Where-Object numero -eq $number).Count){$number=Get-Random -Minimum 1000000 -Maximum 2000000}
    $invalid=Request '/api/habitaciones' 'POST' (RoomData $number $fixtureFloor 0) $token
    Expect $invalid 400
    if($invalid.Body -notmatch 'capacidad'){throw 'El error debe identificar el campo capacidad.'}
    if((Rooms).Count -ne $roomsBefore.Count){throw 'La solicitud invalida modifico los registros.'}
    Write-Host 'PASS backend: capacidad 0 rechazada con HTTP 400; no se guardo la habitacion.'
    Expect (Request '/api/habitaciones' 'POST' (RoomData $number $fixtureFloor)) 403
    Expect (Request '/api/habitaciones' 'POST' (RoomData $number 999999999) $token) 404
    $created=Request '/api/habitaciones' 'POST' (RoomData $number $fixtureFloor) $token
    Expect $created 201
    $fixtureRoom=($created.Body|ConvertFrom-Json).id
    Expect (Request "/api/pisos/$fixtureFloor" 'DELETE' $null $token) 409
    $updated=RoomData $number $fixtureFloor 3
    $updated.precio=65.00
    $updated.estadoOperativo='MANTENIMIENTO'
    Expect (Request "/api/habitaciones/$fixtureRoom" 'PUT' $updated $token) 200

    # Keep 101 untouched when it already exists, including any fields pending configuration.
    if(-not $original101.Count){
        $data=RoomData 101 $fixtureFloor 1
        $data.tipo='Individual'
        Expect (Request '/api/habitaciones' 'POST' $data $token) 201
        $baseline101=(@(Rooms|Where-Object numero -eq 101)[0]|ConvertTo-Json -Compress -Depth 6)
        $keepFloor=$true
    }
    Stop-Process -Id $ownProcess.Id
    $ownProcess.WaitForExit()
    NewClient
    Launch
    $token=Login
    $persisted=Request "/api/habitaciones/$fixtureRoom"
    Expect $persisted 200
    $persisted=$persisted.Body|ConvertFrom-Json
    if($persisted.capacidad -ne 3 -or $persisted.piso.id -ne $fixtureFloor -or [decimal]$persisted.precio -ne 65 -or $persisted.estadoOperativo -ne 'MANTENIMIENTO'){
        throw 'Los datos de prueba no persistieron correctamente despues del reinicio.'
    }
    $after101=@(Rooms|Where-Object numero -eq 101)[0]|ConvertTo-Json -Compress -Depth 6
    if($after101 -cne $baseline101){throw 'La habitacion 101 cambio durante la prueba.'}
    Expect (Request "/api/habitaciones/$fixtureRoom" 'DELETE' $null $token) 204
    Expect (Request "/api/habitaciones/$fixtureRoom") 404
    $fixtureRoom=$null
    if(-not $keepFloor){
        Expect (Request "/api/pisos/$fixtureFloor" 'DELETE' $null $token) 204
        $fixtureFloor=$null
    }
    Expect (Request '/logout' 'POST' $null $token) 302
    Expect (Request '/api/habitaciones') 401
    $token=$null
    $report="PASS PostgreSQL MVC: login, pisos, FK, capacidad validada sin JavaScript, CRUD, CSRF, logout, persistencia tras reinicio y habitacion 101 conservada. Fecha: $(Get-Date -Format o)"
    Set-Content 'VERIFICACION-POSTGRESQL.txt' $report -Encoding utf8
    Write-Host $report
    Write-Host "Backend activo: $base/login.html. PID propio: $($ownProcess.Id). Detener: Stop-Process -Id $($ownProcess.Id)"
    $ownProcess=$null
}catch{
    if($token -and $client){
        try{
            if($fixtureRoom){[void](Request "/api/habitaciones/$fixtureRoom" 'DELETE' $null $token)}
            if($fixtureFloor -and -not $keepFloor){[void](Request "/api/pisos/$fixtureFloor" 'DELETE' $null $token)}
        }catch{}
    }
    throw
}finally{
    if($ownProcess -and -not $ownProcess.HasExited){Stop-Process -Id $ownProcess.Id}
    if($client){$client.Dispose()}
    if($handler){$handler.Dispose()}
    Remove-Item Env:DB_PASSWORD,Env:ADMIN_PASSWORD -ErrorAction SilentlyContinue
}
exit 0
