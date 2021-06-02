param (
     [Parameter(Mandatory=$true)][string]$process
 )

get-Process $process | stop-process -Force



