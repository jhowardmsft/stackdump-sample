
param ( [Parameter(Mandatory=$true)][string]$inputFile )

$i=0
$out=""
$ErrorActionPreference="Stop"

foreach ($line in [System.IO.File]::ReadLines((join-path ($pwd) -ChildPath $inputFile))) {
    # First match gets the goroutine# in the first match group, everything else in the second
    $goroutineMatch=[regex]::matches($line, "^goroutine (\d+) \[(.*)\]:")
    If ($goroutineMatch.Success -eq $True) {

        if ($out.Length -gt 0) { Write-Output $out }

        $i++
        $searching=$true
        $goroutineID=$goroutineMatch.Groups[1].Value
        $innerContents=$goroutineMatch.Groups[2].Value

        # inner contents will be something like
        #  running
        #  chan receive, nnn minutes]
        #  syscall, nnn minutes, locked to thread
        #  IO wait

        $innerItems=$innerContents.Split( ",")
        $operation=$innerItems[0]
        $mins=-1;
        $additional=""
        if ($innerItems.Count -gt 1) {
            if ($innerItems[1].Contains("minutes")) {
                $mins=[int]$innerItems[1].Replace(" minutes","")
            } else {
                $additional = $innerItems[1]
            }
        }
        if (($additional -eq "") -and ($innerItems.Count -gt 2)) {$additional=$innerItems[2].Trim()}
        $out="$i,$goRoutineID,$operation,$mins" ####,$additional"
        #if ($i -gt 50) { exit 0 }
    } else {
        if ($searching) {
            if ($line -match "container.\(\*State\).IsRunning") {
                $out+=",(Check state IsRunning)"
            }
            if ($line -match "reducePsContainer") {
                $searching=$false
                $out+=",ps"
            }
            if ($line -match "image.\(\*imageRouter\).deleteImages") {
                $searching=$false
                $out+=",rmi"
            }
            if ($line -match "daemon.\(\*Daemon\).ContainerInspect") {
                $searching=$false
                $out+=",inspect container"
            }
            if ($line -match "daemon.\(\*Daemon\).ContainerExecInspect") {
                $searching=$false
                $out+=",inspect exec"
            }
            if ($line -match "container.\(\*containerRouter\).postContainersStop") {
                $searching=$false
                $out+=",stop container"
            }
            if ($line -match "container.\(\*containerRouter\).postContainersKill") {
                $searching=$false
                $out+=",kill container"
            }
            if ($line -match "daemon.\(\*Daemon\).StateChanged") {
                $searching=$false
                $out+=",monitor StateChanged"
            }
            if ($line -match "container.\(\*containerRouter\).postContainerExecCreate") {
                $searching=$false
                $out+=",exec create"
            }
            if ($line -match "container.\(\*containerRouter\).postContainersAttach") {
                $searching=$false
                $out+=",attach container"
            }
            if ($line -match "jsonfilelog.\(\*JSONFileLogger\).readLogs") {
                $searching=$false
                $out+=",json log reader"
            }
            if ($line -match "stream.\(\*Config\).CopyToPipe.func2") {
                $searching=$false
                $out+=",consoleIO func2"
            }
            if ($line -match "stream.\(\*Config\).CopyToPipe.func1.1") {
                $searching=$false
                $out+=",consoleIO func1.1"
            }
            if ($line -match "logger.\(\*Copier\).copySrc") {
                $searching=$false
                $out+=",logger copier copySrc"
            }
            if ($line -match "container.AttachStreams") {
                $searching=$false
                $out+=",AttachStreams"
            }
            if ($line -match "net.runtime_pollWait") {
                $out+=",net.runtime_pollWait" #keep going for HTTP server
            }
            if ($line -match "hcsCreateComputeSystem") {
                $out+=",hcsCreateComputeSystem (**** Stuck ****???)"
            }
            if ($line -match "zhcsshim.go") {
                $out+=",zhcsshim"
            }
            if ($line -match "created by net/http.\(\*Server\).Serve") {
                $searching=$false
                $out+=",HTTP server"
            }
            if ($line -match "hcsshim.waitForNotification") {
                #$searching=$false
                $out+=",HCSwaitForNotification"
            }
            if ($line -match "libcontainerd.\(\*container\).terminate") {
                $out+=",libcontainerd terminate"
            }
            if ($line -match "libcontainerd.\(\*container\).shutdown") {
                $out+=",libcontainerd shutdown"
                if ($mins -eq -1) { $out+=",????PROBLEM - HUNG????" }
            }
            if ($line -match "waitProcessExitCode") {
                $searching=$false
                $out+=" (wait process exit)"
            }
            if ($line -match "ContainerExecStart") {
                $searching=$false
                $out+=",ContainerExecStart"
            }
            # If blocked on a semaphore
            if ($line -match "sync.runtime_Semacquire") {
                $out+=",$line"
            }
            if ($line -match "windows.StartServiceCtrlDispatcher") {
                $searching=$false
                $out+=",Windows service thread"
            }
            if ($line -match "golang.org/x/sys/windows/svc.Run") {
                $searching=$false
                $out+=",Windows service thread"
            }
            if ($line -match "svc.\(\*service\).run") {
                $searching=$false
                $out+=",Windows service thread"
            }
            if ($line -match "daemon.\(\*Daemon\).setupDumpStackTrap") {
                $searching=$false
                $out+=",debug trap thread"
            }
            if ($line -match "go-winio.\(\*win32PipeListener\).listenerRoutine") {
                $searching=$false
                $out+=",named pipe listener"
            }
        }
    }
}
# The last one
if ($out.Length -gt 0) { Write-Output $out }