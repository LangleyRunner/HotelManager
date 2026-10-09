param([string]$ServiceName)
$ErrorActionPreference='Stop'
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$principal=[Security.Principal.WindowsPrincipal]::new($identity)
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
 throw 'Abre PowerShell con Ejecutar como administrador y vuelve a ejecutar este script.'
}
$allServices=@(Get-CimInstance Win32_Service)
if($ServiceName){$services=@($allServices|Where-Object Name -eq $ServiceName)}
else{$services=@($allServices|Where-Object {$_.Name -match 'postgres' -or $_.DisplayName -match 'postgres' -or $_.PathName -match 'pg_ctl|postgres.exe'})}
if($services.Count -eq 0){throw 'No se encontro un servicio PostgreSQL. Ejecuta Diagnose-Postgres.ps1 para identificar quien escucha en 5432. No se detuvo nada.'}
if($services.Count -gt 1){$services|Format-Table Name,State,PathName -AutoSize;throw 'Hay varios servicios. Especifica -ServiceName con el nombre correcto. No se detuvo nada.'}
$service=$services[0]
$binMatch=[regex]::Match($service.PathName,'(?i)^\s*"?(.+?pg_ctl\.exe)"?(?:\s|$)')
$dataMatch=[regex]::Match($service.PathName,'(?i)(?:^|\s)-D\s+(?:"([^"]+)"|([^\s]+))')
if(-not $binMatch.Success -or -not $dataMatch.Success){throw 'No se pudo identificar el ejecutable o la carpeta de datos desde el servicio. No se detuvo nada.'}
$binDirectory=Split-Path $binMatch.Groups[1].Value
$data=if($dataMatch.Groups[1].Success){$dataMatch.Groups[1].Value}else{$dataMatch.Groups[2].Value}
$data=(Resolve-Path -LiteralPath $data).Path
$postgres=Join-Path $binDirectory 'postgres.exe'
$psql=Join-Path $binDirectory 'psql.exe'
if(-not (Test-Path -LiteralPath (Join-Path $data 'PG_VERSION')) -or -not (Test-Path -LiteralPath $postgres)){throw 'Instalacion o carpeta de datos invalidas; no se detuvo nada.'}
Write-Host "Servicio identificado: $($service.Name)"
Write-Host "Datos existentes: $data"
function ReadSecret($message){
 $secret=Read-Host $message -AsSecureString
 $ptr=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
 try{return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)}finally{[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)}
}
$password=ReadSecret 'Nueva contrasena para postgres'
$confirm=ReadSecret 'Repite la nueva contrasena'
if([string]::IsNullOrWhiteSpace($password) -or $password -cne $confirm){throw 'Las contrasenas no coinciden o estan vacias; no se detuvo nada.'}
# ASCII passwords avoid ambiguity with PostgreSQL SASLprep Unicode normalization.
if($password -match '[^\x20-\x7E]'){throw 'Para esta recuperacion usa una contrasena con letras sin tildes, numeros y simbolos ASCII.'}
$salt=New-Object byte[] 16
$rng=[Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($salt);$rng.Dispose()
$derive=[Security.Cryptography.Rfc2898DeriveBytes]::new($password,$salt,4096,[Security.Cryptography.HashAlgorithmName]::SHA256)
$key=$derive.GetBytes(32);$derive.Dispose()
function Hmac($bytes,$message){
 $h=[Security.Cryptography.HMACSHA256]::new([byte[]]$bytes)
 try{return ,($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($message)))}finally{$h.Dispose()}
}
$clientKey=Hmac $key 'Client Key'
$sha=[Security.Cryptography.SHA256]::Create()
$stored=$sha.ComputeHash($clientKey);$sha.Dispose()
$server=Hmac $key 'Server Key'
$verifier='SCRAM-SHA-256$4096:'+([Convert]::ToBase64String($salt))+'$'+([Convert]::ToBase64String($stored))+':'+([Convert]::ToBase64String($server))
$password=$null;$confirm=$null
Add-Type -Path (Join-Path $PSScriptRoot 'PgOfflineRecovery.cs')
$wasRunning=$service.State -eq 'Running'
try{
 if($wasRunning){
  Write-Host 'Deteniendo temporalmente SOLO el servicio identificado...'
  Stop-Service -Name $service.Name -ErrorAction Stop
  (Get-Service -Name $service.Name).WaitForStatus([ServiceProcess.ServiceControllerStatus]::Stopped,[TimeSpan]::FromSeconds(60))
 }
 if((Get-Service -Name $service.Name).Status -ne 'Stopped'){throw 'El servicio no esta detenido. Recuperacion cancelada.'}
 if(Test-Path -LiteralPath (Join-Path $data 'postmaster.pid')){throw 'El archivo de bloqueo sigue presente. No se borrara; revisa si otro servidor usa esta carpeta.'}
 [PgOfflineRecovery]::Run($postgres,$data,("ALTER ROLE postgres WITH PASSWORD '"+$verifier+"';"))
 Write-Host 'Contrasena de postgres restablecida.'
}finally{
 $verifier=$null;[Array]::Clear($key,0,$key.Length)
 if($wasRunning){
  Start-Service -Name $service.Name -ErrorAction Stop
  (Get-Service -Name $service.Name).WaitForStatus([ServiceProcess.ServiceControllerStatus]::Running,[TimeSpan]::FromSeconds(60))
  Write-Host 'Servicio PostgreSQL restaurado.'
 }
}
Write-Host 'Ahora cambia la contrasena de hotelmanager con Reset-DatabasePassword.ps1.'
Write-Host 'Cuando pida la contrasena actual de postgres, usa la que acabas de elegir.'
