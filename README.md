# Create-WindowsUSBInstall.ps1

Skripti tekee USB-tikusta boottaavan ja kopioi sinne Windows 10 -asennuslevyn sisällön. 

## Skriptin asennus

  1. Kopioi tämän hakemiston sisältö haluamaasi sijaintiin, esimerkiksi hakemistoon C:\images.

  2. Lataa haluamasi Windows 10 -levykuva ja sijoita se samaan hakemistoon skriptin kanssa.

  3. Jos et ole vielä antanut PowerShell-skripteille suoritusoikeuksia, niin nyt on siihen hyvä aika. Lisäksi saatat joutua sallimaan ladatun allekirjoittamattoman skriptin suorituksen. Nämä tehdään esimerkiksi seuraavilla komennoilla.

     ```
     PS> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
     PS> Unblock-File C:\images\Create-WindowsUSBInstall.ps1
     ```

## Skriptin käyttö

  ![Skriptin suorittaminen](/usageanimation.gif)

  1. Skripti toimii ainoastaan pääkäyttäjän oikeuksilla, joten käynnistä PowerShell pääkäyttäjän oikeuksilla.

  2. Käynnistä skripti komennolla:

     ```
     PS> C:\images\Create-WindowsUSBInstall.ps1
     ```

  3. Valitse käytettävä USB-tikku ja ISO-levykuva. Odottele, että skripti tekee taikansa.

## Asennustikun käyttö
  
  Asennustikku toimii ihan normaalina boottaavana tikkuna. Lisäksi tikulta löytyy valmis bat-tiedosto, joka tekee levylle osioinnin ja kopioi valitsemasi jakeluversion levylle.

  USB-tikulla olevan asennusskriptin saat käynnistettyä Windowsin asennuksen komentokehotteessa, jonka saa auki näppäinyhdistelmällä Shift + F10. Skripti käynnistetään komennolla:

  ```
  X:\Sources> D:\w10install.bat 
  ```
  