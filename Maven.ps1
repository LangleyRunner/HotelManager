param([Parameter(ValueFromRemainingArguments=$true)][string[]]$MavenArguments)
$ErrorActionPreference='Stop'
Push-Location (Join-Path $PSScriptRoot 'backend')
try{
 $cache=Join-Path $env:USERPROFILE '.m2'
 $maven=Get-ChildItem (Join-Path $cache 'wrapper\dists') -Recurse -Filter mvn.cmd -ErrorAction SilentlyContinue | Where-Object FullName -Match 'apache-maven-3.9.16' | Select-Object -First 1
 if($maven){ & $maven.FullName "-Dmaven.repo.local=$cache\repository" "-Duser.home=$env:USERPROFILE" -B -ntp @MavenArguments }
 else { $env:MAVEN_USER_HOME=$cache; & .\mvnw.cmd "-Dmaven.repo.local=$cache\repository" "-Duser.home=$env:USERPROFILE" -B -ntp @MavenArguments }
 $code=$LASTEXITCODE
}finally{Pop-Location}
exit $code
