param([string]$HostName='localhost',[int]$Port=5432,[string]$Administrator='postgres')
$ErrorActionPreference='Stop'
$psql=Get-Command psql -ErrorAction SilentlyContinue
if($psql){$binary=$psql.Source}
else{
 $binary=Get-ChildItem 'C:\Program Files\PostgreSQL' -Filter psql.exe -Recurse -ErrorAction SilentlyContinue | Where-Object FullName -Match '\\bin\\psql.exe$' | Select-Object -First 1 -ExpandProperty FullName
}
if(-not $binary){throw 'No se encontró psql. Usa el binario de tu instalación PostgreSQL.'}
Write-Host 'Se pedirá primero la contraseña ACTUAL del administrador PostgreSQL.'
Write-Host 'Después, escribe dos veces la NUEVA contraseña del rol hotelmanager.'
Write-Host 'La contraseña nueva se introduce en psql, no en comandos ni archivos.'
& $binary -h $HostName -p $Port -U $Administrator -d postgres -W -c '\password hotelmanager'
if($LASTEXITCODE -ne 0){throw 'No se pudo cambiar la contraseña. Necesitas acceso válido al administrador PostgreSQL; no se alteró la autenticación.'}
Write-Host 'Contraseña actualizada. Usa esa nueva contraseña como DB_PASSWORD en Start-HotelManager.ps1.'
