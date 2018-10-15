###############################################################
# DESCRIPTION: Get iLO Gen9 & Gen10 information for Proliant Servers
#
#       SERVER: 
#
#      OPTIONS: ---
# REQUIREMENTS: Powershell HPERedfishCmdlets
#         BUGS: ---
#        NOTES: ---
#    IMPORTANT: 
#       AUTHOR: David Martinez Robles (david.martinez@hpcds.com)
#      COMPANY: CDS a Hewlett Packard Enterprise company
#     CUSTOMER: 
#      VERSION: 0.91
#      CREATED: 20/05/2018
#     REVISION: 20/09/2018
#############################################################

Clear-Host
$Error.Clear()

#Load HPERedfishCmdlets module
$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPERedfishCmdlets"))
{
    Write-Host "Loading module :  HPERedfishCmdlets"
    Import-Module HPERedfishCmdlets
    if(($(Get-Module -Name "HPERedfishCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPERedfishCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstallediLOModule  =  Get-Module -Name "HPERedfishCmdlets"
    Write-Host "HPERedfishCmdlets Module Version : $($InstallediLOModule.Version) is installed on your machine."
    Write-host ""
}


#Decribe what script does to the user
Write-Host "This script gets a full inventory information.`n" -ForegroundColor Yellow

$Address = Read-Host 'IP-iLO'
Disable-HPERedfishCertificateAuthentication
$cred = Get-Credential
$session = Connect-HPERedfish -Address $Address -Credential $cred

#$Username  = Read-Host 'User'
#$Password  = Read-Host 'Password' -AsSecureString
#$session = Connect-HPERedfish -Address $Address -Username $Username -Password $Password -DisableCertificateAuthentication


# script execution started
Write-Host "****** Script execution started ******`n" -ForegroundColor Yellow


# Definition of file names
$ChassisLink = Get-HPERedfishDataRaw -odataid '/redfish/v1/Chassis/' -Session $session
$Chassis = Get-HPERedfishDataRaw -odataid '/redfish/v1/Chassis/1/' -Session $session
$GENERACION = $Chassis.Model
$fichero = $Chassis.Model + " ($Address)"
$ficherosalida = $fichero + ".txt"
$ficherosalidaJSON = $fichero + ".json"

#VARIABLES
	ECHO "--------------- INICIO-VARIABLES ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-VARIABLES ---------------" >> $ficherosalidaJSON
	$Systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/' -Session $session
	$SystemsLinks = Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/1/' -Session $session

	# Depends on the generation changes HP by HPE
	$HP = $SystemsLinks.Oem | Get-Member -MemberType NoteProperty | % Name

	$ETHERNETINTERFACES = $SystemsLinks.EthernetInterfaces.'@odata.id'
	$ETHERNETINTERFACES = $SystemsLinks.Oem.$HP.Links.EthernetInterfaces.'@odata.id'
	$PROCESSORSLink = $SystemsLinks.Processors.'@odata.id'
	$PCIDEVICESLink = $SystemsLinks.Oem.$HP.Links.PCIDevices.'@odata.id'
	$NETWORKADAPTERSLink = $SystemsLinks.Oem.$HP.Links.NetworkAdapters.'@odata.id'
	$PCISLOTSLink = $SystemsLinks.Oem.$HP.Links.PCISlots.'@odata.id'
	$SMARTSTORAGELink = $SystemsLinks.Oem.$HP.Links.SmartStorage.'@odata.id'
	$PSULink = $Chassis.Power.'@odata.id'
	$ManagedByLink = $Chassis.Links.ManagedBy.'@odata.id'
	$DrivesNVMELink = $Chassis.Links.Drives.'@odata.id'

# Definition of links according to generation
	if ($GENERACION -match 'Gen10')
	{#Gen10
		$BIOSLink = $SystemsLinks.Bios.'@odata.id'
		$MEMORYLink = $SystemsLinks.Memory.'@odata.id'
		$NETWORKINTERFACESLink = $SystemsLinks.NetworkInterfaces.'@odata.id'
		$SECUREBOOTLink = $SystemsLinks.SecureBoot.'@odata.id'
		$STORAGELink = $SystemsLinks.Storage.'@odata.id'
		$USBPORTSLink = $SystemsLinks.Oem.$HP.Links.USBPorts.'@odata.id'
		$USBDEVICESLink = $SystemsLinks.Oem.$HP.Links.USBDevices.'@odata.id'
		$FIRMWARELink = '/redfish/v1/UpdateService/FirmwareInventory/'
		$DEVICESLink = $Chassis.Oem.$HP.Links.Devices.'@odata.id'
	}
	else
	{#Gen9 & Gen8
		$BIOSLink = $SystemsLinks.Oem.$HP.Links.BIOS.'@odata.id'
		$FIRMWARELink = $SystemsLinks.Oem.$HP.Links.FirmwareInventory.'@odata.id'
		$MEMORYLink = $SystemsLinks.Oem.$HP.Links.Memory.'@odata.id'
		$SECUREBOOTLink = $SystemsLinks.Oem.$HP.Links.SecureBoot.'@odata.id'
		$SOFTWAREINVENTORYLink = $SystemsLinks.Oem.$HP.Links.SoftwareInventory.'@odata.id'
	}		

# Save variables in the file
	$SystemsLinks.Oem.$HP.Links >> $ficherosalida
	$PSULink >> $ficherosalida
	$DEVICESLink >> $ficherosalida
	$ManagedByLink  >> $ficherosalida
	$MEMORYLink >> $ficherosalida
	$BIOSLink >> $ficherosalida
	$FIRMWARELink >> $ficherosalida
	$SOFTWAREINVENTORYLink >> $ficherosalida
	$NETWORKADAPTERSLink >> $ficherosalida
	$PCIDEVICESLink >> $ficherosalida
	$PCISLOTSLink >> $ficherosalida
	$SMARTSTORAGELink >> $ficherosalida

	ECHO "--------------- FIN-VARIABLES ---------------" >> $ficherosalida
	ECHO "--------------- FIN-VARIABLES ---------------" >> $ficherosalidaJSON


# CHASSIS Information (Gen10 Gen9 Gen8)
Write-Host "****** Saving Chassis info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-CHASSIS ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-CHASSIS ---------------" >> $ficherosalidaJSON
    foreach($ChassisItem in $ChassisLink.Members.'@odata.id')
    {
        $ChassisData = Get-HPERedfishDataRaw -odataid $ChassisItem -Session $session
		$ChassisData | Convertto-Json -Depth 99 >> $ficherosalidaJSON
		$ChassisData | fl SerialNumber, SKU, Manufacturer, Model, ChassisType, Power >> $ficherosalida
	ECHO "+++++++++++++++" >> $ficherosalida
	}
	ECHO "--------------- FIN-CHASSIS ---------------" >> $ficherosalida
	ECHO "--------------- FIN-CHASSIS ---------------" >> $ficherosalidaJSON

# SYSTEM Information (Gen10 Gen9 Gen8)
Write-Host "****** Saving System info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-SISTEMA ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-SISTEMA ---------------" >> $ficherosalidaJSON

    foreach($sys in $systems.Members.'@odata.id')
    {
		$sysData = Get-HPERedfishDataRaw -odataid $sys -Session $session
		$sysData | Convertto-Json -Depth 99 >> $ficherosalidaJSON
        $sysData | fl Id, SerialNumber, HostName, Manufacturer, Model, SKU, Name, UUID, BiosVersion, PowerState, ProcessorSummary, MemorySummary >> $ficherosalida
		$sysData.ProcessorSummary | fl Count, Model >> $ficherosalida
		$sysData.ProcessorSummary.Status | fl >> $ficherosalida
		$sysData.MemorySummary | fl TotalSystemMemoryGiB >> $ficherosalida
		$sysData.Oem.$HP | fl IntelligentProvisioningVersion, PostState, PowerAllocationLimit, PowerRegulatorMode >> $ficherosalida
		$sysData.Oem.$HP.Battery >> $ficherosalida
		#JSON
	ECHO "+++++++++++++++" >> $ficherosalida
	}
	ECHO "--------------- FIN-SISTEMA ---------------" >> $ficherosalida
	ECHO "--------------- FIN-SISTEMA ---------------" >> $ficherosalidaJSON


# PROCESSSOR Information (Gen10 Gen9 Gen8)
Write-Host "****** Saving CPU info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-PROCESADORES ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-PROCESADORES ---------------" >> $ficherosalidaJSON

	$CPUs = Get-HPERedfishDataRaw -odataid $PROCESSORSLink -Session $session
	"NUMERO-DE-CPUS : " + $CPUs.'Members@odata.count' >> $ficherosalida

    foreach($CPU in $CPUs.Members.'@odata.id')
    {
        $Procesador = Get-HPERedfishDataRaw -odataid $CPU -Session $session
		$Procesador | Convertto-Json -Depth 99 >> $ficherosalidaJSON
        $Procesador | Select-Object -Property * >> $ficherosalida
	ECHO "+++++++++++++++" >> $ficherosalida
	}
	ECHO "--------------- FIN-PROCESADORES ---------------" >> $ficherosalida
	ECHO "--------------- FIN-PROCESADORES ---------------" >> $ficherosalidaJSON


#MEMORY Information (Gen10, Gen9, Gen8)
Write-Host "****** Saving Memory info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-MEMORIAS ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-MEMORIAS ---------------" >> $ficherosalidaJSON

	$Memorys = Get-HPERedfishDataRaw -odataid $MEMORYLink -Session $session
	"NUMERO-DE-MEMORIAS : " + $Memorys.'Members@odata.count' >> $ficherosalida

	foreach($Memory in $Memorys.Members.'@odata.id')
    {
        $Memoria = Get-HPERedfishDataRaw -odataid $Memory -Session $session
		$Memoria | Convertto-Json -Depth 99 >> $ficherosalidaJSON
		if ($GENERACION -match 'Gen10')
		{#Gen10
		$DIMMStatus = $Memoria.Oem.Hpe.DIMMStatus
		$Memoria | ft Id, Name, DeviceLocator, CapacityMiB, MemoryDeviceType, BaseModuleType, OperatingSpeedMhz, ErrorCorrection, DIMMStatus, PartNumber >> $ficherosalida
		}
		else
		{#Gen9 y Gen8
		$Memoria | ft Id, Name, SocketLocator, SizeMB, DIMMType, DIMMTechnology, MaximumFrequencyMHz, ErrorCorrection, DIMMStatus, PartNumber >> $ficherosalida
		}
	ECHO "+++++++++++++++" >> $ficherosalida
	}
	ECHO "--------------- FIN-MEMORIAS ---------------" >> $ficherosalida
	ECHO "--------------- FIN-MEMORIAS ---------------" >> $ficherosalidaJSON

	
#Informacion de las Power Supply (Gen10 Gen9 Gen8)
Write-Host "****** Saving Powersupplys info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-PSU ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-PSU ---------------" >> $ficherosalidaJSON
	$PSUs = Get-HPERedfishDataRaw -odataid $PSULink -Session $session
	"NUMERO-DE-PSUS : " + $PSUs.'Members@odata.count' >> $ficherosalida
	$PSUs | Convertto-Json -Depth 99 >> $ficherosalidaJSON
	$PSUs >> $ficherosalida
	ECHO "--------------- FIN-PSU ---------------" >> $ficherosalida
	ECHO "--------------- FIN-PSU ---------------" >> $ficherosalidaJSON

# Informacion de las LICENCIAS #(Gen10 Gen9 Gen8)
Write-Host "****** Saving Licenses info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-LICENCIAS ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-LICENCIAS ---------------" >> $ficherosalidaJSON
	$LICENCIAs = Get-HPERedfishDataRaw -odataid '/redfish/v1/Managers/1/LicenseService/' -Session $session
    foreach($Licencia in $LICENCIAs.Members.'@odata.id')
    {
        $License = Get-HPERedfishDataRaw -odataid $Licencia -Session $session
		$License | Convertto-Json -Depth 99 >> $ficherosalidaJSON
		$License.LicenseKey = $License.ConfirmationRequest.EON.LicenseKey
        $License | Select-Object -Property * >> $ficherosalida
	ECHO "+++++++++++++++" >> $ficherosalida
	}
	ECHO "--------------- FIN-LICENCIAS ---------------" >> $ficherosalida
	ECHO "--------------- FIN-LICENCIAS ---------------" >> $ficherosalidaJSON

# Extraccion de los IML #(Gen10 y Gen9)
Write-Host "****** Saving IML info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-IML ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-IML ---------------" >> $ficherosalidaJSON
	$IMLs = Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/1/LogServices/IML/Entries/' -Session $session
	if ($GENERACION -match 'Gen10')
	{#Gen10
		$IMLs.Members | ft Id, Created, EntryType,Name, Message, Severity >> $ficherosalida
		$IMLs.Members | Convertto-Json -Depth 99  >> $ficherosalidaJSON
	}
	if ($GENERACION -match 'Gen9')
	{#Gen9
		foreach($IML in $IMLs.Members.'@odata.id')
		{
			$IMLData = Get-HPERedfishDataRaw -odataid $IML -Session $session
			#Creo el tituloif
			if ($IMLData.id -match '1') # revisar para que sea exactamente 1
			{
				ECHO "Id, Created, EntryType,Name, Message, Severity " >> $ficherosalida
			}
			$IMLData | ft Id, Created, EntryType,Name, Message, Severity -HideTableHeaders >> $ficherosalida
			$IMLData | Convertto-Json -Depth 99  >> $ficherosalidaJSON
		}
	}
	if ($GENERACION -match 'Gen8')
	{#Gen9
		foreach($IML in $IMLs.Members.'@odata.id')
		{
			$IMLData = Get-HPERedfishDataRaw -odataid $IML -Session $session
			#Creo el tituloif
			if ($IMLData.id -match '1') # revisar para que sea exactamente 1
			{
				ECHO "Id, Created, EntryType,Name, Message, Severity " >> $ficherosalida
			}
			$IMLData | ft Id, Created, EntryType,Name, Message, Severity -HideTableHeaders >> $ficherosalida
			$IMLData | Convertto-Json -Depth 99  >> $ficherosalidaJSON
		}
	}
	ECHO "--------------- FIN-IML ---------------" >> $ficherosalida
	ECHO "--------------- FIN-IML ---------------" >> $ficherosalidaJSON

# Extraccion de lo ILO EVENT LOG #(Gen10 y Gen9 TARDA MUCHO)
Write-Host "****** Saving IEL info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-IEL ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-IEL ---------------" >> $ficherosalidaJSON
	$IELs = Get-HPERedfishDataRaw -odataid '/redfish/v1/Managers/1/LogServices/IEL/Entries/' -Session $session
	
	if ($GENERACION -match 'Gen10')
	{#Gen10
		$IELs.Members | ft Id, Created, EntryType,Name, Message, Severity >> $ficherosalida
		$IELs.Members | Convertto-Json -Depth 99  >> $ficherosalidaJSON
	}
#	if ($GENERACION -match 'Gen9')
#	{#Gen9
#		foreach($IEL in $IELs.Members.'@odata.id')
#		{
#			$IELData = Get-HPERedfishDataRaw -odataid $IEL -Session $session
#			#Creo el tituloif
#			if ($IELData.id -match '2') # revisar para que sea exactamente 1
#			{
#				ECHO "Id, Created, EntryType,Name, Message, Severity " >> $ficherosalida
#			}
#			$IELData | ft Id, Created, EntryType,Name, Message, Severity -HideTableHeaders >> $ficherosalida
#			$IELData | Convertto-Json -Depth 99  >> $ficherosalidaJSON
#		}
#	}
#	if ($GENERACION -match 'Gen8')
#	{#Gen8
#		foreach($IEL in $IELs.Members.'@odata.id')
#		{
#			$IELData = Get-HPERedfishDataRaw -odataid $IEL -Session $session
#			#Creo el tituloif
#			if ($IELData.id -match '2') # revisar para que sea exactamente 1
#			{
#				ECHO "Id, Created, EntryType,Name, Message, Severity " >> $ficherosalida
#			}
#			$IELData | ft Id, Created, EntryType,Name, Message, Severity -HideTableHeaders >> $ficherosalida
#			$IELData | Convertto-Json -Depth 99  >> $ficherosalidaJSON
#		}
#	}
	ECHO "--------------- FIN-IEL ---------------" >> $ficherosalida
	ECHO "--------------- FIN-IEL ---------------" >> $ficherosalidaJSON


# Informacion de los datos de red de ILO #(Gen10 y Gen9)
Write-Host "****** Saving Ilo Network info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-DATOS-ILO ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-DATOS-ILO ---------------" >> $ficherosalidaJSON
	$managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/managers/' -Session $session

    foreach($manager in $managers.members.'@odata.id') # /redfish/v1/managers/1/, /redfish/v1/managers/2/
    {
        $managerData = Get-HPERedfishDataRaw -odataid $manager -Session $session
        $nicListData = Get-HPERedfishDataRaw -odataid $managerData.EthernetInterfaces.'@odata.id' -Session $session

        foreach($nicOdataId in $nicListData.Members.'@odata.id')
		{
            $nicData = Get-HPERedfishDataRaw -odataid $nicOdataId -Session $session
			$nicData | Convertto-Json -Depth 99 >> $ficherosalidaJSON
			$nicData | fl '@odata.id', id, Name, HostName ,MACAddress, FQDN >> $ficherosalida
			$nicData.IPv4Addresses | fl AddressOrigin, Address, Gateway, SubnetMask  >> $ficherosalida
			$nicData.Status | fl State, Health  >> $ficherosalida
		}
	ECHO "+++++++++++++++" >> $ficherosalida
	}
	ECHO "--------------- FIN-DATOS-ILO ---------------" >> $ficherosalida
	ECHO "--------------- FIN-DATOS-ILO ---------------" >> $ficherosalidaJSON




#function Get-FW # FUNCIONAL GEN10 / REVISAR GEN9
Write-Host "****** Saving Firmware info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-FIRMWARE-EQUIPO ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-FIRMWARE-EQUIPO ---------------" >> $ficherosalidaJSON

	if ($GENERACION -match 'Gen10')
	{#Gen10
		$firmwares = Get-HPERedfishDataRaw -odataid $FIRMWARELink -Session $session
		foreach($firmware in $firmwares.Members.'@odata.id')
		{
			$fwData = Get-HPERedfishDataRaw -odataid $firmware -Session $session
			echo "Id, Name, Description, Version " >> $ficherosalida
			$fwData | ft Id, Name, Description, Version -HideTableHeaders >> $ficherosalida
			$fwData | Convertto-Json -Depth 99 >> $ficherosalidaJSON
		}
	}
	else
	{#Gen9 y Gen8
		$firmwares = Get-HPERedfishDataRaw -odataid $FIRMWARELink -Session $session
		# print details of all list of fw
		$firmwares.Current | Convertto-Json -Depth 99 >> $ficherosalida
		$firmwares.Current | Convertto-Json -Depth 99 >> $ficherosalidaJSON
	}

	#revisar en GEN9
	if ($GENERACION -match 'Gen9')
	{
	$softwares = Get-HPERedfishDataRaw -odataid $SOFTWAREINVENTORYLink -Session $session
	# print details of all list of fw
	$softwares.Current | Convertto-Json -Depth 99 >> $ficherosalida
	$softwares.Current | Convertto-Json -Depth 99 >> $ficherosalidaJSON
	}
	
	ECHO "--------------- FIN-FIRMWARE-EQUIPO ---------------" >> $ficherosalida
	ECHO "--------------- FIN-FIRMWARE-EQUIPO ---------------" >> $ficherosalidaJSON

Write-Host "****** Saving Devices info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-DEVICES ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-DEVICES ---------------" >> $ficherosalidaJSON

	if ($GENERACION -match 'Gen10') # revisar porque no hace bien el IF
	{
		# Gen10
		$ServerDevices = Get-HPERedfishDataRaw -odataid $DEVICESLink -Session $session
		#$ServerDevices = Get-HPERedfishDataRaw -odataid '/redfish/v1/Chassis/1/Devices/' -Session $session
	}
	if ($GENERACION -match 'Gen9') # revisar porque no hace bien el IF
	{
		# Gen9 y Gen8
		$ServerDevices = Get-HPERedfishDataRaw -odataid $PCIDEVICESLink -Session $session
	}
	if ($GENERACION -match 'Gen8') # revisar porque no hace bien el IF
	{
		# Gen9 y Gen8
		$ServerDevices = Get-HPERedfishDataRaw -odataid $PCIDEVICESLink -Session $session
	}
	
    foreach($ServerDevice in $ServerDevices.Members.'@odata.id')
    {
		ECHO "-------------- INICIO-DEVICE ------------" >> $ficherosalida
		ECHO "-------------- INICIO-DEVICE ------------" >> $ficherosalidaJSON

		$ServerDeviceData = Get-HPERedfishDataRaw -odataid $ServerDevice -Session $session
		$ServerDeviceData | Convertto-Json -Depth 99 >> $ficherosalidaJSON
#
#
#revisar porque saca iniciodevice y iniciodispositivo muchas veces
#en gen9 y gen8 es problabe que un device y dipositivo sea igual
#
#

		if ($GENERACION -match 'Gen9')#REVISARRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
		{
			ECHO " -INICIO-DISPOSITIVO- " >> $ficherosalida
			ECHO " -INICIO-DISPOSITIVO- " >> $ficherosalidaJSON
			$ServerDeviceData  | Convertto-Json -Depth 99 >> $ficherosalidaJSON
			$ServerDeviceData | fl Id, Name, StructuredName, DeviceType, DeviceLocation >> $ficherosalida
			ECHO " -FIN-DISPOSITIVO-" >> $ficherosalida
			ECHO " -FIN-DISPOSITIVO-" >> $ficherosalidaJSON
		}
#
		if ($GENERACION -match 'Gen8')#REVISARRRRRRRRRRRRRRRRRRRRRRRRRRRRRR
		{
			ECHO " -INICIO-DISPOSITIVO- " >> $ficherosalida
			ECHO " -INICIO-DISPOSITIVO- " >> $ficherosalidaJSON
			$ServerDeviceData  | Convertto-Json -Depth 99 >> $ficherosalidaJSON
			$ServerDeviceData | fl Id, Name, StructuredName, DeviceType, DeviceLocation >> $ficherosalida
			ECHO " -FIN-DISPOSITIVO-" >> $ficherosalida
			ECHO " -FIN-DISPOSITIVO-" >> $ficherosalidaJSON
		}
#
#
#
#
#
#

		if ($GENERACION -match 'Gen10')
		{
		#Exclusivo de los Gen10
		foreach($ServerDeviceDataID in $ServerDeviceData.DeviceInstances.'@odata.id')
			{
				$PCIData = Get-HPERedfishDataRaw -odataid $ServerDeviceDataID -Session $session
				ECHO " -INICIO-DISPOSITIVO- " >> $ficherosalida
				ECHO " -INICIO-DISPOSITIVO- " >> $ficherosalidaJSON
				$PCIData | Convertto-Json -Depth 99 >> $ficherosalidaJSON
				$ServerDeviceData.DeviceInstances.'@odata.id' >> $ficherosalida
				$ServerDeviceData.FirmwareVersion = $ServerDeviceData.FirmwareVersion.Current.VersionString
				$ServerDeviceData | fl Location, Name, FirmwareVersion >> $ficherosalida
				$PCIData | fl StructuredName, DeviceLocation, DeviceType, LocationString >> $ficherosalida
				ECHO " -FIN-DISPOSITIVO-" >> $ficherosalida
				ECHO " -FIN-DISPOSITIVO-" >> $ficherosalidaJSON
			}
		}
		ECHO "-------------- FIN-DEVICE ------------" >> $ficherosalida
		ECHO "-------------- FIN-DEVICE ------------" >> $ficherosalidaJSON

	}
	ECHO "--------------- FIN-DEVICES ---------------" >> $ficherosalida
	ECHO "--------------- FIN-DEVICES ---------------" >> $ficherosalidaJSON


Write-Host "****** Saving Storage info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-ALMACENAMIENTO ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-ALMACENAMIENTO ---------------" >> $ficherosalidaJSON
    # retrieve list of device fw
    $SmartArrays = Get-HPERedfishDataRaw -odataid '/redfish/v1/Systems/1/SmartStorage/ArrayControllers/' -Session $session

	foreach($SmartArray in $SmartArrays.Members.'@odata.id')
    {
	ECHO "--------------- INICIO-SMART-ARRAY ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-SMART-ARRAY ---------------" >> $ficherosalidaJSON

	ECHO "--------------- INICIO-TARJETA-SMART-ARRAY ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-TARJETA-SMART-ARRAY ---------------" >> $ficherosalidaJSON
		$Array = Get-HPERedfishDataRaw -odataid $SmartArray -Session $session
		$Array | Convertto-Json -Depth 99 >> $ficherosalidaJSON
		$Array.FirmwareVersion = $Array.FirmwareVersion.Current.VersionString
		$Array | FT Id, Model, SerialNumber,Locationformat, Location, CacheMemorySizeMiB, Firmwareversion  >> $ficherosalida

	ECHO "--------------- FIN-TARJETA-SMART-ARRAY ---------------" >> $ficherosalida
	ECHO "--------------- FIN-TARJETA-SMART-ARRAY ---------------" >> $ficherosalidaJSON

		$StorageEnclosures = Get-HPERedfishDataRaw -odataid $Array.Links.StorageEnclosures.'@odata.id' -Session $session
		$LogicalDrives = Get-HPERedfishDataRaw -odataid $Array.Links.LogicalDrives.'@odata.id' -Session $session
		$UnconfiguredDrives = Get-HPERedfishDataRaw -odataid $Array.Links.UnconfiguredDrives.'@odata.id' -Session $session
		$PhysicalDrives =  Get-HPERedfishDataRaw -odataid $Array.Links.PhysicalDrives.'@odata.id' -Session $session

		#RESUMEN DE CANTIDADES
		"SMART ARRAY                             : " + $SmartArrays.Members.'@odata.id' >> $ficherosalida
		$SmartArray >> $ficherosalida
		"NUMERO DE ENCLOSURES                    : " + $StorageEnclosures.'Members@odata.count' >> $ficherosalida
		$StorageEnclosures.Members.'@odata.id' >> $ficherosalida
		"NUMERO DISCOS LOGICOS                   : " + $LogicalDrives.'Members@odata.count' >> $ficherosalida
		$LogicalDrives.Members.'@odata.id' >> $ficherosalida
		"NUMERO DISCOS QUE NO ESTAN CONFIGURADOS : " + $UnconfiguredDrives.'Members@odata.count' >> $ficherosalida
		$UnconfiguredDrives.Members.'@odata.id' >> $ficherosalida
		"TOTAL NUMERO DISCOS FISICOS             : " + $PhysicalDrives.'Members@odata.count' >> $ficherosalida
		$PhysicalDrives.Members.'@odata.id' >> $ficherosalida
		#FIN RESUMEN DE CANTIDADES

		ECHO " -INICIO-ENCLOSURES- "  >> $ficherosalida
		ECHO " -INICIO-ENCLOSURES- "  >> $ficherosalidaJSON
		foreach($StorageEnclosure in $StorageEnclosures.Members.'@odata.id')
			{
				$Enclosure = Get-HPERedfishDataRaw -odataid $StorageEnclosure -Session $session

				ECHO " -INICIO-ENCLOSURE- "  >> $ficherosalidaJSON
				$Enclosure | Convertto-Json -Depth 99 >> $ficherosalidaJSON
				ECHO " -FIN-ENCLOSURE-" >> $ficherosalidaJSON
				
				#reasigno variables para extraccion de datos.
				$Enclosure.FirmwareVersion = $Enclosure.FirmwareVersion.Current.VersionString
				$Enclosure.Status = $Enclosure.Status.Health
				#fin
				$Enclosure | ft Id, LocationFormat, Location, Status, DriveBayCount, FirmwareVersion >> $ficherosalida
			}
		ECHO " -FIN-ENCLOSURES- "  >> $ficherosalida
		ECHO " -FIN-ENCLOSURES- "  >> $ficherosalidaJSON

	# If ($LogicalDrives'Members@odata.count' -eq 0 ) {EJECUTAR LO SIGUIENTE}
		ECHO " -INICIO-LOGICALDISK- "  >> $ficherosalida
		ECHO " -INICIO-LOGICALDISK- "  >> $ficherosalidaJSON
		foreach($LogicalDrive in $LogicalDrives.Members.'@odata.id')
			{
				$LogicalDisk = Get-HPERedfishDataRaw -odataid $LogicalDrive -Session $session
				$LogicalDiskMembers = Get-HPERedfishDataRaw -odataid $LogicalDisk.Links.DataDrives.'@odata.id' -Session $session
				"LOGICAL DRIVE : " + $LogicalDrive >> $ficherosalida
				"NUMERO DE DISCOS QUE FORMAN ESTE LOGICAL DISK : " + $LogicalDiskMembers.'Members@odata.count' >> $ficherosalida

				#MUESTRA INFORMACION DEL RAID
				$DatosLogicalDrive = Get-HPERedfishDataRaw -odataid $LogicalDrive -Session $session

				$DatosLogicalDrive | Convertto-Json -Depth 99 >> $ficherosalidaJSON
				
				$DatosLogicalDrive.Status = $DatosLogicalDrive.Status.Health
				$DatosLogicalDrive | Select-Object Id, LogicalDriveNumber, LogicalDriveType, Name, Raid, CapacityMiB, StripeSizeBytes, VolumeUniqueIdentifier, Status  >> $ficherosalida
				#FIN MUESTRA INFORMACION DEL RAID
				
				#MUESTRA LA INFORMACION DE CADA DISCO QUE FORMA EL LOGICAL DISK
				foreach($PhysicalLogicalDisk in $LogicalDiskMembers.Members.'@odata.id')
				{ #REVISAR COMO FUNCIONA Y COMO LO MUESTRA
					$PhysicalDisk = Get-HPERedfishDataRaw -odataid $PhysicalLogicalDisk -Session $session
					ECHO " -DISCO-DEL-LOGICALDISK- "  >> $ficherosalidaJSON
					$PhysicalDisk | Convertto-Json -Depth 99 >> $ficherosalidaJSON
					ECHO " -FIN-DISCO-DEL-LOGICALDISK- "  >> $ficherosalidaJSON

					#reasigno variables para extraccion de datos.
					$PhysicalDisk.FirmwareVersion = $PhysicalDisk.FirmwareVersion.Current.VersionString
					$PhysicalDisk.Status = $PhysicalDisk.Status.Health
					#fin
					#Solo muestra cabecera si es el primer disco
					If ($PhysicalDisk.Id -eq 0)
					{
						$PhysicalDisk | Select-Object Id, Model, LocationFormat, Location, InterfaceType, CapacityMiB, SerialNumber, FirmwareVersion, Status | ft >> $ficherosalida
					}
					If ($PhysicalDisk.Id -inotmatch 0)
					{
						$PhysicalDisk | Select-Object Id, Model, LocationFormat, Location, InterfaceType, CapacityMiB, SerialNumber, FirmwareVersion, Status | ft -HideTableHeaders >> $ficherosalida	
					}
				}
			}
			
		ECHO " -FIN-LOGICALDISK- "  >> $ficherosalida
		ECHO " -FIN-LOGICALDISK- "  >> $ficherosalidaJSON
		
		ECHO " -INICIO-UNMANAGEDISK- "  >> $ficherosalida
		ECHO " -INICIO-UNMANAGEDISK- "  >> $ficherosalidaJSON
		foreach($UnconfiguredDrive in $UnconfiguredDrives.Members.'@odata.id')
		{
			$PhysicalDisk = Get-HPERedfishDataRaw -odataid $UnconfiguredDrive -Session $session

			If ($PhysicalDisk.Id -eq 0)
			{
				$UnconfiguredDrives.Members. '@odata.id'>> $ficherosalida
			}

			ECHO " -INICIO-DISCOS-SIN-GESTIONAR- "  >> $ficherosalidaJSON
			$PhysicalDisk | Convertto-Json -Depth 99 >> $ficherosalidaJSON
			ECHO " -FIN-DISCOS-SIN-GESTIONAR- "  >> $ficherosalidaJSON
			
			#reasigno variables para extraccion de datos.
			$PhysicalDisk.FirmwareVersion = $PhysicalDisk.FirmwareVersion.Current.VersionString
			$PhysicalDisk.Status = $PhysicalDisk.Status.Health
			#fin
			#Solo muestra cabecera si es el primer disco
			If ($PhysicalDisk.Id -eq 0)
			{
				$PhysicalDisk | Select-Object Id, Model, LocationFormat, Location, InterfaceType, CapacityMiB, SerialNumber, FirmwareVersion, Status | ft >> $ficherosalida
			}
			If ($PhysicalDisk.Id -inotmatch 0)
			{
				$PhysicalDisk | Select-Object Id, Model, LocationFormat, Location, InterfaceType, CapacityMiB, SerialNumber, FirmwareVersion, Status | ft -HideTableHeaders >> $ficherosalida	
			}
		}
		ECHO " -FIN-UNMANAGEDISK- "  >> $ficherosalida
		ECHO " -FIN-UNMANAGEDISK- "  >> $ficherosalidaJSON

		ECHO " -INICIO-TODOS-DISCOS-FISICOS- "  >> $ficherosalida
		ECHO " -INICIO-TODOS-DISCOS-FISICOS- "  >> $ficherosalidaJSON
		foreach($ArrayPhysicalDisk in $PhysicalDrives.Members.'@odata.id')
		{

			$PhysicalDisk = Get-HPERedfishDataRaw -odataid $ArrayPhysicalDisk -Session $session
			If ($PhysicalDisk.Id -eq 0)
			{
				$PhysicalDrives.Members.'@odata.id' >> $ficherosalida
			}
			ECHO " -INICIO-DISCO-FISICO- "  >> $ficherosalidaJSON
			$PhysicalDisk | Convertto-Json -Depth 99 >> $ficherosalidaJSON
			ECHO " -FIN-DISCO-FISICO-" >> $ficherosalidaJSON

			#reasigno variables para extraccion de datos.
			$PhysicalDisk.FirmwareVersion = $PhysicalDisk.FirmwareVersion.Current.VersionString
			$PhysicalDisk.Status = $PhysicalDisk.Status.Health
			#fin
			#Solo muestra cabecera si es el primer disco
			If ($PhysicalDisk.Id -eq 0)
			{
				$PhysicalDisk | Select-Object Id, Model, LocationFormat, Location, InterfaceType, CapacityMiB, SerialNumber, FirmwareVersion, Status | ft >> $ficherosalida
			}
			If ($PhysicalDisk.Id -inotmatch 0)
			{
				$PhysicalDisk | Select-Object Id, Model, LocationFormat, Location, InterfaceType, CapacityMiB, SerialNumber, FirmwareVersion, Status | ft -HideTableHeaders >> $ficherosalida	
			}
		}
		ECHO " -FIN-TODOS-DISCOS-FISICOS- "  >> $ficherosalida
		ECHO " -FIN-TODOS-DISCOS-FISICOS- "  >> $ficherosalidaJSON

	ECHO "--------------- FIN-SMART-ARRAY ---------------" >> $ficherosalida
	ECHO "--------------- FIN-SMART-ARRAY ---------------" >> $ficherosalidaJSON

	}
	ECHO " -INICIO-NVME-DISCOS-FISICOS- "  >> $ficherosalida
	ECHO " -INICIO-NVME-DISCOS-FISICOS- "  >> $ficherosalidaJSON

	if ($DrivesNVMELink -eq 1)
		{
		}
	else
		{
		echo "- NO HAY DISCOS NVME " >> $ficherosalida
		echo "- NO HAY DISCOS NVME " >> $ficherosalidaJSON
		}
	ECHO " -FIN-NVME-DISCOS-FISICOS- "  >> $ficherosalida
	ECHO " -FIN-NVME--DISCOS-FISICOS- "  >> $ficherosalidaJSON
	
	ECHO "--------------- FIN-ALMACENAMIENTO ---------------" >> $ficherosalida
	ECHO "--------------- FIN-ALMACENAMIENTO ---------------" >> $ficherosalidaJSON
# }

#function UsbDevices # EXCLUSIVO GEN10 REVISAR
#{
Write-Host "****** Saving USBs info ******`n" -ForegroundColor Yellow
	ECHO "--------------- INICIO-USB ---------------" >> $ficherosalida
	ECHO "--------------- INICIO-USB ---------------" >> $ficherosalidaJSON

	if ($GENERACION -match 'Gen10')
	{
		$USBDevices = Get-HPERedfishDataRaw -odataid $USBDEVICESLink -Session $session
		$USBPorts = Get-HPERedfishDataRaw -odataid $USBPORTSLink  -Session $session
		#comprobar si la variable es mayor que 0
		"NUMERO-DE-USB-DEVICES : " + $USBDevices.'Members@odata.count' >> $ficherosalida
		foreach($USBDevice in $USBDevices.Members.'@odata.id')
		{
			Get-HPERedfishDataRaw -odataid $USBDevice -Session $session >> $ficherosalida
		}
		
		$USBDevices >> $ficherosalida
		$USBDevices | Convertto-Json -Depth 99 >> $ficherosalidaJSON
	
		"NUMERO-DE-USB-PORTS : " + $USBPorts.'Members@odata.count' >> $ficherosalida
		foreach($USBPort in $USBPorts.Members.'@odata.id')
		{
			$PuertoUSB = Get-HPERedfishDataRaw -odataid $USBPort -Session $session 
			$PuertoUSB | ft >> $ficherosalida
			$PuertoUSB | Convertto-Json -Depth 99 >> $ficherosalidaJSON
		}
	}
	
	ECHO "--------------- FIN-USB ---------------" >> $ficherosalida
	ECHO "--------------- FIN-USB ---------------" >> $ficherosalidaJSON
#} 

# script execution finish
	if($Error.Count -ne 0 )
    {
        Write-Host "`nScript executed with few errors. Check the log files for more information.`n" -ForegroundColor Red
    }

Write-Host "****** Script execution finished ******`n" -ForegroundColor Yellow
Write-Host "****** Created the file $ficherosalida ******" -ForegroundColor Green
Write-Host "****** Created the file $ficherosalidaJSON ******`n" -ForegroundColor Green
#-----------------------------------



function ESQUEMAS
{
	ECHO " --------------------- INICIO-ESQUEMAS -----------" >> $ficherosalida
	$schemas = Get-HPERedfishDataRaw -odataid '/redfish/v1/Schemas/' -Session $session
    foreach($schema in $schemas.members.'@odata.id')
    {
		Get-HPERedfishDataRaw -odataid $schema -Session $session >> $ficherosalida
	}
	ECHO " --------------------- FIN ESQUEMAS -----------" >> $ficherosalida
}
	
#function disconect
#{
    # Disconnect session after use
    Disconnect-HPERedfish -Session $session  
#}


