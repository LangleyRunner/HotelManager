param([string]$Container='hotelmanager-postgres')
$ErrorActionPreference='Stop'
$command=Get-Command docker -ErrorAction SilentlyContinue
if($command){$docker=$command.Source}
else{
 $candidates=@(
  (Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\bin\docker.exe'),
  'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
 )
 $docker=$candidates|Where-Object {Test-Path -LiteralPath $_}|Select-Object -First 1
}
if(-not $docker){throw 'No se encontro el cliente Docker.'}
$state=& $docker inspect --format '{{.State.Running}}' $Container
if($LASTEXITCODE -ne 0 -or ($state|Out-String).Trim() -ne 'true'){throw 'El contenedor indicado no esta en ejecucion. No se cambio nada.'}
$admin=& $docker exec -u postgres $Container sh -c 'printf "%s" "${POSTGRES_USER:-postgres}"'
if($LASTEXITCODE -ne 0){throw 'No se pudo identificar el usuario inicial dentro del contenedor.'}
$admin=($admin|Out-String).Trim()
if([string]::IsNullOrWhiteSpace($admin)){throw 'No se identifico el usuario administrador.'}
$role=& $docker exec -u postgres $Container psql -U $admin -d postgres -w -Atc "SELECT current_user, rolsuper FROM pg_roles WHERE rolname=current_user;"
if($LASTEXITCODE -ne 0){throw 'La conexion local no permitio acceso administrativo. No se modifico la autenticacion ni la base.'}
$role=($role|Out-String).Trim()
if($admin -ne 'hotelmanager' -and $role -notmatch '\|t$'){throw 'El usuario local no tiene permisos para cambiar hotelmanager.'}
$exists=& $docker exec -u postgres $Container psql -U $admin -d postgres -w -Atc "SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname='hotelmanager');"
if($LASTEXITCODE -ne 0 -or ($exists|Out-String).Trim() -ne 't'){throw 'El rol hotelmanager no existe o no se pudo comprobar. No se creo ni se borro nada.'}
Write-Host "Contenedor confirmado: $Container; acceso local: $admin"
Write-Host 'Elige una NUEVA contrasena para hotelmanager. psql la pedira dos veces de forma oculta.'
Write-Host 'No se necesita la contrasena anterior. No se detendra el contenedor ni se modificaran volumenes.'
& $docker exec -u postgres -it $Container psql -U $admin -d postgres -w -c '\password hotelmanager'
if($LASTEXITCODE -ne 0){throw 'No se pudo completar el cambio de contrasena.'}
Write-Host 'Ahora verifica esa NUEVA contrasena cuando psql la solicite:'
& $docker exec -it $Container psql -h 127.0.0.1 -U hotelmanager -d hotelmanager_db -W -c 'SELECT current_user, current_database();'
if($LASTEXITCODE -ne 0){throw 'La verificacion TCP no paso. Revisa la contrasena introducida y si existe hotelmanager_db.'}
Write-Host 'PASS: contrasena de hotelmanager restablecida y acceso TCP comprobado.'
Write-Host 'Ejecuta Start-HotelManager.ps1 -Verify -Port 8081 y usa esa contrasena como DB_PASSWORD.'
