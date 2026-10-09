param([switch]$Verify,[int]$Port=8080)
$ErrorActionPreference='Stop'
Set-Location $PSScriptRoot
function Secret($prompt) {
 $secure=Read-Host $prompt -AsSecureString
 $ptr=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
 try{return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)}
 finally{[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)}
}
if(-not $env:DB_PASSWORD){$env:DB_PASSWORD=Secret 'Contraseña PostgreSQL (DB_PASSWORD)'}
if(-not $env:ADMIN_PASSWORD){$env:ADMIN_PASSWORD=Secret 'Contraseña admin existente, o nueva si aún no existe'}
$env:SERVER_PORT=[string]$Port
if(-not $env:DB_URL){$env:DB_URL='jdbc:postgresql://localhost:5432/hotelmanager_db'}
if(-not $env:DB_USER){$env:DB_USER='hotelmanager'}
if([string]::IsNullOrWhiteSpace($env:DB_PASSWORD) -or [string]::IsNullOrWhiteSpace($env:ADMIN_PASSWORD)){throw 'Debes proporcionar ambas contraseñas; no se guardarán en archivos.'}
$jar=Join-Path $PSScriptRoot 'backend\target\backend-0.0.1-SNAPSHOT.jar'
if(-not (Test-Path $jar)){ & "$PSScriptRoot\Maven.ps1" package; if($LASTEXITCODE -ne 0){throw 'Falló la compilación'} }
if(-not $Verify){
 Write-Host "Acceso: http://localhost:$Port/login.html · usuario admin"
 try { & java -jar $jar } finally {Remove-Item Env:DB_PASSWORD,Env:ADMIN_PASSWORD -ErrorAction SilentlyContinue}
 exit
}
Add-Type -AssemblyName System.Net.Http
$base="http://localhost:$Port"
$ownProcess=$null
$handler=[Net.Http.HttpClientHandler]::new()
$handler.AllowAutoRedirect=$false
$client=[Net.Http.HttpClient]::new($handler)
function Request($path,$method='GET',$data=$null,$token=$null,$form=$false){
 $req=[Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::new($method),"$base$path")
 if($token){$req.Headers.Add('X-CSRF-TOKEN',$token)}
 if($null -ne $data){
  if($form){$fields=[Collections.Generic.Dictionary[string,string]]::new();foreach($key in $data.Keys){$fields.Add([string]$key,[string]$data[$key])};$req.Content=[Net.Http.FormUrlEncodedContent]::new($fields)}
  else{$req.Content=[Net.Http.StringContent]::new(($data|ConvertTo-Json -Compress),[Text.Encoding]::UTF8,'application/json')}
 }
 try{$res=$client.SendAsync($req).GetAwaiter().GetResult();$text=$res.Content.ReadAsStringAsync().GetAwaiter().GetResult();return @{Status=[int]$res.StatusCode;Body=$text}}
 finally{$req.Dispose()}
}
function Expect($result,$status){if($result.Status -ne $status){throw "HTTP esperado $status, recibido $($result.Status)"}}
function Launch {
 $script:ownProcess=Start-Process java -ArgumentList '-jar', ('"'+$jar+'"') -WindowStyle Hidden -PassThru -RedirectStandardOutput 'backend\runtime.log' -RedirectStandardError 'backend\runtime-error.log'
 for($i=0;$i -lt 60;$i++){
  if($script:ownProcess.HasExited){throw 'El backend no inició. Revisa backend/runtime-error.log y runtime.log.'}
  try{$r=Request '/api/csrf';if($r.Status -eq 200){return}}catch{}
  Start-Sleep -Seconds 1
 }
 throw 'El backend no respondió en 60 segundos.'
}
function Login {
 $csrf=(Request '/api/csrf').Body|ConvertFrom-Json
 $r=Request '/login' 'POST' @{username='admin';password=$env:ADMIN_PASSWORD;_csrf=$csrf.token} $null $true
 Expect $r 302
 if($r.Body -match 'error'){throw 'Login fallido'}
 $r=Request '/api/habitaciones';Expect $r 200
 return ((Request '/api/csrf').Body|ConvertFrom-Json).token
}
try{
 $tcp=[Net.Sockets.TcpClient]::new()
 try{$tcp.Connect('localhost',$Port);throw "Puerto $Port ocupado. Usa -Port 8081; no se detuvo ningún proceso."}
 catch [Net.Sockets.SocketException]{}finally{$tcp.Dispose()}
 Launch
 Expect (Request '/api/habitaciones') 401
 Expect (Request '/api/habitaciones' 'POST' @{}) 403
 $token=Login
 Expect (Request '/api/habitaciones' 'POST' @{}) 403
 $rooms=(Request '/api/habitaciones').Body|ConvertFrom-Json
 $room=@($rooms|Where-Object numero -eq 101)
 if($room.Count -eq 0){
  $r=Request '/api/habitaciones' 'POST' @{numero=101;tipo='Individual';precio=55.00;disponible=$true} $token;Expect $r 201
  $room=@($r.Body|ConvertFrom-Json)
 }
 $existing=$room[0]
 $original=@{numero=$existing.numero;tipo=$existing.tipo;precio=$existing.precio;disponible=$existing.disponible}
 $updated=@{numero=$existing.numero;tipo=$existing.tipo;precio=$existing.precio;disponible=(-not $existing.disponible)}
 try{
  Expect (Request "/api/habitaciones/$($existing.id)" 'PUT' $updated $token) 200
  Expect (Request "/api/habitaciones/$($existing.id)") 200
 }finally{Expect (Request "/api/habitaciones/$($existing.id)" 'PUT' $original $token) 200}
 $number=Get-Random -Minimum 1000000 -Maximum 2000000
 while(@($rooms|Where-Object numero -eq $number).Count){$number=Get-Random -Minimum 1000000 -Maximum 2000000}
 $r=Request '/api/habitaciones' 'POST' @{numero=$number;tipo='Prueba temporal';precio=1.00;disponible=$true} $token;Expect $r 201
 $temporary=$r.Body|ConvertFrom-Json
 Expect (Request "/api/habitaciones/$($temporary.id)" 'DELETE' $null $token) 204
 Expect (Request "/api/habitaciones/$($temporary.id)") 404
 Stop-Process -Id $ownProcess.Id
 $ownProcess.WaitForExit()
 $client.Dispose();$handler.Dispose()
 $handler=[Net.Http.HttpClientHandler]::new();$handler.AllowAutoRedirect=$false
 $client=[Net.Http.HttpClient]::new($handler)
 Launch
 $token=Login
 $r=Request "/api/habitaciones/$($existing.id)";Expect $r 200
 $persisted=$r.Body|ConvertFrom-Json
 if($persisted.numero -ne 101 -or [decimal]$persisted.precio -ne [decimal]$original.precio -or $persisted.disponible -ne $original.disponible){throw 'Persistencia incorrecta tras reiniciar'}
 Expect (Request '/logout' 'POST' $null $token) 302
 Expect (Request '/api/habitaciones') 401
 $report="PASS PostgreSQL: login, CRUD, CSRF, acceso anónimo, logout y habitación 101 después de reiniciar. Fecha: $(Get-Date -Format o)"
 Set-Content 'VERIFICACION-POSTGRESQL.txt' $report -Encoding utf8
 Write-Host $report
 Write-Host "Backend activo en $base/login.html. PID propio: $($ownProcess.Id). Para detenerlo: Stop-Process -Id $($ownProcess.Id)"
 $ownProcess=$null
}catch{
 Write-Host 'Verificación incompleta. No se eliminaron tablas ni volúmenes.'
 throw
}finally{
 if($ownProcess -and -not $ownProcess.HasExited){Stop-Process -Id $ownProcess.Id}
 $client.Dispose();$handler.Dispose()
 Remove-Item Env:DB_PASSWORD,Env:ADMIN_PASSWORD -ErrorAction SilentlyContinue
}
