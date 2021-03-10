<#
.SYNOPSIS
    Tekee boottaavan USB-tikun Windows 10 ISO-levykuvasta. 
.Description
    Skripti pyytää valitsemaan hakemistossa olevista ISO-levykuvista ja koneeseen 
    kytketyistä USB-tikuista haluamansa. Näiden valintojen perusteella skripti
    tyhjentää USB-tikun, alusta tikun FAT32-tiedostojärjestelmällä, tekee 
    siitä boottaavan ja kopioi ISO-levykuvassa olevat tiedostot USB-tikulle. 
    Lisäksi skripti kopioi bat-tiedoston, jolla Windowsin pystyy asentamaan
    komentoriviltä.
.EXAMPLE
    PS> .\Create-WindowsUSBInstall.ps1
.NOTES
    Author: Pekka Tapio Aalto
    Date:   10.3.2021
#>


#Requires -RunAsAdministrator

# Skriptin vaiheiden kokonaismäärä.
$Steps = 14

# Selvitetään mistä kansiosta skriptiä on kutsuttu.
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

# Määritellää funktio, joka tulostaa näytölle yhteinäisen 
# etenemispalkin.
function Write-ScriptProgress{
  param (
    $Step,
    $Steps,
    $CurrentOperation
  )
  $PercentComplete = ($Step/$Steps)*100
  Write-Progress -Activity "create-win10-usb-from-iso" -PercentComplete $PercentComplete -CurrentOperation $CurrentOperation
}

# Kysytään käyttäjältä käytettävä USB-tikku.
Write-ScriptProgress 1 $Steps "Valitaan käytettävä USB-tikku."
$Disk = Get-Disk | Where-Object BusType -eq USB | Out-GridView -Title 'Select USB Drive to Format' -OutputMode Single

# Tarkistetaan valittiinko prosessissa käytettävä USB-tikku.
if ( $Disk -eq $null ) {
  Write-Output "Käytettävää USB-tikkua ei valittu! Kytke koneeseen USB-tikku ja suorita komento uudelleen."
  exit
}

# Kysytään käyttäjältä käytettävä ISO-levykuva.
Write-ScriptProgress 2 $Steps "Valitaan käytettävä ISO-levykuva."
$Image = Get-Childitem $ScriptDir -filter *.iso | Out-GridView -Title 'Select ISO image' -OutputMode Single

# Tarkistetaan valittiinko prosessissa käytettävä ISO-levykuva.
if ( $Image -eq $null ) {
  Write-Output "Käytettävää ISO-levykuvaa ei valittu! Varmista, että kansiosta löytyy ISO-levykuva ja suorita komento uudelleen."
  exit
}

# Selvitetään valitun USB-tikun levynumero.
$Disknr = $Disk.DiskNumber

# Tyhjennetään USB-tikku.
Write-ScriptProgress 3 $Steps "Tyhjennetään USB-tikku"
Clear-Disk -Number $Disknr -RemoveData -RemoveOEM -Confirm:$false -PassThru 

# Luodaan USB-tikulle FAT32-osio ja asetetaan se aktiiviseksi.
Write-ScriptProgress 4 $Steps "Luodaan FAT32-osio"
$FAT = New-Partition -DiskNumber $Disknr -UseMaximumSize -IsActive -AssignDriveLetter | Format-Volume -FileSystem FAT32

# Nimetään USB-tikku 
Write-ScriptProgress 5 $Steps "Määritellään USB-tikulle nimi"
Set-Volume -DriveLetter "$($FAT.DriveLetter)" -NewFileSystemLabel "WIN10"

# Mountataan ISO-image
Write-ScriptProgress 5 $Steps "Avataan valittu ISO-levykuva"
$Volumes = (Get-Volume).Where({$_.DriveLetter}).DriveLetter
Mount-DiskImage -ImagePath $Image.FullName
$ISO = (Compare-Object -ReferenceObject $Volumes -DifferenceObject (Get-Volume).Where({$_.DriveLetter}).DriveLetter).InputObject

# Asennetaan bootsect FAT32-levylle.
Write-ScriptProgress 6 $Steps "Asennetaan boot sector"
Set-Location -Path "$($ISO):\boot"
bootsect.exe /nt60 "$($FAT.DriveLetter):"

# Kopioidaan tiedostot.
Write-ScriptProgress 7 $Steps "Kopioidaan asennuslevyllä olevat tiedostot"
$exclude = @('install.wim');
Copy-Item -Path "$($ISO):\*" -Destination "$($FAT.DriveLetter):" -Recurse -Verbose -Exclude $exclude

# Selvitetään install.wim -tiedoston polku.
$imagefile = "$($ISO):\sources\install.wim"
$file_installwim = Get-ChildItem $imagefile

# FAT32-osion tiedoston maksimikoko on 4GB - 2 tavua.
$maxsize = 4294967296 - 2; 

# Tarkistetaan install.wim-tiedoston koko. Jos koko on suurempi, mitä
# FAT32-levylle pystyy kopioimaan, niin pilkotaan tiedosto pienempiin
# osiin DISM:n avulla.
if ($file_installwim.Length -gt $maxsize) {
  Write-ScriptProgress 8 $Steps "Pilkotaan ja kopioidaan install.wim"
  $destination = "$($FAT.DriveLetter):\sources\install.swm"
  Dism /Split-Image /ImageFile:$imagefile /SWMFile:$destination /FileSize:4000
} else {
  Write-ScriptProgress 8 $Steps "Kopioidaan install.wim"
  Copy-Item -Path $imagefile -Destination "$($FAT.DriveLetter):\sources"
}

# Kopioidaan efi-boottitiedostot.
Write-ScriptProgress 9 $Steps "Kopioidaan efi-boottitiedostot"
Copy-Item -Path "$($FAT.DriveLetter):\efi\microsoft\boot\*" -Destination "$($FAT.DriveLetter):\efi\boot"
Remove-Item -Path "$($FAT.DriveLetter):\efi\boot\bootx64.efi" -Force
Copy-Item -Path "$($env:WINDIR)\Boot\EFI\bootmgfw.efi" -Destination "$($FAT.DriveLetter):\efi\boot\bootx64.efi"

# Kopioidaan asennusskriptit.
Write-ScriptProgress 10 $Steps "Kopioidaan skriptit"
$CopyPath = "$($ScriptDir)\scripts\*"
Copy-Item -Path $CopyPath -Destination "$($FAT.DriveLetter):"

# Luodaan lista tikulla asennettavista Windows-imageversioista.
Write-ScriptProgress 11 $Steps "Luodaan imagelista"
Get-WindowsImage -ImagePath $imagefile | Select-Object ImageIndex, ImageName | Out-File -FilePath "$($FAT.DriveLetter):\images.txt"

# Palataan takaisin alkuperäiseen kansioon, josta skriptiä kutsuttiin.
Write-ScriptProgress 12 $Steps "Palataan skriptikansioon"
Set-Location $ScriptDir

# Poistetaan mountattu ISO-levykuva.
Write-ScriptProgress 13 $Steps "Poistetaan ISO-levykuvan liitos"
Dismount-DiskImage -ImagePath $Image.FullName

# Poistetaan USB-tikku.
Write-ScriptProgress 14 $Steps "Kaikki valmista, poistetaan USB-tikku"
$Eject = New-Object -comObject Shell.Application
$Eject.NameSpace(17).ParseName("$($FAT.DriveLetter):").InvokeVerb("Eject")