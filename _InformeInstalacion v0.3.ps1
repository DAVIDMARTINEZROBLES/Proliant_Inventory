Clear-Host
Write-Host "-----------------------------------------------------------------------------------------------------------------"
Write-Host "|                                                                                                               |"
Write-Host "|   Name    : Installation Inform                                                                               |"
Write-Host "|   Version  : 0.2                                                                                              |"
Write-Host "|                                                                                                               |"
Write-Host "|   Description:                                                                                                |"
Write-Host "|   - Extract the info of Proliant Server G7 / Gen8 / Gen9 / Gen10                                              |"
Write-Host "|                                                                                                               |"
Write-Host "|   Author: David.Martinez@hpecds.com                                                                           |"
Write-Host "|                                                                                                               |"
Write-Host "|   Input ILO:                                                                                                  |"
Write-Host "|   - Ip, user, password                                                                                        |"
Write-Host "|   - Optional input file format:                                                                               |"
Write-Host "|     header : IP,User,Password                                                                                 |"
Write-Host "|     content: SerialNumber,Customer Name,SomeDescription                                                       |"
Write-Host "|                                                                                                               |"
Write-Host "|   Pre-requisites:                                                                                             |"
Write-Host "|     HPEiLOCmdlets v 2.2.0.0                                                                                   |"
Write-Host "|                                                                                                               |"
Write-Host "-----------------------------------------------------------------------------------------------------------------"

#Asignamos el tamaño de ventana de forma correcta.
$Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size (5000, 500)

$ArrayServers = @()

if (-not (get-module HPEiLOCmdlets))
	{
		Import-Module HPEiLOCmdlets
		$version = Get-Module HPEiLOCmdlets | Select-Object -ExpandProperty Version
		If ($version.Minor -lt "3") {Update-Module HPEiLOCmdlets -Force -AcceptLicense}
	}

function CollectConfigFile($ILOIP, $ILOUSER, $ILOPASSWORD)
{
$iLOServerInfo = Find-HPEiLO $ILOIP -Full

if ($iLOServerInfo)
{
	$connection = Connect-HPEiLO -IP $ILOIP -Username $ILOUSER -Password $ILOPASSWORD -DisableCertificateAuthentication

	$iLOVersion = $connection.iLOGeneration -replace '\w+\D+',''
	$iLOVersionFW = $iLOServerInfo.ManagementProcessor.FWRI

	if (!$iLOServerInfo.HostSystemInformation.ProductID) {$productID = "#"} Else {$productID = $iLOServerInfo.HostSystemInformation.ProductID.trim()}

	#Write-Output "-POWERSUPPLY-"
	#$PowerSupply = Get-HPEiLOPowerSupply -Connection $connection
	#Write-Output "-FIRMWARE-"
	#$firmware = Get-HPEiLOFirmwareInventory -Connection $connection
	#Write-Output "-SMART-STORAGE-BATTERY-"
	#$smartArrayinfoBattery = Get-HPEiLOSmartStorageBattery -Connection $connection
	#$ServerNicInfo = Get-HPEiLONICInfo -Connection $connection

	#Write-Output "-SERVER-INFO-"
	$ServerInfo = Get-HPEiLOServerInfo -Connection $connection
	if ($iLOVersion -eq "5")
		{
		#Feature not supported on iLO3 and iLO4
		$SystemInfo = Get-HPEiLOSystemInfo -Connection $connection
		$swInventory = Get-HPEiLOServerSoftwareInventory -Connection $connection
		$IntelligentProvisioning = Get-HPEiLOIntelligentProvisioningInfo -Connection $connection
		$PCIInfo = Get-HPEiLOPCIDeviceInventory -Connection $connection
		}
	#Write-Output "-LICENSES-"
	$ServerLicenseInfo = Get-HPEiLOLicense -Connection $connection
	if ($iLOVersion -eq "5" -And $iLOVersionFW -gt '1.17')
		{
		#Feature not supported on iLO3, iLO4 and iLO5 (FW Ver: 1.10,1.11,1.15,1.17)
		$deviceINFO = Get-HPEiLODeviceInventory -Connection $connection
		}
	#Write-Output "-PROCESSOR-"
	$ILoProcessor = Get-HPEiLOProcessor -Connection $connection
		if ($iLOVersion -eq "3")
		{
			$CPU = ([string]($ILoProcessor.Processor.count) + " x CPU " + $ILoProcessor.Processor[0].RatedSpeedMHz + " MHz (" + ($ILoProcessor.Processor[0].TotalCores) + " cores)")
		}
		if ($iLOVersion -eq "4" -Or $iLOVersion -eq "5" )
		{
		$CPU = [string]($ILoProcessor.Processor.count) + " x " + ($ILoProcessor.Processor[0].Model).trim()
		}
	#Write-Output "-SMART-ARRAY-CONTROLLER-"	
	if ($iLOVersion -eq "4" -Or $iLOVersion -eq "5" )
		{#Feature not supported on iLO3.
		$smartArrayinfo = Get-HPEiLOSmartArrayStorageController -Connection $connection
		}
	#Write-Output "-TPM-"
	$ServerTPM = Get-HPEiLOTPMStatus -Connection $connection
		if($ServerTPM.TPMEnabled -eq "Yes") {$TPMStatus = "Enable"} Else {$TPMStatus = "Not Enable"}
	#Write-Output "-ILO-NIC-INFO-"
	$ILONicInfo = Get-HPEiLOIPv4NetworkSetting -Connection $connection
	 IF ($ILONicInfo.DHCPv4Enabled -eq "Yes") {$dhcp = "DHCP"}else{ $dhcp = "Static"}
	 IF ($ILONicInfo.DeviceType -eq "Dedicated") {$ILOPort = "Dedicado"}else{$ILOPort = "Compartido"}
	#Write-Output "-MEMORY-INFO-"	
	$Memory = Get-HPEiLOMemoryInfo -Connection $connection
			$MemorySum = 0
			if ($iLOVersion -eq "3")
				{
				$MemorySum = ([String] ($Memory.MemoryComponent | Where-Object MemorySizeMB -NE "Not Installed"| Select-Object MemorySizeMB | Select-Object-String "(\d+)" | ForEach-Object {$_.Matches.Groups[1].Value} | Measure-Object -Sum).Sum + [String](" MB"))
				}
			if ($iLOVersion -eq "4" -Or $iLOVersion -eq "5" )
				{
				$MemorySum = ([String] ((($Memory.MemoryDetailsSummary | Select-Object TotalMemorySizeGB | Measure-Object -Sum TotalMemorySizeGB).sum) * 1024) + [String](" MB"))
				#$MemorySum = ([String] ($serverinfo.MemoryInfo.MemoryDetails.memoryData | Select-Object CapacityMiB | Measure-Object -Sum CapacityMiB | Select-Object-object -ExpandProperty Sum) + [String](" MB"))
				}
		#Write-Output "-USER-INFO-"	
		$ILOUsers = Get-HPEiLOUser -Connection $connection
		

	 $myObject = New-Object System.Object

	$myObject | Add-Member -type NoteProperty -name "Modelo" -Value ($iLOServerInfo.HostSystemInformation.SPN)
	$myObject | Add-Member -type NoteProperty -name "Serial Number" -Value ($iLOServerInfo.HostSystemInformation.SerialNumber)
	$myObject | Add-Member -type NoteProperty -name "ProductID" -Value ($productID)
	$myObject | Add-Member -type NoteProperty -name "Server Name" -Value ($serverinfo.ServerName)
	$myObject | Add-Member -type NoteProperty -name "ROM Fw" -Value ($serverinfo.FirmwareInfo | Where-Object FirmwareName -eq "System ROM" | Select-Object -ExpandProperty FirmwareVersion)
	$myObject | Add-Member -type NoteProperty -name "ILO Fw" -Value ($serverinfo.FirmwareInfo | Where-Object FirmwareName -like "iLO*" | Select-Object -ExpandProperty FirmwareVersion)
	$myObject | Add-Member -type NoteProperty -name "ILO License" -Value (($serverLicenseInfo.License) + " (" + ($serverLicenseInfo.Key) + ")")
	$myObject | Add-Member -type NoteProperty -name "User Default" -Value (($ILOUSER) + " / " + ($ILOPASSWORD))
	$myObject | Add-Member -type NoteProperty -name "User Add" -Value (($newUserILO) + " / " + ($newPasswordILO))
	$myObject | Add-Member -type NoteProperty -name "IloPort" -Value ( $ILONicInfo.InterfaceType + " ($dhcp)")
	$myObject | Add-Member -type NoteProperty -name "IloDNS" -Value ($ILONicInfo.DNSName)
	$myObject | Add-Member -type NoteProperty -name "IloIPv4" -Value ($ILONicInfo.IPv4Address)
	$myObject | Add-Member -type NoteProperty -name "IloMask" -Value ($ILONicInfo.IPv4SubnetMask)
	$myObject | Add-Member -type NoteProperty -name "IloGateway" -Value ($ILONicInfo.IPv4Gateway)
	$myObject | Add-Member -type NoteProperty -name "IntelligentProvisioning" -Value ($serverinfo.FirmwareInfo | Where-Object FirmwareName -like "Intelligent Provisioning" | Select-Object -ExpandProperty FirmwareVersion)
	$myObject | Add-Member -type NoteProperty -name "CPU" -Value ($CPU)
	$myObject | Add-Member -type NoteProperty -name "Memory MB" -Value ($MemorySum)
	$myObject | Add-Member -type NoteProperty -name "TPMModule" -Value ($ServerTPM.TrustedModuleType)
	$myObject | Add-Member -type NoteProperty -name "TPMModuleEnable" -Value ($TPMStatus)
	$myObject | Add-Member -type NoteProperty -name "ALOM" -Value ($serverinfo.FirmwareInfo | Where-Object Location -eq "Embedded ALOM" | Select-Object -expandProperty FirmwareName)
	$myObject | Add-Member -type NoteProperty -name "ALOM Fw" -Value ($serverinfo.FirmwareInfo | Where-Object Location -eq "Embedded ALOM" | Select-Object -expandProperty FirmwareVersion)
	$myObject | Add-Member -type NoteProperty -name "LOM" -Value ($serverinfo.FirmwareInfo | Where-Object Location -eq "Embedded LOM" | Select-Object -expandProperty FirmwareName)
	$myObject | Add-Member -type NoteProperty -name "LOM Fw" -Value ($serverinfo.FirmwareInfo | Where-Object Location -eq "Embedded LOM" | Select-Object -expandProperty FirmwareVersion)
	$myObject | Add-Member -type NoteProperty -name "EmbeddedRAID" -Value ($serverinfo.FirmwareInfo | Where-Object Location -eq "Embedded RAID" | Select-Object -ExpandProperty FirmwareName)
	$myObject | Add-Member -type NoteProperty -name "EmbeddedRAID Fw" -Value ($serverinfo.FirmwareInfo | Where-Object Location -eq "Embedded RAID" | Select-Object -ExpandProperty FirmwareVersion)
	$ControllerCount = $SmartArrayinfo.Controllers.count
	for ($i=0; $i -lt $ControllerCount ; $i++)
		{
		$LogicalDriveCount = $SmartArrayinfo.Controllers[$i].LogicalDrives.Count
		$UnconfiguredDrivesModelCount = ($SmartArrayinfo.Controllers[$i].UnconfiguredDrives.Model | Get-Unique).count
		$Id=$SmartArrayinfo.Controllers[$i].Id 
		$myObject | Add-Member -type NoteProperty -name "SmartArray $Id Model" -Value ($SmartArrayinfo.Controllers[$i].Model)
		$myObject | Add-Member -type NoteProperty -name "SmartArray $Id Fw" -Value ("Fw. " + ($SmartArrayinfo.Controllers[$i].FirmwareVersion) + " (" + ($SmartArrayinfo.Controllers[$i].CacheMemorySizeMiB) + " MB Cache)")
		for ($j=0; $j -lt $LogicalDriveCount; $j++)
			{
			$HDDRAID = [string] ($SmartArrayinfo.Controllers[$i].LogicalDrives[$j].DataDrives | Where-Object-Object Model -eq ($SmartArrayinfo.Controllers[$i].LogicalDrives[$j].DataDrives.Model | Get-Unique)).count + " x " + ($SmartArrayinfo.Controllers[$i].LogicalDrives[$j].DataDrives.Model | Get-Unique) 
			$RAID = [string] $SmartArrayinfo.Controllers[$i].LogicalDrives[$j].CapacityMib + "MB (RAID " + $SmartArrayinfo.Controllers.LogicalDrives[$j].Raid + ")"
			$myObject | Add-Member -type NoteProperty -name "C$Id-L$j-HDDs" -Value ($HDDRAID)
			$myObject | Add-Member -type NoteProperty -name "C$Id-L$j-RAID" -Value ($RAID)
			}
		for ($k=0; $k -lt $UnconfiguredDrivesModelCount; $k++)
			{
			$cantidad = [string](($SmartArrayinfo.Controllers[$i].UnconfiguredDrives | Where-Object Model -like ([string](($SmartArrayinfo.Controllers[$i].UnconfiguredDrives | Select-Object Model | Get-Unique)[$k] | Select-Object -ExpandProperty Model)))).count
			$modelo = [string](($SmartArrayinfo.Controllers[$i].UnconfiguredDrives | Select-Object Model | Get-Unique)[$k] | Select-Object -ExpandProperty Model)
			$myObject | Add-Member -type NoteProperty -name "C$Id-U$k-HDDs" -Value ($cantidad + " x " + $modelo)
			}
		}
	#Feature not supported on iLO3 and iLO4.
	$PCINumberSlots = ($PCIInfo.PCIDevice | Where-Object DeviceLocation -Like "*PCI-E*").count
	For ($i=1; $i -le $PCINumberSlots; $i++)
		{
			$myObject | Add-Member -type NoteProperty -name "PCI-E Slot $i" -Value ($serverinfo.FirmwareInfo | Where-Object Location -eq "PCI-E Slot $i" | Select-Object -expandProperty FirmwareName)
			$myObject | Add-Member -type NoteProperty -name "PCI-E Slot $i Fw" -Value ($serverinfo.FirmwareInfo | Where-Object Location -eq "PCI-E Slot $i" | Select-Object -expandProperty FirmwareVersion)
		}
	$MezzanineSlots = ($PCIInfo.PCIDevice | Where-Object DeviceLocation -Like "*Mezzanine*").count
	For ($i=1; $i -le $MezzanineSlots; $i++)
		{
			$myObject | Add-Member -type NoteProperty -name "Mezz-Slot $i" -Value ($serverinfo.FirmwareInfo | Where-Object Location -eq "Mezzanine Slot $i" | Select-Object -expandProperty FirmwareName)
			$myObject | Add-Member -type NoteProperty -name "Mezz-Slot $i Fw" -Value ($serverinfo.FirmwareInfo | Where-Object Location -eq "Mezzanine Slot $i" | Select-Object -expandProperty FirmwareVersion)
		}
	$NVMEDevices = ($PCIInfo.PCIDevice | Where-Object DeviceLocation -Like "*NVMe*").count
	For ($i=0; $i -lt $NVMEDevices; $i++)
		{
			$myObject | Add-Member -type NoteProperty -name "NVMe $i" -Value ($serverinfo.FirmwareInfo | Where-Object Location -Like "*NVMe*" | Select-Object -expandProperty FirmwareName)[$i]
			$myObject | Add-Member -type NoteProperty -name "NVMe $i Fw" -Value ($serverinfo.FirmwareInfo | Where-Object Location -Like "*NVMe*" | Select-Object -expandProperty FirmwareVersion)[$i]
		}

}

return $myObject
}	

	
	
do {
	Write-Host ""
  Write-Host "========================= Menu options ==================================="
  Write-Host ""
  Write-Host "1: Extract a single Server info based on IP"
  Write-Host "2: Save the last Server info to file"
  Write-Host "3: Save all the Server info to file and exit"
  Write-Host "4: Extract a multiple Server info, based on input csv file"
  Write-Host ""
  Write-Host "0: Exit this menu"
  Write-Host ""

  $MenuChoice = Read-Host -Prompt "Choice"
  Write-Host ""
	  
 
  if ($MenuChoice -eq 1) {
		$ILOIP = Read-Host -Prompt "Please provide iLO IP"
		$ILOUSER = Read-Host -Prompt "Please provide iLO UserName"
		$ILOPASSWORD = Read-Host -Prompt "Please provide iLO Password"

    $ServerInfoCollect = CollectConfigFile $ILOIP $ILOUSER $ILOPASSWORD
	Write-Host "-----------------------------------------------------------------------------------------------------------------"
	Write-Host "| Server Info                                                                                                   |"
	Write-Host "-----------------------------------------------------------------------------------------------------------------"
	
	$ServerInfoCollect
	Write-Host "-----------------------------------------------------------------------------------------------------------------"
	Write-Host "| Server Nic Info                                                                                               |"
	Write-Host "-----------------------------------------------------------------------------------------------------------------"
		$iLOServerInfo.HostSystemInformation.NICS | Format-Table
	Write-Host "-----------------------------------------------------------------------------------------------------------------"

		$ArrayServers += $ServerInfoCollect
		
	} elseif ($MenuChoice -eq 2) {
		$ServerInfoCollect | Out-File -FilePath .\$ILOIP.txt
	
	} elseif ($MenuChoice -eq 3) {
		$file = (Get-Date -Format "yyyyMMdd-HHmmss") + " ServerInfo"
		$ArrayServers | export-csv .\$file.csv -NoTypeInformation
		break
  } elseif ($MenuChoice -eq 4) {
    Add-Type -AssemblyName System.Windows.Forms
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
		#InitialDirectory = [Environment]::GetFolderPath($folderpath)
		Filter = 'CSV files (*.csv, *.txt)|*.csv;*.txt|All files|*.*'}
	
	$null = $FileBrowser.ShowDialog()
    Write-Host $FileBrowser.FileName

    $List = Import-Csv $FileBrowser.FileName

    ForEach ($entry in $List)
		{
      $ILOIP = $($entry.IP)
      $ILOUSER = $($entry.User)
      $ILOPASSWORD = $($entry.Password)
      Write-Host "Retrieving info of Sever with IP $ILOIP" -ForegroundColor Green

      $ServerCollectInfo = CollectConfigFile $ILOIP $ILOUSER $ILOPASSWORD
			$ServerCollectInfo | Out-File -FilePath ".\$ILOIP.txt" -Append
			$ArrayServers += $ServerCollectInfo
    }
		
		$ArrayServers | export-csv .\fichero.csv -NoTypeInformation
	} elseif ($MenuChoice -eq 0) {

	Write-Host ""
    Write-Host "Thank you, bye."
    Start-Sleep -Milliseconds 500
	break
	} else {
    Write-Host "Incorrect input provided"
    pause
  }
} while (1 -ne 2) # This loop will always go on. There is a break in the loop to stop it when menu item 0 is chosen, or when this script is run in batch mode


	

#G7 = 
#$ILOIP = "16.23.26.56"
#Gen8 =
#$ILOIP = "16.23.27.127"
##Gen9
#$ILOIP = "16.23.27.124"
#$ILOUSER = "Administrator"
#$ILOPASSWORD = "admin2018"
#$ILOIP = "192.168.1.249"
#$ILOUSER = "hp"
#$ILOPASSWORD = "hpinvent"
