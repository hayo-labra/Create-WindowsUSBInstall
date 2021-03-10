@echo off

rem == Ask index number of image ==
type %~dp0\images.txt
set /p INDEX=Image index:

rem == Partition disk ==
diskpart /s %~dp0\partitions.txt

rem == Set high-performance power scheme to speed deployment ==
powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

rem == Apply the image to the Windows partition ==
if exist %~dp0\sources\install.swm (  
  Dism /Apply-Image /ImageFile:%~dp0\sources\install.swm /swmfile:%~dp0\sources\install*.swm /index:%INDEX% /applydir:W:\
) else (  
  dism /Apply-Image /ImageFile:%~dp0\sources\install.wim /Index:%INDEX% /ApplyDir:W:\
)

rem == Copy boot files to the System partition ==
W:\Windows\System32\bcdboot W:\Windows /s S: /f ALL