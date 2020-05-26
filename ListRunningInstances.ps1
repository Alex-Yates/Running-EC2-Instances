# To do - Write this PS
Write-Output "Starting script"

$states = @()

Get-EC2Instance | ForEach-Object {	 
	 $_.RunningInstance | ForEach-Object {
	 	Write-Output $("Instance {0} is in the state {1}" -f $_.InstanceId, $_.State.Name)
		Write-Output "Checking State.Name actually holds a value"
		$instancestate = (Get-EC2Instance $_.InstanceId).Instances.State.Name
		Write-Output "instantstate is: $instancestate"
		Write-Output "Adding $instancestate to states" 
		$states += $instancestate
	 }
}

Write-Output "Logging all the states"
$states | ForEach-Object {
	Write-Output "There is an instance in the state: " + $_
}

$expectedStates = "pending","running","shuttingDown","terminated","stopping","stopped"
$pending = $states.Length | Where-Object {$_ -like "pending"}
$running = $states.Length | Where-Object {$_ -like "running"}
$shuttingDown = $states.Length | Where-Object {$_ -like "shutting-down"}
$terminated = $states.Length | Where-Object {$_ -like "terminated"}
$stopping = $states.Length | Where-Object {$_ -like "stopping"}
$stopped = $states.Length | Where-Object {$_ -like "stopped"}
$unexpectedStates = $states.Length | Where-Object {$_ -notin $expectedStates}

$returnMsg = "Summary of current instances - Pending: $pending, Running: $running, Shutting down: $shuttingDown, Terminated: $terminated, Stopping: $stopping, Stopped: $stopped, Unexpected states: $unexpectedStates"

if ($unexpectedStates -gt 0){
	Write-Warning "D'oh! Looks like the build script is failing to recognise some instance states! Better check your code."
}
if (($pending -gt 0) -or ($running -gt 0) ){
	Write-Warning "D'oh! Looks like you've left some EC2 instances running overnight! If you aren't using them, best turn them off to save the pennies."
}

if (($pending -gt 0) -or ($running -gt 0) -or ($unexpectedStates -gt 0)){
	Write-Error $returnMsg
}
else {
	Write-Output "Good news! You don't have any expensive EC2 instances butning a hole in your wallet!"
	Write-Output $returnMsg
}

Write-Output "Finishing script"