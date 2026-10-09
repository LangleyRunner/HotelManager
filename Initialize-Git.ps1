param([string]$AuthorName='LangleyRunner',[string]$AuthorEmail)
$ErrorActionPreference='Stop'
$script:RepoRoot=$PSScriptRoot
Set-Location $script:RepoRoot
function GitCommand {
 & $script:GitExe -c "safe.directory=$script:RepoRoot" -C $script:RepoRoot --git-dir (Join-Path $script:RepoRoot '.git') --work-tree $script:RepoRoot @args
 if($LASTEXITCODE -ne 0){throw 'Git no pudo completar el comando anterior. Revisa su mensaje antes de continuar.'}
}
$candidates=@(
 'C:\Program Files\Git\cmd\git.exe',
 'C:\Program Files (x86)\Git\cmd\git.exe',
 (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe')
)
$pathGit=Get-Command git -CommandType Application -ErrorAction SilentlyContinue
if($pathGit){$candidates+=$pathGit.Source}
$candidates+=(Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe')
$script:GitExe=$candidates|Where-Object {Test-Path -LiteralPath $_ -PathType Leaf}|Select-Object -First 1
if(-not $script:GitExe){
 Write-Host 'No se encontro git.exe en las ubicaciones de instalacion.'
 throw 'Si solo descargaste el instalador, abre Git-*-64-bit.exe y completa la instalacion. Despues vuelve a ejecutar este script.'
}
Write-Host "Git detectado: $script:GitExe"
& $script:GitExe --version
if($LASTEXITCODE -ne 0){throw 'Git fue encontrado pero no pudo ejecutarse.'}

if(-not $AuthorEmail){$AuthorEmail=Read-Host 'Correo para tus commits (puede ser tu noreply de GitHub)'}
if($AuthorEmail -notmatch '^[^\s@]+@[^\s@]+$'){throw 'Introduce un correo valido. No se cambio la identidad Git global.'}
if(-not (Test-Path -LiteralPath (Join-Path $script:RepoRoot '.git\HEAD'))){GitCommand init -b main}
GitCommand rev-parse --show-toplevel
GitCommand config --local user.name $AuthorName
GitCommand config --local user.email $AuthorEmail
GitCommand add .
$tracked=@(GitCommand ls-files)
if($LASTEXITCODE -ne 0){throw 'No se pudo revisar el indice.'}
$forbidden=@($tracked|Where-Object {$_ -match '(^|/)(node_modules|target|\.npm-cache|\.git)/|(^|/)\.npmrc$|(^|/)\.env($|\.)|\.(log|pid|p12|jks)$'})
if($forbidden.Count){$forbidden;throw 'Hay archivos de secretos o generados en el indice. No se creo el commit; revisa .gitignore.'}
GitCommand diff --cached --stat
& $script:GitExe -c "safe.directory=$script:RepoRoot" -C $script:RepoRoot --git-dir (Join-Path $script:RepoRoot '.git') --work-tree $script:RepoRoot diff --cached --quiet
$changes=$LASTEXITCODE
if($changes -eq 1){GitCommand commit -m 'Completar HotelManager con CRUD, seguridad, interfaz y documentacion'}
elseif($changes -ne 0){throw 'No se pudo comparar el indice.'}
else{Write-Host 'No hay cambios nuevos para commit.'}
GitCommand status --short
GitCommand log -1 --format='%h %s'
Write-Host 'Repositorio local preparado. Para GitHub, crea HotelManager vacio, sin README, .gitignore ni licencia adicionales.'
Write-Host 'Despues configura origin con la URL real y ejecuta git push -u origin main.'
