# These are the states that an EC2 VM can be in
# (I'm doing it this way to ensure I've considered all possible states. If it ever becomes possible for an instance
# to be in a different state, and one of my instance enters that state, this script should throw and error)
[array]$expectedStates = "pending","running","shutting-down","terminated","stopping","stopped"

# Asking EC2 what VMs I have running
$states = @()
Get-EC2Instance | ForEach-Object {	 
	$_.RunningInstance | ForEach-Object {
		$instanceId = (Get-EC2Instance $_.InstanceId).Instances.InstanceId
		$instancestate = (Get-EC2Instance $_.InstanceId).Instances.State.Name
		$msg = "$instanceId is in the state: $instancestate"
		Write-Output $msg
		$states += $instancestate
	}
}

# Checking to see if I have any VMs that are costing me money
$VMsRunning = $false
if (($states -contains "running") -or ($states -contains "pending")){
	$VMsRunning = $true
}

# Creating a summary of the status of all my VMs
$returnMsg = "Summary of existing EC2 instances: "
forEach ($state in $expectedStates){	
	$count = $states | Where-Object {$_ -like $state}
	$suffix = $state + ": " + $count.Length + ", "
	$returnMsg += $suffix
}

# Checking if there are any VMs in any other state
[array]$unexpectedStates = $states | Where-Object {$_ -notin $expectedStates}
$SumUnexpectedStates = $unexpectedStates.Length
$returnMsg = $returnMsg + "Unexpected states: $SumUnexpectedStates"

# Writing errors
if ($SumUnexpectedStates -gt 0){
	Write-Warning "D'oh! Looks like the build script is failing to recognise some instance states! Better check your code."
}
if ($VMsRunning){
	Write-Warning "D'oh! Looks like you've left some EC2 instances running overnight! If you aren't using them, best turn them off to save the pennies."
}

# Returning the good/bad news
if ($VMsRunning -or ($SumUnexpectedStates -gt 0)){
	Write-Error $returnMsg
} 
else {
	Write-Output "Good news! You don't have any expensive EC2 instances burning a hole in your wallet!"
	Write-Output $returnMsg
}
