$ErrorActionPreference='Continue'
Write-Host '=== Servicios PostgreSQL ==='
$services=@(Get-CimInstance Win32_Service | Where-Object {$_.Name -match 'postgres' -or $_.DisplayName -match 'postgres' -or $_.PathName -match 'postgres|pg_ctl'})
if($services.Count){$services|Format-List Name,DisplayName,State,ProcessId,PathName}else{Write-Host 'No se encontraron servicios PostgreSQL.'}
Write-Host '=== Puerto 5432 ==='
$connections=@(Get-NetTCPConnection -LocalPort 5432 -State Listen -ErrorAction SilentlyContinue)
$connections|Format-Table LocalAddress,LocalPort,OwningProcess -AutoSize
Write-Host '=== Procesos PostgreSQL y propietario del puerto ==='
$owners=@($connections|Select-Object -ExpandProperty OwningProcess -Unique)
$processes=@(Get-CimInstance Win32_Process | Where-Object {$_.Name -match '^(postgres|pg_ctl|com.docker.backend|wslhost|wslrelay|docker).*' -or $_.ProcessId -in $owners})
$processes|Format-List Name,ProcessId,ParentProcessId,ExecutablePath,CommandLine
Write-Host '=== Servicios propietarios del puerto ==='
Get-CimInstance Win32_Service | Where-Object {$_.ProcessId -in $owners -and $_.ProcessId -ne 0} | Format-List Name,State,PathName
Write-Host '=== Contenedores, si Docker esta disponible ==='
$docker=Get-Command docker -ErrorAction SilentlyContinue
if($docker){& $docker.Source ps -a --format '{{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}}'}
elseif(Test-Path 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'){& 'C:\Program Files\Docker\Docker\resources\bin\docker.exe' ps -a --format '{{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}}'}
else{Write-Host 'Docker no se encontro en PATH ni en la ruta habitual.'}
Write-Host 'Diagnostico terminado. No se detuvieron procesos ni se modificaron datos.'
