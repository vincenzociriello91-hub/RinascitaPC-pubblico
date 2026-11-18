@echo off
:: ==========================================================================
::  RinascitaPC.bat - ottimizzazione completa per PC con Windows 10 e 11 (portatili e fissi)
::
::  All'avvio analizza il PC da solo: marca, modello, seriale, BIOS, CPU,
::  grafica, RAM, dischi, batteria, Windows, utente e connessione internet.
::  Tutte le fasi successive si adattano a quello che trova.
::
::  Cosa fa: punto di ripristino, rimozione bloatware, pulizia profonda,
::  riparazione di Windows, aggiornamento di app e driver via internet
::  (Windows Update, app ufficiale del produttore, driver grafici),
::  alternative leggere e gratuite, prestazioni e RAM, profili di
::  raffreddamento, ottimizzazione dischi, diagnostica con consigli.
::  Ogni passaggio registra il proprio esito (OK o DA CONTROLLARE) e alla
::  fine compare un riepilogo. L'opzione 13 verifica, senza modificare nulla,
::  che tutto sia andato bene. L'opzione 14 ripara da sola i punti trovati
::  dalla verifica (con i riavvii) e l'opzione 15 fa l'analisi completa del PC.
::
::  I file personali non vengono mai toccati: Documenti, Immagini, Video,
::  Musica, Desktop, Download, OneDrive, altri dischi, Cronologia file.
::
::  Cosa NON fa, di proposito: non disattiva Defender o Windows Update,
::  non aggiorna BIOS o firmware da solo (lo lascia all'app del produttore),
::  non deframmenta gli SSD, non "pulisce la RAM", non applica trucchi
::  di registro non verificati.
::
::  Alla fine di ogni lavoro salva sul Desktop un unico file
::  RinascitaPC_rapporto_DATA.txt da allegare in chat per mostrare cosa ha fatto.
::
::  Uso: doppio clic. Lo script chiede da solo i permessi di amministratore.
:: ==========================================================================
setlocal EnableExtensions
:: Se lo script parte da PowerShell 7 (es. Terminale di Windows), PSModulePath punta ai suoi
:: moduli e il PowerShell 5.1 usato qui non trova i comandi: vuota, 5.1 rimette i suoi percorsi.
set "PSModulePath="
set "VERSIONE=4.0 del 18-11-2026"
:: Invio del rapporto via internet, per i PC senza Google Drive per desktop.
:: RAPPORTO_URL = indirizzo della web app RinascitaPC_ricevitore.gs (vuoto = invio via internet spento)
set "RAPPORTO_URL=https://script.google.com/macros/s/AKfycbz5eZc7TlzV4RdVIGaoaqr5JZH05P6geqzIIAsYAzhdZAgcLLznEGbgZiFGv1hmQeRf/exec"
:: Chiave del ricevitore: vuota nel repository pubblico, viene inserita solo nella versione pubblicata.
set "RAPPORTO_KEY="
set "INIZIO=%date% %time%"
title RinascitaPC %VERSIONE% - Windows 10 e 11
:: versione sconosciuta = 99999: si prosegue, cosi' un errore di lettura non blocca lo script
set "WINBUILD=99999"
for /f "tokens=3" %%b in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| findstr /i "CurrentBuildNumber"') do set "WINBUILD=%%b"
if %WINBUILD% LSS 10240 (
    echo.
    echo  RinascitaPC funziona solo su Windows 10 e Windows 11.
    echo  Questo PC ha una versione precedente: nessuna modifica effettuata.
    pause
    exit /b
)
where powershell >nul 2>&1
if errorlevel 1 (
    echo.
    echo  PowerShell non trovato: RinascitaPC non puo' funzionare su questo PC. Nessuna modifica effettuata.
    pause
    exit /b
)
set "ARG1=%~1"
if /i not "%ARG1%"=="ripara" if /i not "%ARG1%"=="verifica" set "ARG1="
set "SELF=%~f0"
set "SELFDIR=%~dp0"
cd /d "%~dp0"

fltmc >nul 2>&1
if errorlevel 1 (
    echo.
    echo  Servono i permessi di amministratore: riavvio lo script...
    powershell -NoProfile -Command "try { if($env:ARG1){ Start-Process -FilePath $env:SELF -ArgumentList $env:ARG1 -Verb RunAs -ErrorAction Stop } else { Start-Process -FilePath $env:SELF -Verb RunAs -ErrorAction Stop } } catch { exit 1 }"
    if errorlevel 1 (
        echo  Permessi di amministratore non concessi: lo script non puo' continuare.
        pause
    )
    exit /b
)

for /f "usebackq delims=" %%d in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')" 2^>nul`) do set "DESKTOP=%%d"
if not defined DESKTOP set "DESKTOP=%USERPROFILE%\Desktop"
for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmm" 2^>nul`) do set "TS=%%t"
set "OUT=%DESKTOP%\RinascitaPC_%TS%"
if not exist "%OUT%" mkdir "%OUT%" >nul 2>&1
if not exist "%OUT%" set "OUT=%SystemDrive%\RinascitaPC_%TS%"
if not exist "%OUT%" mkdir "%OUT%" >nul 2>&1
set "LOG=%OUT%\registro.txt"
set "DRV=%SystemDrive:~0,1%"
set "UK=HKCU"
set "WG=0"
set "MODO="
set "ANNULLA="
set "RP_FATTO="
set "VUOTI=0"
set "N_OK=0"
set "N_ATT=0"
set "REGERR=0"
set "BLOATDATI='Clipchamp.Clipchamp','microsoft.windowscommunicationsapps'"
set "BLOAT='Microsoft.BingNews','Microsoft.BingWeather','Microsoft.BingSearch','Microsoft.Getstarted','Microsoft.WindowsFeedbackHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.MicrosoftOfficeHub','Microsoft.WindowsMaps','Microsoft.ZuneVideo','Microsoft.PowerAutomateDesktop','Microsoft.Todos','Microsoft.People','Microsoft.549981C3F5F10','Microsoft.Windows.DevHome','MicrosoftTeams','Microsoft.SkypeApp','Microsoft.MixedReality.Portal','Microsoft.Microsoft3DViewer','Microsoft.Messaging','Microsoft.OneConnect','Microsoft.Print3D','*CandyCrush*','*king.com*','*BubbleWitch*','*MarchofEmpires*','*Disney*','*TikTok*','*Facebook*','*Instagram*','*Twitter*','*LinkedIn*'"

call :autoaggiorna
if defined UPD_RIAVVIO exit /b
call :analisi
call :misure
if /i "%ARG1%"=="ripara" goto ripara_tutto_fase2
if /i "%ARG1%"=="verifica" goto verifica_dopo_ripara

:menu
cls
echo.
echo  ==========================================================
echo                  R I N A S C I T A   P C
echo         Ottimizzazione completa per Windows 10 e 11 - %HW_TIPOPC%
echo  ==========================================================
echo   PC rilevato : %HW_NOME%
echo   Processore  : %HW_CPU%
echo   Grafica     : %HW_GPU%
echo   RAM %HW_RAM% GB  -  Disco %HW_DISCO%  -  Internet: %HW_RETE_TXT%
if "%HW_GESTITO%"=="1" echo   ATTENZIONE: PC gestito da azienda o scuola, chiedi all'IT prima di ottimizzarlo.
if defined HW_ALTROUTENTE echo   Nota: le impostazioni personali vengono applicate all'utente %HW_ALTROUTENTE%.
echo  ==========================================================
echo.
echo    1. ESEGUI TUTTO (consigliato, 30-90 minuti)
echo.
echo    2. Crea punto di ripristino
echo    3. Rimuovi app inutili (bloatware)
echo    4. Pulizia profonda del disco
echo    5. Ripara Windows (DISM, SFC, scansione antivirus)
echo    6. Aggiorna app, Windows e driver del tuo modello (internet)
echo    7. Installa alternative leggere e gratuite (internet)
echo    8. Prestazioni, RAM e servizi
echo    9. Raffreddamento e ventola (profili CPU)
echo   10. Ottimizza dischi (TRIM su SSD, deframmentazione su HDD)
echo   11. Diagnostica hardware e consigli di potenziamento
echo   12. Apri la scheda hardware completa del PC
echo   13. VERIFICA: e' andato tutto bene? (sola lettura, consigliata dopo il riavvio)
echo   14. RIPARA TUTTO: sistema da solo i punti della verifica, riavvii compresi
echo   15. ANALISI COMPLETA del PC, hardware e software (sola lettura)
echo.
echo    0. Esci
echo.
set "SCELTA=-"
set /p "SCELTA=  Scegli un'opzione: "
set "SCELTA=%SCELTA:"=%"
:: Input finito (es. risposte da file): dopo 30 risposte vuote di fila esce invece di girare all'infinito.
if "%SCELTA%"=="-" (set /a VUOTI+=1) else (set "VUOTI=0")
if %VUOTI% GEQ 30 goto esci
call :esito_reset
if "%SCELTA%"=="1"  goto tutto
if "%SCELTA%"=="2"  (call :ripristino & goto fatto)
if "%SCELTA%"=="3"  (call :con_ripristino bloatware & goto fatto)
if "%SCELTA%"=="4"  (call :con_ripristino pulizia & goto fatto)
if "%SCELTA%"=="5"  (call :ripara & goto fatto)
if "%SCELTA%"=="6"  (call :aggiorna & goto fatto)
if "%SCELTA%"=="7"  (call :installa & goto fatto)
if "%SCELTA%"=="8"  (call :con_ripristino prestazioni & goto fatto)
if "%SCELTA%"=="9"  (call :con_ripristino raffreddamento & goto fatto)
if "%SCELTA%"=="10" (call :dischi & goto fatto)
if "%SCELTA%"=="11" (call :diagnostica & goto fatto)
if "%SCELTA%"=="12" (start "" notepad "%OUT%\analisi_hardware.txt" & goto menu)
if "%SCELTA%"=="13" (call :verifica & goto fatto)
if "%SCELTA%"=="14" goto ripara_tutto
if "%SCELTA%"=="15" (call :analisi_completa & goto fatto)
if "%SCELTA%"=="0"  goto esci
goto menu

:fatto
set "MODO="
set "ANNULLA="
call :esito_riepilogo
call :rapporto
echo.
pause
goto menu

:esci
call :rapporto
if exist "%REPORT%" start "" explorer /select,"%REPORT%"
endlocal
exit /b 0

:: ==========================================================================
:tutto
cls
echo.
echo  MODALITA' COMPLETA - prima di iniziare:
if "%HW_PORTATILE%"=="1" (echo    - collega il caricabatterie e resta connesso a internet) else (echo    - resta connesso a internet)
echo    - chiudi i programmi e salva i documenti aperti
echo    - durata: da 30 a 90 minuti (riparazione, driver e dischi sono le fasi lunghe)
echo    - viene creato un punto di ripristino per poter tornare indietro
echo    - i tuoi file personali (Documenti, Immagini, Video, Desktop, Download,
echo      OneDrive) non vengono toccati
if "%HW_GESTITO%"=="1" echo    - ATTENZIONE: questo PC e' gestito da azienda o scuola
echo.
powershell -NoProfile -Command "$b=Get-CimInstance Win32_Battery | Select-Object -First 1; if($b -and $b.BatteryStatus -in 1,4,5){ exit 1 }"
if errorlevel 1 echo   ATTENZIONE: il portatile sta andando a batteria. Collega il caricabatterie.
echo.
choice /c SN /m "  Iniziare"
if errorlevel 2 goto menu
set "MODO=TUTTO"
call :log "=== AVVIO MODALITA' COMPLETA su %HW_NOME% ==="
call :ripristino
if defined ANNULLA (set "ANNULLA=" & set "MODO=" & call :rapporto & goto menu)
call :bloatware
call :pulizia
call :ripara
call :aggiorna
call :installa
call :prestazioni
call :raffreddamento
call :dischi
call :diagnostica
call :log "=== OTTIMIZZAZIONE COMPLETATA ==="
set "MODO="
call :esito_riepilogo
echo.
echo  ==========================================================
echo   Fatto. Riavvia il PC per applicare tutte le modifiche.
echo   Dopo il riavvio avvia di nuovo lo script e scegli 13 per la verifica finale.
echo  ==========================================================
echo.
choice /c SN /t 60 /d N /m "  Riavviare ora (No automatico tra 60 s)"
if errorlevel 2 goto tutto_dopo
call :log "Riavvio del PC tra 15 secondi: dopo il riavvio trovi il rapporto sul Desktop"
call :rapporto
shutdown /r /t 15 /c "RinascitaPC: riavvio per completare l'ottimizzazione"
exit /b
:tutto_dopo
call :log "Riavvio rimandato"
call :rapporto
if exist "%REPORT%" start "" explorer /select,"%REPORT%"
echo.
pause
goto menu

:: ==========================================================================
:titolo
echo.
echo  ----------------------------------------------------------
echo   %~1
echo  ----------------------------------------------------------
>>"%LOG%" echo.
>>"%LOG%" echo [%date% %time%] ### %~1
exit /b

:log
echo   ^> %~1
>>"%LOG%" echo [%date% %time%] %~1
exit /b

:logfile
>>"%LOG%" echo [%date% %time%] %~1
exit /b

:esito
if /i "%~2"=="OK" goto esito_ok
set /a N_ATT+=1
call :log "DA CONTROLLARE - %~1: %~3"
>>"%ESITI%" echo   - %~1: %~3
exit /b
:esito_ok
set /a N_OK+=1
call :log "OK - %~1: %~3"
exit /b

:esito_winget
if "%~2"=="0" (call :esito "%~1" OK "fatto" & exit /b)
if "%~2"=="-1978335135" (call :esito "%~1" OK "era gia' installato" & exit /b)
if "%~2"=="-1978335189" (call :esito "%~1" OK "era gia' aggiornato" & exit /b)
if "%~2"=="-1978335188" (call :esito "%~1" ATT "alcune app non si sono aggiornate: chiudile e ripeti l'opzione 6" & exit /b)
call :esito "%~1" ATT "errore, codice %~2: riprova piu' tardi"
exit /b

:esito_reset
set "N_OK=0"
set "N_ATT=0"
if defined ESITI del "%ESITI%" >nul 2>&1
exit /b

:esito_riepilogo
set /a N_TOT=N_OK+N_ATT
if %N_TOT% EQU 0 exit /b
echo.
echo  ==========================================================
echo   ESITO: %N_OK% passaggi riusciti, %N_ATT% da controllare
if %N_ATT% GTR 0 type "%ESITI%"
if %N_ATT% EQU 0 echo   Tutto e' andato a buon fine.
echo  ==========================================================
call :logfile "RIEPILOGO: %N_OK% passaggi riusciti, %N_ATT% da controllare"
exit /b

:rapporto
if not defined REPORT exit /b
set "PS=$ErrorActionPreference='SilentlyContinue'; $o=New-Object Collections.Generic.List[string]; function Sez($t){ $o.Add(''); $o.Add('=' * 72); $o.Add('  ' + $t); $o.Add('=' * 72) }; function Fil($t,$f){ if($f -and (Test-Path -LiteralPath $f)){ Sez $t; foreach($x in Get-Content -LiteralPath $f){ $o.Add([string]$x) } } }"
set "PS=%PS%; $o.Add('RAPPORTO RinascitaPC ' + $env:VERSIONE + ' - da allegare in chat'); $o.Add('Creato il ' + (Get-Date -Format 'dd-MM-yyyy HH:mm') + ' - sessione iniziata il ' + $env:INIZIO); $o.Add('PC: ' + $env:HW_NOME + ' - ' + $env:HW_WIN); $o.Add('CPU: ' + $env:HW_CPU + ' - Grafica: ' + $env:HW_GPU); $o.Add('RAM: ' + $env:HW_RAM + ' GB - Disco: ' + $env:HW_DISCO + ' - Batteria: ' + $env:HW_BATTTXT + ' - Internet: ' + $env:HW_RETE_TXT); if($env:HW_GESTITO -eq '1'){ $o.Add('PC gestito da azienda o scuola') }; if($env:HW_ALTROUTENTE){ $o.Add('Avviato da un altro amministratore, impostazioni applicate all''utente ' + $env:HW_ALTROUTENTE) }"
set "PS=%PS%; $r=@(); if(Test-Path -LiteralPath $env:LOG){ $r=@(Get-Content -LiteralPath $env:LOG) }; Sez 'RIEPILOGO'; $sum=@($r | Where-Object { $_ -match 'RIEPILOGO: |VERIFICA: |=== ' }); $att=@($r | Where-Object { $_ -cmatch '\] DA CONTROLLARE - ' }); if($sum.Count -eq 0){ $o.Add('Nessuna operazione completata in questa sessione') } else { foreach($x in $sum){ $o.Add($x) } }; if($att.Count -gt 0){ $o.Add(''); $o.Add('Punti da controllare:'); foreach($x in $att){ $o.Add($x) } } else { $o.Add('Nessun passaggio da controllare') }"
set "PS=%PS%; Fil 'REGISTRO COMPLETO DELLE OPERAZIONI' $env:LOG; Fil 'VERIFICA - OPZIONE 13' (Join-Path $env:OUT 'verifica.txt'); Fil 'ANALISI COMPLETA - OPZIONE 15' (Join-Path $env:OUT 'analisi_completa.txt'); Fil 'PRIMA E DOPO' (Join-Path $env:OUT 'misure.txt'); Fil 'DIAGNOSTICA HARDWARE E CONSIGLI' (Join-Path $env:OUT 'diagnostica.txt'); Fil 'SCHEDA HARDWARE' (Join-Path $env:OUT 'analisi_hardware.txt'); Sez 'FILE DELLA SESSIONE'; $o.Add('Cartella: ' + $env:OUT); foreach($f in Get-ChildItem -LiteralPath $env:OUT -File){ $o.Add('  ' + $f.Name + ' - ' + [math]::Ceiling($f.Length/1KB) + ' KB') }"
set "PS=%PS%; $t=$o -join [Environment]::NewLine; $sn=[string]$env:HW_SERIALE; if($sn.Length -gt 4){ $t=$t.Replace($sn, ('*' * ($sn.Length - 4)) + $sn.Substring($sn.Length - 4)) }; [IO.File]::WriteAllText($env:REPORT, $t + [Environment]::NewLine, (New-Object Text.UTF8Encoding($true))); if(Test-Path -LiteralPath $env:REPORT){ exit 0 }; exit 1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%"
if errorlevel 1 (echo   Rapporto non creato: controlla lo spazio libero sul disco.& exit /b)
echo.
echo  ==========================================================
echo   RAPPORTO DA CONDIVIDERE IN CHAT:
echo   "%REPORT%"
echo   Allega questo file: dentro c'e' tutto quello che ha fatto lo script.
echo  ==========================================================
:: shortcut: il disco virtuale di Drive di un altro utente puo' non essere visibile da qui; resta la cartella in modalita' mirror
powershell -NoProfile -Command "$r=@(); foreach($d in [IO.DriveInfo]::GetDrives()){ foreach($n in 'Il mio Drive','My Drive'){ $r+=Join-Path $d.Name $n } }; foreach($u in @($env:USERPROFILE, $env:HW_PROFILO)){ if($u){ foreach($n in 'Il mio Drive','My Drive','Google Drive\Il mio Drive','Google Drive\My Drive'){ $r+=Join-Path $u $n } } }; $g=$r | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1; if(-not $g){ exit 1 }; $dst=Join-Path $g 'RinascitaPC\rapporti'; try { New-Item -ItemType Directory -Force -Path $dst -ErrorAction Stop | Out-Null; Copy-Item -LiteralPath $env:REPORT -Destination $dst -Force -ErrorAction Stop; Write-Host ('   Inviato su Google Drive: ' + $dst); exit 0 } catch { exit 2 }"
set "RC=%errorlevel%"
if "%RC%"=="0" goto rapporto_inviato
if not defined RAPPORTO_URL goto rapporto_noinvio
if not "%HW_RETE%"=="1" goto rapporto_noinvio
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $b=@{ k=$env:RAPPORTO_KEY; n=($env:COMPUTERNAME + '_' + [IO.Path]::GetFileName($env:REPORT)); r=[IO.File]::ReadAllText($env:REPORT) }; $x=Invoke-WebRequest -Uri $env:RAPPORTO_URL -Method Post -Body $b -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop; $c=$x.Content; if($c -is [byte[]]){ $c=[Text.Encoding]::UTF8.GetString($c) }; if([string]$c -match '^ok'){ exit 0 }; exit 2 } catch { exit 2 }"
if errorlevel 1 goto rapporto_noinvio
echo   Inviato a Claude via internet.
:rapporto_inviato
echo   Non serve allegarlo: scrivimi in chat "leggi il rapporto RinascitaPC".
exit /b
:rapporto_noinvio
echo   Invio automatico non riuscito: allega il file a mano.
exit /b

:sfc_inizio
set "SFCSTART="
for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "(Get-Date).AddSeconds(-5).ToString('yyyy-MM-dd HH:mm:ss')" 2^>nul`) do set "SFCSTART=%%t"
exit /b

:sfc_esito
set "PS=function LogR($x){ if($env:LOG){ try { Add-Content -LiteralPath $env:LOG -Value $x -Encoding ASCII -ErrorAction Stop } catch {} } }; $s=[string]$env:SFCSTART; if(-not $s){ exit 3 }; $p=Join-Path $env:SystemRoot 'Logs\CBS\CBS.log'; $bad=0; $cor=0; $fix=0; $done=0; $det=New-Object Collections.Generic.List[string]"
set "PS=%PS%; try { $fs=[IO.File]::Open($p,'Open','Read','ReadWrite'); $sr=New-Object IO.StreamReader($fs); while($null -ne ($l=$sr.ReadLine())){ if($l.Length -lt 19){ continue }; if([string]::CompareOrdinal($l.Substring(0,19),$s) -lt 0){ continue }; if($l -notmatch '\[SR\]|\[Pnp\]'){ continue }; $k=0; if($l -match 'Cannot repair member file|Unable to repair|Could not reproject corrupted file|Failed repairing file: |Cannot verify component files for|Failed verifying file: '){ $bad++; $k=1 } elseif($l -match 'Corrupt file: '){ $cor++; $k=1 } elseif($l -match 'Repaired file|Repairing corrupted file'){ $fix++; $k=1 }; if($k -and $det.Count -lt 25){ $det.Add(($l -replace '^.*\[(SR|Pnp)\] ','').Trim()) }; if($l -match '\[SR\] (Verify|Repair) complete'){ $done++ } }; $sr.Close() } catch { exit 3 }"
set "PS=%PS%; if($env:LOG){ foreach($x in $det){ LogR ('    SFC: ' + $x) } }; if($bad -gt 0 -or $cor -gt $fix){ exit 2 }; if($done -eq 0){ exit 3 }; if($fix -gt 0){ exit 1 }; exit 0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%"
set "SFCRC=%errorlevel%"
exit /b

:spazio
for /f "usebackq delims=" %%s in (`powershell -NoProfile -Command "[int64]((Get-PSDrive $env:DRV).Free/1MB)" 2^>nul`) do set "SPAZIO_%~1=%%s"
exit /b

:winget_check
set "WG=0"
where winget >nul 2>&1 && (set "WG=1" & exit /b)
powershell -NoProfile -Command "Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction SilentlyContinue" >nul 2>&1
where winget >nul 2>&1 && set "WG=1"
if "%WG%"=="0" call :log "winget non disponibile: installa o aggiorna 'Programma di installazione app' dal Microsoft Store"
exit /b

:: ==========================================================================
:autoaggiorna
:: Controlla sulla web app se esiste una versione piu' nuova. Non cambia nulla senza il tuo Si.
set "UPD_RIAVVIO="
if not defined RAPPORTO_URL exit /b
set "UPDINFO=%TEMP%\RinascitaPC_aggiornamento.txt"
set "UPDNEW=%TEMP%\RinascitaPC_nuova_versione.bat"
del "%UPDINFO%" >nul 2>&1
echo.
echo  Controllo se esiste una versione piu' nuova di RinascitaPC...
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $c=(Invoke-WebRequest -Uri ($env:RAPPORTO_URL + '?a=info') -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop).Content; if($c -is [byte[]]){ $c=[Text.Encoding]::UTF8.GetString($c) }; $p=([string]$c).Trim().Split('|'); if($p.Count -ne 2){ exit 1 }; if([version]$p[0] -le [version]($env:VERSIONE.Split(' ')[0])){ exit 1 }; Set-Content -LiteralPath $env:UPDINFO -Value ($p[0] + '|' + $p[1]) -Encoding ASCII; exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 exit /b
set "UPDVER="
for /f "usebackq tokens=1 delims=|" %%v in ("%UPDINFO%") do set "UPDVER=%%v"
echo.
echo  E' disponibile RinascitaPC %UPDVER%. Tu stai usando la %VERSIONE%.
echo  La versione attuale resta salvata come copia di sicurezza accanto allo script.
choice /c SN /t 20 /d N /m "  Aggiornare ora (No automatico tra 20 s)"
if errorlevel 2 exit /b
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $i=(Get-Content -LiteralPath $env:UPDINFO -TotalCount 1).Split('|'); $c=(Invoke-WebRequest -Uri ($env:RAPPORTO_URL + '?a=file') -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop).Content; if($c -is [byte[]]){ $c=[Text.Encoding]::UTF8.GetString($c) }; [IO.File]::WriteAllText($env:UPDNEW, [string]$c, [Text.Encoding]::ASCII); if((Get-FileHash -LiteralPath $env:UPDNEW -Algorithm SHA256).Hash -ne $i[1]){ exit 2 }; $t=[IO.File]::ReadAllText($env:UPDNEW); if(-not $t.StartsWith('@echo off') -or -not $t.Contains('set ' + [char]34 + 'VERSIONE=' + $i[0] + ' ')){ exit 2 }; Copy-Item -LiteralPath $env:SELF -Destination ($env:SELF -replace '\.bat$','_precedente.bat') -Force -ErrorAction Stop; exit 0 } catch { Write-Host ('  Dettaglio: ' + $_.Exception.Message); exit 3 }"
set "RC=%errorlevel%"
if "%RC%"=="2" (echo   Download non integro: aggiornamento annullato, continuo con la versione attuale.& exit /b)
if not "%RC%"=="0" (echo   Aggiornamento non riuscito: continuo con la versione attuale.& exit /b)
echo   Aggiornamento verificato. RinascitaPC si riavvia con la nuova versione...
:: la sostituzione avviene 2 secondi dopo l'uscita: un file .bat non va mai sovrascritto mentre e' in esecuzione
start "" powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Seconds 2; Copy-Item -LiteralPath $env:UPDNEW -Destination $env:SELF -Force; Start-Process -FilePath $env:SELF"
set "UPD_RIAVVIO=1"
exit /b

:: ==========================================================================
:misure
:: Elenco dei programmi all'avvio (chiavi Run, cartelle Esecuzione automatica, app dello Store):
:: lo usano le misure e la disattivazione automatica in :prestazioni.
set "PSAV=$ErrorActionPreference='SilentlyContinue'; function LogR($x){ if($env:LOG){ try { Add-Content -LiteralPath $env:LOG -Value $x -Encoding ASCII -ErrorAction Stop } catch {} } }; $hk='Registry::HKEY_CURRENT_USER'; $hc=$hk + '\Software\Classes'; if($env:UK -like 'HKU\*'){ $sid=$env:UK.Substring(4); $hk='Registry::HKEY_USERS\' + $sid; $hc=$hk + '_Classes' }; $lm='Registry::HKEY_LOCAL_MACHINE\SOFTWARE'; $cv='\Microsoft\Windows\CurrentVersion'; $sa=$cv + '\Explorer\StartupApproved\'"
set "PSAV=%PSAV%; function Voci { $v=@(); foreach($r in @(@(($hk + '\Software' + $cv + '\Run'),($hk + '\Software' + $sa + 'Run')),@(($lm + $cv + '\Run'),($lm + $sa + 'Run')),@(($lm + '\WOW6432Node' + $cv + '\Run'),($lm + $sa + 'Run32')))){ $p=Get-ItemProperty -LiteralPath $r[0]; if($p){ foreach($x in $p.PSObject.Properties){ if($x.Name -notmatch '^PS(Path|ParentPath|ChildName|Drive|Provider)$'){ $v+=[pscustomobject]@{N=$x.Name; C=[string]$x.Value; A=$r[1]; T='R'; S=0} } } } }"
set "PSAV=%PSAV%; $us=[Environment]::GetFolderPath('Startup'); if($env:HW_PROFILO){ $us=Join-Path $env:HW_PROFILO 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup' }; foreach($f in @(@($us,($hk + '\Software' + $sa + 'StartupFolder')),@([Environment]::GetFolderPath('CommonStartup'),($lm + $sa + 'StartupFolder')))){ if($f[0]){ foreach($x in @(Get-ChildItem -LiteralPath $f[0] -File | Where-Object { $_.Name -ne 'desktop.ini' })){ $c=''; if($x.Extension -eq '.lnk'){ try { $c=(New-Object -ComObject WScript.Shell).CreateShortcut($x.FullName).TargetPath } catch {} }; $v+=[pscustomobject]@{N=$x.Name; C=[string]$c; A=$f[1]; T='R'; S=0} } } }"
set "PSAV=%PSAV%; foreach($pk in @(Get-ChildItem -LiteralPath ($hc + '\Local Settings\Software' + $cv + '\AppModel\SystemAppData'))){ foreach($t in @(Get-ChildItem -LiteralPath $pk.PSPath)){ $st=(Get-ItemProperty -LiteralPath $t.PSPath).State; if($null -ne $st){ $v+=[pscustomobject]@{N=$pk.PSChildName; C=$t.PSChildName; A=$t.PSPath; T='S'; S=[int]$st} } } };@($v | Where-Object { $_.N }) }"
set "PSAV=%PSAV%; function Spento($x){ if($x.T -eq 'S'){ return ($x.S -ne 2 -and $x.S -ne 4) }; $b=(Get-ItemProperty -LiteralPath $x.A -Name $x.N).($x.N); return [bool]($b -and ($b[0] -band 1)) }; $tieni='(?i)securityhealth|defender|msmpeng|antivir|avast|\bavg\b|avira|kaspersky|\bavp\b|\beset\b|ekrn|egui|norton|symantec|mcafee|bitdefender|malwarebytes|mbam|sophos|trend ?micro|panda|webroot|f-secure|comodo|realtek|\brtk|rthdvcpl|waves|maxxaudio|dolby|nahimic|sonic|igfx|intel|nvidia|\bamd\b|radeon|synaptics|syntp|\belan|\betd|alps|touchpad|logi|razer|corsair|steelseries|bluetooth|wacom|fingerprint|hotkey|thunderbolt|conexant|\bidt\b|audio|onedrive|googledrive|google drive|drivefs|dropbox|icloud|megasync|bitwarden|1password|keepass|lastpass|dashlane|vpn|wireguard|nordvpn|proton|anyconnect|globalprotect|forti|teamviewer|anydesk|ctfmon|narrator|magnify|\bosk\b|bitlocker|acronis|macrium|veeam|backblaze|rinascita|\basus|armoury|lenovo|vantage|\bdell\b|\bhp\b|hpcommand|\bacer\b|\bmsi\b|printer|epson|canon|brother'"
:: Fotografia del PC a ogni avvio, salvata in %ProgramData%\RinascitaPC\misure.csv:
:: il rapporto la confronta con la prima misura, cosi' si vede quanto e' migliorato.
set "PS=%PSAV%; $ic=[Globalization.CultureInfo]::InvariantCulture; $os=Get-CimInstance Win32_OperatingSystem; $ram=[double][math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory)/1MB,1); $v=Get-Volume -DriveLetter $env:DRV; $free=[double][math]::Round($v.SizeRemaining/1GB,1); $st=@(Voci | Where-Object { -not (Spento $_) }).Count; $pr=@(Get-Process).Count; $boot=''"
set "PS=%PS%; $e=Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnostics-Performance/Operational'; Id=100} -MaxEvents 1; if($e){ $bt=(([xml]$e.ToXml()).Event.EventData.Data | Where-Object { $_.Name -eq 'BootTime' }).'#text'; if($bt){ $boot=[math]::Round([double]$bt/1000,1) } }"
set "PS=%PS%; $now=@($boot,$ram,$free,$st,$pr); $val=@($now | ForEach-Object { if($_ -is [double]){ $_.ToString('0.0',$ic) } else { [string]$_ } }); $dir=Join-Path $env:ProgramData 'RinascitaPC'; New-Item -ItemType Directory -Force -Path $dir | Out-Null; $csv=Join-Path $dir 'misure.csv'; $first=$null; if(Test-Path -LiteralPath $csv){ $first=Get-Content -LiteralPath $csv | Where-Object { $_ -match '^\d{4}-' } | Select-Object -First 1 }; Add-Content -LiteralPath $csv -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm') + ';' + ($val -join ';')) -Encoding ASCII"
set "PS=%PS%; $nomi=@('Avvio di Windows, secondi','RAM occupata, GB','Spazio libero disco di sistema, GB','Programmi all''avvio','Processi attivi'); $giu=@($true,$true,$false,$true,$true); $o=@('Misure prese all''avvio di RinascitaPC il ' + (Get-Date -Format 'dd-MM-yyyy HH:mm'))"
set "PS=%PS%; if(-not $first){ $o+='Prima misura salvata su questo PC: il confronto prima/dopo comparira'' dalla prossima volta, meglio dopo un riavvio.'; for($i=0; $i -lt 5; $i++){ $o+=('  ' + $nomi[$i].PadRight(38) + $(if($val[$i]){ $val[$i] } else { 'n.d.' })) } } else { $p=$first.Split(';'); $o+=('Confronto con la prima misura su questo PC, del ' + $p[0] + ':'); for($i=0; $i -lt 5; $i++){ $a=0.0; $b=0.0; if([double]::TryParse([string]$p[$i+1],[Globalization.NumberStyles]::Float,$ic,[ref]$a) -and [double]::TryParse([string]$val[$i],[Globalization.NumberStyles]::Float,$ic,[ref]$b)){ $d=[math]::Round($b-$a,1); $g=if($d -eq 0){'uguale'} elseif(($d -lt 0) -eq $giu[$i]){'meglio'} else {'peggio'}; $o+=('  ' + $nomi[$i].PadRight(38) + $p[$i+1] + ' -> ' + $val[$i] + '   (' + $(if($d -gt 0){'+'}else{''}) + $d.ToString('0.0',$ic) + ', ' + $g + ')') } else { $o+=('  ' + $nomi[$i].PadRight(38) + 'n.d.') } } }; Set-Content -LiteralPath (Join-Path $env:OUT 'misure.txt') -Value $o -Encoding ASCII"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%" >nul 2>&1
exit /b

:: ==========================================================================
:analisi
echo.
echo  Analizzo il PC e verifico la connessione a internet...
for %%v in (NOME MARCA MODELLO TIPO SERIALE BIOS BIOSDATA BIOSANNI CPU GPU GPUNV GPUAMD INTEL RAM RAMMOD RAMSLOT DISCO BATT BATTPRES WIN GESTITO ALTROUTENTE ALTROSID UTEMP PROFILO PORTATILE RETE) do set "HW_%%v="
set "PS=$ErrorActionPreference='SilentlyContinue'; function C($v){ ([string]$v -replace '\((R|TM|C)\)','' -replace '[\x28\x29]',' ' -replace '[\x22\x25\x26\x3C\x3E\x5E\x7C\x21\x3D]','' -replace '\s+',' ').Trim() }"
set "PS=%PS%; $cs=Get-CimInstance Win32_ComputerSystem; $csp=Get-CimInstance Win32_ComputerSystemProduct; $bios=Get-CimInstance Win32_BIOS; $cpu=Get-CimInstance Win32_Processor | Select-Object -First 1; $marca=C $cs.Manufacturer; $tipo=C $cs.Model; $mod=$tipo; if($marca -match 'LENOVO' -and $csp.Version){ $mod=C $csp.Version }"
set "PS=%PS%; $g=@(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Basic|Remote|Virtual|Mirror|DisplayLink|Meta' }); $gn=($g | ForEach-Object { C $_.Name }) -join ' + '; $nv=[int]($gn -match 'NVIDIA'); $amd=[int]($gn -match 'AMD|Radeon'); $intel=[int](($gn -match 'Intel') -or ($cpu.Manufacturer -match 'Intel'))"
set "PS=%PS%; $mods=@(Get-CimInstance Win32_PhysicalMemory); $ram=[math]::Round(($mods | Measure-Object -Property Capacity -Sum).Sum/1GB); if(-not $ram){ $ram=[math]::Round($cs.TotalPhysicalMemory/1GB) }; $slot=(Get-CimInstance Win32_PhysicalMemoryArray | Where-Object { $_.Use -eq 3 } | Measure-Object -Property MemoryDevices -Sum).Sum; if(-not $slot){ $slot=$mods.Count }"
set "PS=%PS%; $pd=@(Get-PhysicalDisk | Where-Object { $_.BusType -notmatch 'USB' }); $hdd=@($pd | Where-Object { $_.MediaType -eq 'HDD' }).Count; $ssd=@($pd | Where-Object { $_.MediaType -eq 'SSD' -or $_.BusType -eq 'NVMe' }).Count; $disco=if($hdd -and $ssd){'SSD + HDD'}elseif($hdd){'HDD'}elseif($ssd){'SSD'}elseif($pd.Count){'tipo non indicato'}else{'non rilevato'}"
set "PS=%PS%; $bs=Get-CimInstance -Namespace root/wmi -ClassName BatteryStaticData | Select-Object -First 1; $bf=Get-CimInstance -Namespace root/wmi -ClassName BatteryFullChargedCapacity | Select-Object -First 1; $bat=''; if($bs.DesignedCapacity -gt 0 -and $bf.FullChargedCapacity -gt 0){ $bat=[math]::Round(100*$bf.FullChargedCapacity/$bs.DesignedCapacity) }; $bp=[int](@(Get-CimInstance Win32_Battery).Count -gt 0); if(-not $bat){ $bx=Join-Path $env:TEMP 'rinascitapc_batt.xml'; powercfg /batteryreport /xml /output $bx | Out-Null; if(Test-Path -LiteralPath $bx){ $b1=([xml](Get-Content -LiteralPath $bx -Raw)).BatteryReport.Batteries.Battery | Select-Object -First 1; if($b1 -and [double]$b1.DesignCapacity -gt 0 -and [double]$b1.FullChargeCapacity -gt 0){ $bat=[math]::Round(100*[double]$b1.FullChargeCapacity/[double]$b1.DesignCapacity); $bp=1 }; Remove-Item -LiteralPath $bx -Force } }"
set "PS=%PS%; $bd=''; $ba=0; if($bios.ReleaseDate){ $bd=$bios.ReleaseDate.ToString('dd-MM-yyyy'); $ba=[int][math]::Floor(((Get-Date)-$bios.ReleaseDate).TotalDays/365) }; $os=Get-CimInstance Win32_OperatingSystem; $dv=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').DisplayVersion; $win=C ($os.Caption + ' ' + $dv + ' build ' + $os.BuildNumber)"
set "PS=%PS%; $gest=[int](($cs.PartOfDomain -eq $true) -or [bool](Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' | Where-Object { (Get-ItemProperty -LiteralPath $_.PSPath).ProviderID -eq 'MS DM Server' }))"
set "PS=%PS%; $ex=Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'explorer.exe' } | Select-Object -First 1; $ou=''; $osid=''; $ut=''; $pp=''; if($ex){ $ou=[string](Invoke-CimMethod -InputObject $ex -MethodName GetOwner).User; $osid=[string](Invoke-CimMethod -InputObject $ex -MethodName GetOwnerSid).Sid }; if($ou -and $osid -and ($ou -ne $env:USERNAME)){ $pp=(Get-ItemProperty -LiteralPath ('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' + $osid)).ProfileImagePath; if($pp){ $ut=([string]$pp).TrimEnd('\') + '\AppData\Local\Temp' } } else { $ou=''; $osid='' }"
set "PS=%PS%; $net=0; @('http://www.msftconnecttest.com/connecttest.txt','https://www.microsoft.com') | ForEach-Object { if(-not $net){ try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $null=Invoke-WebRequest -Uri $_ -Method Head -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop; $net=1 } catch {} } }"
set "PS=%PS%; $mb=$marca; $hit=@('Lenovo','ASUS','Dell','Acer','MSI','HP','Samsung','Huawei','Microsoft','Toshiba','Dynabook','Fujitsu','Medion','Xiaomi','Honor','Razer','Gigabyte','Framework') | Where-Object { $marca -match $_ } | Select-Object -First 1; if($hit){ $mb=$hit }; if($marca -match 'Hewlett'){ $mb='HP' }; if($marca -match 'Micro-Star'){ $mb='MSI' }; $nome=if($mod -like ($mb + ' *')){ $mod } else { ($mb + ' ' + $mod).Trim() }; $res=@(('NOME=' + $nome), ('MARCA=' + $marca), ('MODELLO=' + $mod), ('TIPO=' + $tipo), ('SERIALE=' + (C $bios.SerialNumber)), ('BIOS=' + (C $bios.SMBIOSBIOSVersion)), ('BIOSDATA=' + $bd), ('BIOSANNI=' + $ba), ('CPU=' + (C $cpu.Name)), ('GPU=' + $gn), ('GPUNV=' + $nv), ('GPUAMD=' + $amd), ('INTEL=' + $intel), ('RAM=' + $ram), ('RAMMOD=' + $mods.Count), ('RAMSLOT=' + $slot), ('DISCO=' + $disco), ('BATT=' + $bat), ('BATTPRES=' + $bp), ('WIN=' + $win), ('GESTITO=' + $gest), ('ALTROUTENTE=' + (C $ou)), ('ALTROSID=' + (C $osid)), ('UTEMP=' + $ut), ('PROFILO=' + $pp), ('PORTATILE=' + [int]((@(Get-CimInstance Win32_Battery | Where-Object { $_ }).Count -gt 0) -or ($cs.PCSystemType -eq 2))), ('RETE=' + $net)); Set-Content -LiteralPath (Join-Path $env:OUT 'hw.tmp') -Value $res -Encoding ASCII"
del "%OUT%\hw.tmp" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%" >nul 2>&1
if exist "%OUT%\hw.tmp" for /f "usebackq tokens=1* delims==" %%a in ("%OUT%\hw.tmp") do set "HW_%%a=%%b"
del "%OUT%\hw.tmp" >nul 2>&1
if not defined HW_RAM set "HW_RAM=0"
if not defined HW_RETE set "HW_RETE=0"
if "%HW_PORTATILE%"=="1" (set "HW_TIPOPC=portatile") else (set "HW_TIPOPC=PC fisso")
if "%HW_RETE%"=="1" (set "HW_RETE_TXT=si") else (set "HW_RETE_TXT=NO")
set "HW_BATTTXT=assente"
if "%HW_PORTATILE%"=="1" set "HW_BATTTXT=non rilevata da Windows"
if "%HW_BATTPRES%"=="1" set "HW_BATTTXT=presente, salute non leggibile"
if defined HW_BATT set "HW_BATTTXT=salute %HW_BATT% percento"
set "UK=HKCU"
if defined HW_ALTROSID set "UK=HKU\%HW_ALTROSID%"

set "PS=$ErrorActionPreference='SilentlyContinue'; $cs=Get-CimInstance Win32_ComputerSystem; $csp=Get-CimInstance Win32_ComputerSystemProduct; $bios=Get-CimInstance Win32_BIOS; $os=Get-CimInstance Win32_OperatingSystem; $o=@('SCHEDA HARDWARE - RinascitaPC', ('Creata il ' + (Get-Date -Format 'dd-MM-yyyy HH:mm')), '')"
set "PS=%PS%; $o+='SISTEMA'; $o+=('  Produttore : ' + $cs.Manufacturer); $tp=''; if($env:HW_TIPO -and ($env:HW_TIPO -ne $env:HW_MODELLO)){ $tp=' - tipo ' + $env:HW_TIPO }; $o+=('  Modello    : ' + $env:HW_NOME + $tp); $o+=('  Seriale    : ' + $env:HW_SERIALE); $o+=('  BIOS       : ' + $bios.SMBIOSBIOSVersion + ' del ' + $env:HW_BIOSDATA); $o+=('  Windows    : ' + $env:HW_WIN + ' - ' + $os.OSArchitecture); $o+=''"
set "PS=%PS%; $o+='PROCESSORE'; foreach($c in Get-CimInstance Win32_Processor){ $o+=('  ' + $c.Name.Trim() + ' - ' + $c.NumberOfCores + ' core, ' + $c.NumberOfLogicalProcessors + ' thread, frequenza base ' + $c.MaxClockSpeed + ' MHz') }; $o+=''"
set "PS=%PS%; $o+='GRAFICA E SCHERMO'; foreach($v in Get-CimInstance Win32_VideoController){ $dd=''; if($v.DriverDate){ $dd=' del ' + $v.DriverDate.ToString('dd-MM-yyyy') }; $o+=('  ' + $v.Name + ' - driver ' + $v.DriverVersion + $dd); if($v.CurrentHorizontalResolution){ $o+=('    schermo ' + $v.CurrentHorizontalResolution + 'x' + $v.CurrentVerticalResolution + ' a ' + $v.CurrentRefreshRate + ' Hz') } }; $o+=''"
set "PS=%PS%; $mods=@(Get-CimInstance Win32_PhysicalMemory); $slot=(Get-CimInstance Win32_PhysicalMemoryArray | Where-Object { $_.Use -eq 3 } | Measure-Object -Property MemoryDevices -Sum).Sum; $o+=('MEMORIA RAM - moduli installati: ' + $mods.Count + ', posizioni segnalate dal BIOS: ' + $slot); foreach($m in $mods){ $pn=([string]$m.PartNumber).Trim(); $mf=([string]$m.Manufacturer).Trim(); if(-not $mf -or $mf -match 'Unknown|Undefined|^0+$'){ $mf=if($pn -match '^(CT|BL)'){'Crucial'} elseif($pn -match '^(MT|[0-9]+ATF)'){'Micron'} elseif($pn -match '^M[34]'){'Samsung'} elseif($pn -match '^HM[ATC]'){'SK hynix'} elseif($pn -match '^(KVR|KF|KCP|KHX)'){'Kingston'} elseif($pn -match '^F[345]'){'G.Skill'} elseif($pn -match '^CM'){'Corsair'} else {'marca non indicata'} }; $o+=('  ' + [math]::Round($m.Capacity/1GB) + ' GB ' + $mf + ' ' + $pn + ' a ' + $m.ConfiguredClockSpeed + ' MHz - ' + (([string]$m.BankLabel + ' ' + [string]$m.DeviceLocator).Trim())) }; $o+=''"
set "PS=%PS%; $o+='DISCHI'; foreach($d in Get-PhysicalDisk){ $o+=('  ' + $d.FriendlyName + ' - ' + $d.MediaType + ' ' + $d.BusType + ' - ' + [math]::Round($d.Size/1GB) + ' GB - stato ' + $d.HealthStatus) }; foreach($v in Get-Volume | Where-Object { $_.DriveLetter -and $_.Size }){ $o+=('  Unita'' ' + $v.DriveLetter + ': ' + [math]::Round($v.SizeRemaining/1GB) + ' GB liberi su ' + [math]::Round($v.Size/1GB) + ' GB') }; $o+=''"
set "PS=%PS%; $o+='BATTERIA'; $o+=('  ' + $env:HW_BATTTXT); $bs=Get-CimInstance -Namespace root/wmi -ClassName BatteryStaticData | Select-Object -First 1; $bf=Get-CimInstance -Namespace root/wmi -ClassName BatteryFullChargedCapacity | Select-Object -First 1; if($bs.DesignedCapacity){ $o+=('  Capacita'' originale ' + $bs.DesignedCapacity + ' mWh, attuale ' + $bf.FullChargedCapacity + ' mWh') }; $o+=''"
set "PS=%PS%; $o+='RETE'; foreach($n in Get-NetAdapter -Physical){ $o+=('  ' + $n.InterfaceDescription + ' - ' + $n.Status + ' ' + $n.LinkSpeed) }; Set-Content -LiteralPath (Join-Path $env:OUT 'analisi_hardware.txt') -Value $o"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%" >nul 2>&1

if defined HW_ALTROUTENTE if exist "%PUBLIC%\Desktop" move "%OUT%" "%PUBLIC%\Desktop\" >nul 2>&1
if defined HW_ALTROUTENTE if exist "%PUBLIC%\Desktop\RinascitaPC_%TS%" set "OUT=%PUBLIC%\Desktop\RinascitaPC_%TS%"
set "LOG=%OUT%\registro.txt"
set "ESITI=%OUT%\esiti.tmp"
for %%p in ("%OUT%\..") do set "REPDIR=%%~fp"
set "REPORT=%REPDIR%\RinascitaPC_rapporto_%TS%.txt"

>>"%LOG%" echo [%date% %time%] RinascitaPC versione %VERSIONE%
>>"%LOG%" echo [%date% %time%] PC rilevato: %HW_NOME% - tipo %HW_TIPO% - seriale %HW_SERIALE%
>>"%LOG%" echo [%date% %time%] BIOS %HW_BIOS% del %HW_BIOSDATA% - %HW_WIN%
>>"%LOG%" echo [%date% %time%] CPU %HW_CPU% - GPU %HW_GPU% - RAM %HW_RAM% GB - Disco %HW_DISCO% - Batteria %HW_BATTTXT% - Internet %HW_RETE_TXT%
if defined HW_ALTROUTENTE call :logfile "Impostazioni personali applicate all'utente %HW_ALTROUTENTE%"

if not "%HW_RETE%"=="1" (
    echo.
    echo   Internet non disponibile: senza connessione salto aggiornamenti, driver e nuove app.
    choice /c RC /m "  [R]iprova dopo esserti collegato oppure [C]ontinua senza internet"
    if not errorlevel 2 goto analisi
)
exit /b

:: ==========================================================================
:ripristino
call :titolo "PUNTO DI RIPRISTINO"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Enable-ComputerRestore -Drive '%SystemDrive%\'; Checkpoint-Computer -Description 'Prima di RinascitaPC' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop; Write-Host '   Punto di ripristino creato.' -ForegroundColor Green } catch { Write-Host '   Punto di ripristino NON creato.' -ForegroundColor Red; exit 1 }"
if errorlevel 1 (
    call :esito "Punto di ripristino" ATT "non creato: protezione sistema disattivata o spazio insufficiente"
    choice /c SN /t 30 /d N /m "  Continuare comunque senza punto di ripristino (No automatico tra 30 s)"
    if errorlevel 2 (set "ANNULLA=1") else (set "RP_FATTO=1")
) else (
    call :esito "Punto di ripristino" OK "creato"
    set "RP_FATTO=1"
)
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /f >nul 2>&1
exit /b

:: Le opzioni che cambiano impostazioni di Windows creano prima un punto di
:: ripristino, una sola volta per sessione.
:con_ripristino
if not defined RP_FATTO call :ripristino
if defined ANNULLA (call :log "Operazione annullata: nessun punto di ripristino" & exit /b)
call :%~1
exit /b

:: ==========================================================================
:bloatware
call :titolo "RIMOZIONE APP INUTILI"
echo   Vengono rimosse, se presenti: Notizie, Meteo, Bing Search, Suggerimenti,
echo   Feedback Hub, Solitaire, Microsoft 365 Hub, Mappe, Film e TV,
echo   Power Automate, To Do, Persone, Cortana,
echo   Dev Home, Teams personale vecchio, Skype, Realta' mista, Visualizzatore 3D
echo   e app promozionali (Candy Crush, TikTok, Disney+, Facebook, Instagram...).
echo.
echo   NON vengono toccati: Store, Foto, Calcolatrice, Blocco note, Paint,
echo   Fotocamera, Strumento di cattura, Lettore multimediale, Assistenza,
echo   Xbox, Edge, OneDrive, Copilot, Outlook, Collegamento al telefono.
echo   Tutto cio' che viene rimosso si puo' reinstallare dal Microsoft Store.
echo.
choice /c SN /t 30 /d S /m "  Procedere (Si automatico tra 30 s)"
if errorlevel 2 (call :log "Rimozione app saltata" & exit /b)
call :log "Rimuovo le app preinstallate inutili"
set "PS=function LogR($x){ if($env:LOG){ try { Add-Content -LiteralPath $env:LOG -Value $x -Encoding ASCII -ErrorAction Stop } catch {} } }; $l=@(%BLOAT%); $prov=@(Get-AppxProvisionedPackage -Online); $n=0; foreach($a in $l){ $p=@(Get-AppxPackage -AllUsers -Name $a -ErrorAction SilentlyContinue); if($p.Count -gt 0){ Write-Host ('    - rimuovo ' + $a); LogR ('    rimossa: ' + (($p | ForEach-Object { $_.Name }) -join ', ')); $p | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; $n++ }; $prov | Where-Object { $_.DisplayName -like $a } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null }; Write-Host ('    App rimosse: ' + $n) -ForegroundColor Green; exit (100 + $n)"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%"
set "RC=%errorlevel%"
set "NAPP="
if %RC% GEQ 100 set /a NAPP=RC-100
if defined NAPP (call :esito "Rimozione app inutili" OK "%NAPP% app rimosse") else (call :esito "Rimozione app inutili" ATT "non completata, codice %RC%")

powershell -NoProfile -Command "$n=0; foreach($a in @(%BLOATDATI%)){ if(Get-AppxPackage -AllUsers -Name $a -ErrorAction SilentlyContinue){ $n++ } }; exit $n"
if not errorlevel 1 goto bloat_pubblicita
echo.
echo   Clipchamp e la vecchia app Posta e Calendario possono contenere dati tuoi
echo   salvati solo su questo PC: progetti video non esportati, email di account POP.
echo   Rimuovile solo se non le usi, oppure dopo aver esportato video ed email.
choice /c SN /t 30 /d N /m "  Rimuovere anche Clipchamp e Posta e Calendario (No automatico tra 30 s)"
if errorlevel 2 (call :log "Clipchamp e Posta e Calendario mantenuti con i loro dati" & goto bloat_pubblicita)
set "PS=function LogR($x){ if($env:LOG){ try { Add-Content -LiteralPath $env:LOG -Value $x -Encoding ASCII -ErrorAction Stop } catch {} } }; $l=@(%BLOATDATI%); $prov=@(Get-AppxProvisionedPackage -Online); $n=0; foreach($a in $l){ $p=@(Get-AppxPackage -AllUsers -Name $a -ErrorAction SilentlyContinue); if($p.Count -gt 0){ Write-Host ('    - rimuovo ' + $a); LogR ('    rimossa: ' + (($p | ForEach-Object { $_.Name }) -join ', ')); $p | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; $n++ }; $prov | Where-Object { $_.DisplayName -like $a } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null }; exit (100 + $n)"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%"
set "RC=%errorlevel%"
set "NAPP="
if %RC% GEQ 100 set /a NAPP=RC-100
if defined NAPP (call :esito "Rimozione Clipchamp e Posta e Calendario" OK "%NAPP% app rimosse") else (call :esito "Rimozione Clipchamp e Posta e Calendario" ATT "non completata, codice %RC%")

:bloat_pubblicita
call :log "Impedisco a Windows di reinstallare app sponsorizzate e di mostrare pubblicita'"
set "REGERR=0"
set "CDM=%UK%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
for %%v in (SilentInstalledAppsEnabled PreInstalledAppsEnabled OemPreInstalledAppsEnabled SystemPaneSuggestionsEnabled SoftLandingEnabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled) do reg add "%CDM%" /v %%v /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1
reg add "%UK%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_IrisRecommendations /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1
reg add "%UK%\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1
if %REGERR% GTR 0 (call :esito "Blocco pubblicita' e app sponsorizzate" ATT "%REGERR% impostazioni non applicate") else (call :esito "Blocco pubblicita' e app sponsorizzate" OK "applicato")

echo.
echo   Programmi di terze parti spesso preinstallati o in prova trovati sul PC:
powershell -NoProfile -Command "function LogR($x){ if($env:LOG){ try { Add-Content -LiteralPath $env:LOG -Value $x -Encoding ASCII -ErrorAction Stop } catch {} } }; $k='HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'; $r=Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'McAfee|Norton|WildTangent|ExpressVPN|Booking|CyberLink|Avast|AVG|Dropbox|WPS Office|Trial' } | Select-Object -ExpandProperty DisplayName -Unique; if($r){ $r | ForEach-Object { Write-Host ('    - ' + $_) -ForegroundColor Yellow; LogR ('    programma di terze parti da valutare: ' + $_) } } else { Write-Host '    nessuno' }"
echo   Se non ti servono, rimuovili con Bulk Crap Uninstaller (opzione 7)
echo   oppure da Impostazioni - App - App installate.
exit /b

:: ==========================================================================
:pulizia
call :titolo "PULIZIA PROFONDA"
call :spazio PRIMA

call :log "File temporanei dell'utente e di sistema (la cartella di questo script resta intatta)"
powershell -NoProfile -Command "$skip=$env:SELFDIR; $self=$env:SELF; foreach($t in @($env:TEMP, (Join-Path $env:SystemRoot 'Temp'), $env:HW_UTEMP)){ if($t -and (Test-Path -LiteralPath $t)){ Get-ChildItem -LiteralPath $t -Force -ErrorAction SilentlyContinue | Where-Object { ($_.FullName -ne $self) -and (-not $skip.StartsWith($_.FullName + '\', [StringComparison]::OrdinalIgnoreCase)) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } }"

call :log "Cache di Windows Update e di Ottimizzazione recapito"
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /f /s /q "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
for /d %%d in ("%SystemRoot%\SoftwareDistribution\Download\*") do rd /s /q "%%d" >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
powershell -NoProfile -Command "Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue" >nul 2>&1

choice /c SN /t 20 /d N /m "  Svuotare anche il Cestino (No automatico tra 20 s)"
if errorlevel 2 (
    call :log "Cestino non svuotato"
) else (
    powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
    call :log "Cestino svuotato"
)

if not exist "%SystemRoot%\System32\cleanmgr.exe" goto pulizia_dism
call :log "Pulizia disco di Windows: esclusi Download, Cestino, Cronologia file, vecchie installazioni e frammenti recuperati"
set "VC=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
for /f "delims=" %%k in ('reg query "%VC%" ^| findstr /i /v /c:"DownloadsFolder" /c:"Recycle Bin" /c:"Previous Installations" /c:"Windows ESD installation files" /c:"User file versions" /c:"Old ChkDsk Files"') do reg add "%%k" /v StateFlags0099 /t REG_DWORD /d 2 /f >nul 2>&1
for /f "delims=" %%k in ('reg query "%VC%" ^| findstr /i /c:"DownloadsFolder" /c:"Recycle Bin" /c:"Previous Installations" /c:"Windows ESD installation files" /c:"User file versions" /c:"Old ChkDsk Files"') do reg delete "%%k" /v StateFlags0099 /f >nul 2>&1
start "" /wait "%SystemRoot%\System32\cleanmgr.exe" /sagerun:99

:pulizia_dism
call :log "Pulizia dei componenti di Windows (cartella WinSxS)"
DISM /Online /Cleanup-Image /StartComponentCleanup
set "RC=%errorlevel%"
if "%RC%"=="0" call :esito "Pulizia componenti di Windows" OK "completata"
if "%RC%"=="3010" call :esito "Pulizia componenti di Windows" OK "completata, si conclude al riavvio"
if not "%RC%"=="0" if not "%RC%"=="3010" call :esito "Pulizia componenti di Windows" ATT "non riuscita, codice %RC%"

call :log "Svuoto la cache DNS"
ipconfig /flushdns >nul 2>&1

call :log "Attivo Sensore memoria: in futuro pulira' solo i file temporanei, mai Cestino e Download"
set "SSK=%UK%\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
set "REGERR=0"
reg add "%SSK%" /v 04 /t REG_DWORD /d 1 /f >nul 2>&1 || set /a REGERR+=1
reg add "%SSK%" /v 08 /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1
reg add "%SSK%" /v 32 /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1
if %REGERR% EQU 0 reg add "%SSK%" /v 01 /t REG_DWORD /d 1 /f >nul 2>&1 || set /a REGERR+=1
if %REGERR% GTR 0 (call :esito "Sensore memoria" ATT "non configurato, resta come prima") else (call :esito "Sensore memoria" OK "attivo solo sui file temporanei")

call :spazio DOPO
set /a LIBERATI=SPAZIO_DOPO-SPAZIO_PRIMA
if %LIBERATI% lss 0 set "LIBERATI=0"
call :esito "Pulizia file temporanei e cache" OK "liberati %LIBERATI% MB"
exit /b

:: ==========================================================================
:ripara
call :titolo "RIPARAZIONE DI WINDOWS"
call :log "DISM: verifica e ripristino dell'immagine di sistema (10-20 minuti)"
DISM /Online /Cleanup-Image /RestoreHealth
set "RC=%errorlevel%"
if "%RC%"=="0" call :esito "Riparazione immagine di Windows con DISM" OK "completata"
if "%RC%"=="3010" call :esito "Riparazione immagine di Windows con DISM" OK "completata, si conclude al riavvio"
if not "%RC%"=="0" if not "%RC%"=="3010" call :esito "Riparazione immagine di Windows con DISM" ATT "non riuscita, codice %RC%: controlla internet e ripeti l'opzione 5"
call :log "SFC: controllo e riparazione dei file di sistema"
call :sfc_inizio
sfc /scannow
call :sfc_esito
if "%SFCRC%"=="0" call :esito "File di sistema SFC" OK "nessun file danneggiato"
if "%SFCRC%"=="1" call :esito "File di sistema SFC" OK "file danneggiati trovati e riparati"
if "%SFCRC%"=="2" call :esito "File di sistema SFC" ATT "alcuni file non sono riparabili: riavvia e ripeti l'opzione 5"
if "%SFCRC%"=="3" call :esito "File di sistema SFC" ATT "esito non leggibile: controlla il messaggio di SFC sullo schermo"
set "MP=%ProgramFiles%\Windows Defender\MpCmdRun.exe"
if not exist "%MP%" exit /b
call :log "Microsoft Defender: aggiornamento firme e scansione rapida"
"%MP%" -SignatureUpdate
if errorlevel 1 (call :esito "Aggiornamento firme antivirus" ATT "non riuscito: controlla Sicurezza di Windows") else (call :esito "Aggiornamento firme antivirus" OK "completato")
"%MP%" -Scan -ScanType 1
if errorlevel 1 (call :esito "Scansione antivirus rapida" ATT "minacce trovate o scansione non riuscita: apri Sicurezza di Windows") else (call :esito "Scansione antivirus rapida" OK "nessuna minaccia")
exit /b

:: ==========================================================================
:aggiorna
call :titolo "AGGIORNAMENTI E DRIVER DEL TUO MODELLO"
if not "%HW_RETE%"=="1" (call :log "Internet non disponibile: collegati e riavvia lo script per aggiornare app e driver" & exit /b)
call :winget_check
if not "%WG%"=="1" goto aggiorna_driver
call :log "Aggiorno tutte le app installate all'ultima versione"
winget source update >nul 2>&1
powershell -NoProfile -Command "function LogR($x){ if($env:LOG){ try { Add-Content -LiteralPath $env:LOG -Value $x -Encoding ASCII -ErrorAction Stop } catch {} } }; [Console]::OutputEncoding=[Text.Encoding]::UTF8; $w=@(& winget upgrade --accept-source-agreements 2>$null); $i=0; while($i -lt $w.Count -and $w[$i] -notmatch '^-{10,}'){ $i++ }; $n=0; for($j=$i+1; $j -lt $w.Count; $j++){ $x=[string]$w[$j]; if([string]::IsNullOrWhiteSpace($x)){ break }; if($x -notmatch '^\d+ \S'){ $n++; LogR ('    da aggiornare: ' + ($x -replace '\s{2,}',' / ').Trim()) } }; if($n -eq 0){ LogR '    nessuna app da aggiornare secondo winget' }" >nul 2>&1
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
call :esito_winget "Aggiornamento di tutte le app" %errorlevel%
:aggiorna_driver
call :driver_wu
echo.
choice /c SN /t 20 /d S /m "  Installare gli strumenti ufficiali per i driver del tuo %HW_NOME% (Si automatico tra 20 s)"
if errorlevel 2 goto aggiorna_fine
call :driver_produttore
call :driver_grafica
:aggiorna_fine
call :log "Avvio anche la ricerca degli aggiornamenti di Windows"
usoclient StartInteractiveScan >nul 2>&1
exit /b

:driver_wu
call :log "Cerco su Windows Update i driver piu' recenti per il tuo hardware (alcuni minuti)"
set "PS=function LogR($x){ if($env:LOG){ try { Add-Content -LiteralPath $env:LOG -Value $x -Encoding ASCII -ErrorAction Stop } catch {} } }; $ErrorActionPreference='Stop'; try { $s=New-Object -ComObject Microsoft.Update.Session; $q=$s.CreateUpdateSearcher(); $r=$q.Search('IsInstalled=0 and Type=''Driver'' and IsHidden=0'); if($r.Updates.Count -eq 0){ Write-Host '    Tutti i driver offerti da Windows Update sono gia'' aggiornati.' -ForegroundColor Green; exit 0 }"
set "PS=%PS%; $c=New-Object -ComObject Microsoft.Update.UpdateColl; $skip=@(); foreach($u in $r.Updates){ $t=[string]$u.Title; if(([string]$u.DriverClass -match 'Firmware') -or ($t -match 'Firmware|BIOS|UEFI') -or $u.InstallationBehavior.CanRequestUserInput){ $skip+=$t; continue }; Write-Host ('    - ' + $t); LogR ('    driver da installare: ' + $t); if(-not $u.EulaAccepted){ $u.AcceptEula() }; [void]$c.Add($u) }"
set "PS=%PS%; foreach($t in $skip){ Write-Host ('    NON installato in automatico (BIOS, firmware o richiede conferma): ' + $t) -ForegroundColor Yellow; LogR ('    escluso, BIOS/firmware o interattivo: ' + $t) }; if($c.Count -eq 0){ if($skip.Count -gt 0){ exit 14 }; exit 0 }; Write-Host '    Scarico i driver...'; $d=$s.CreateUpdateDownloader(); $d.Updates=$c; [void]$d.Download(); Write-Host '    Installo i driver...'; $i=$s.CreateUpdateInstaller(); $i.Updates=$c; $res=$i.Install()"
set "PS=%PS%; $m=@{2='completata';3='completata con qualche errore';4='non riuscita';5='annullata'}; Write-Host ('    Installazione driver ' + $m[[int]$res.ResultCode] + '.') -ForegroundColor Green; if($res.RebootRequired){ Write-Host '    Serve un riavvio per completare.' -ForegroundColor Yellow }; $k=10; if([int]$res.ResultCode -eq 3){ $k=11 } elseif([int]$res.ResultCode -ne 2){ $k=12 } elseif($skip.Count -gt 0){ $k=15 }; exit $k } catch { Write-Host ('    Ricerca driver non riuscita: ' + $_.Exception.Message) -ForegroundColor Yellow; exit 13 }"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%"
set "RC=%errorlevel%"
set "D=Driver da Windows Update"
if "%RC%"=="0" (call :esito "%D%" OK "gia' tutti aggiornati" & exit /b)
if "%RC%"=="10" (call :esito "%D%" OK "installati" & exit /b)
if "%RC%"=="11" (call :esito "%D%" ATT "alcuni non si sono installati: riavvia e ripeti l'opzione 6" & exit /b)
if "%RC%"=="12" (call :esito "%D%" ATT "installazione non riuscita: riavvia e ripeti l'opzione 6" & exit /b)
if "%RC%"=="13" (call :esito "%D%" ATT "ricerca non riuscita: controlla Windows Update nelle Impostazioni" & exit /b)
if "%RC%"=="14" (call :esito "%D%" ATT "c'e' un aggiornamento BIOS o firmware da fare con l'app del produttore" & exit /b)
if "%RC%"=="15" (call :esito "%D%" ATT "installati, ma resta un aggiornamento BIOS o firmware da fare con l'app del produttore" & exit /b)
call :esito "%D%" ATT "esito imprevisto, codice %RC%"
exit /b

:driver_produttore
set "VID="
set "VSRC=winget"
set "VNOME="
echo %HW_MARCA% | findstr /i "lenovo" >nul && (set "VID=9WZDNCRFJ4MV" & set "VSRC=msstore" & set "VNOME=Lenovo Vantage")
echo %HW_MARCA% | findstr /i "asus" >nul && (set "VID=9N7R5S6B0ZZH" & set "VSRC=msstore" & set "VNOME=MyASUS")
echo %HW_MARCA% | findstr /i "hp hewlett" >nul && (set "VID=HP.SupportAssistant" & set "VNOME=HP Support Assistant")
echo %HW_MARCA% | findstr /i "dell" >nul && (set "VID=Dell.CommandUpdate.Universal" & set "VNOME=Dell Command Update")
echo %HW_MARCA% | findstr /i "msi micro-star" >nul && (set "VID=MSI.MSICenter" & set "VNOME=MSI Center")
if not defined VID goto driver_pagina
if not "%WG%"=="1" goto driver_pagina
call :log "App ufficiale per il tuo %HW_NOME%: %VNOME% (driver, BIOS, garanzia e modalita' termiche)"
winget install --id %VID% -e -s %VSRC% --silent --accept-package-agreements --accept-source-agreements
call :esito_winget "Installazione %VNOME%" %errorlevel%
if /i "%VID%"=="Dell.CommandUpdate.Universal" call :driver_dell
exit /b

:driver_dell
set "DCU=%ProgramFiles%\Dell\CommandUpdate\dcu-cli.exe"
if not exist "%DCU%" set "DCU=%ProgramFiles(x86)%\Dell\CommandUpdate\dcu-cli.exe"
if not exist "%DCU%" (call :log "Apri Dell Command Update dal menu Start per cercare gli aggiornamenti" & exit /b)
call :log "Dell Command Update: installo driver e app certificati per il tuo modello (il BIOS aggiornalo dall'app)"
"%DCU%" /applyUpdates -updateType=driver,application -reboot=disable
set "RC=%errorlevel%"
if "%RC%"=="0" (call :esito "Aggiornamenti Dell" OK "installati" & exit /b)
if "%RC%"=="1" (call :esito "Aggiornamenti Dell" OK "installati, serve un riavvio" & exit /b)
if "%RC%"=="500" (call :esito "Aggiornamenti Dell" OK "nessun aggiornamento necessario" & exit /b)
if "%RC%"=="5" (call :esito "Aggiornamenti Dell" ATT "c'e' un riavvio in sospeso: riavvia e ripeti l'opzione 6" & exit /b)
call :esito "Aggiornamenti Dell" ATT "non riusciti, codice %RC%: apri Dell Command Update"
exit /b

:driver_pagina
call :log "Per il tuo %HW_NOME% apro la pagina driver e BIOS del tuo modello nel browser"
powershell -NoProfile -Command "$m=[string]$env:HW_NOME; Start-Process -FilePath explorer.exe -ArgumentList ('https://www.google.com/search?q=' + [uri]::EscapeDataString($m + ' driver BIOS download supporto ufficiale'))"
exit /b

:driver_grafica
if not "%HW_INTEL%"=="1" goto grafica_altre
if not "%WG%"=="1" goto grafica_altre
call :log "Componenti Intel rilevati: installo Intel Driver e Support Assistant"
winget install --id Intel.IntelDriverAndSupportAssistant -e -s winget --silent --accept-package-agreements --accept-source-agreements
call :esito_winget "Installazione Intel Driver e Support Assistant" %errorlevel%
:grafica_altre
if "%HW_GPUNV%"=="1" (
    call :log "Scheda video NVIDIA rilevata: apro la pagina ufficiale dei driver NVIDIA e della NVIDIA App"
    start "" explorer "https://www.nvidia.com/it-it/drivers/"
)
if "%HW_GPUAMD%"=="1" (
    call :log "Grafica AMD Radeon rilevata: apro la pagina ufficiale dei driver AMD con rilevamento automatico"
    start "" explorer "https://www.amd.com/support"
)
exit /b

:: ==========================================================================
:installa
call :titolo "ALTERNATIVE LEGGERE E GRATUITE"
if not "%HW_RETE%"=="1" (call :log "Internet non disponibile, salto questa fase" & exit /b)
call :winget_check
if not "%WG%"=="1" exit /b
if "%MODO%"=="TUTTO" (
    choice /c SN /t 30 /d N /m "  Vuoi scegliere programmi leggeri da installare (No automatico tra 30 s)"
    if errorlevel 2 (call :log "Installazione alternative saltata" & exit /b)
)
set "ID1=7zip.7zip" & set "DS1=7-Zip - archivi ZIP e RAR, al posto di WinRAR e WinZip"
set "ID2=VideoLAN.VLC" & set "DS2=VLC - riproduce qualsiasi video e audio"
set "ID3=SumatraPDF.SumatraPDF" & set "DS3=SumatraPDF - lettore PDF ultraleggero, al posto di Adobe Reader"
set "ID4=Mozilla.Firefox.it" & set "DS4=Firefox in italiano - browser che usa meno RAM di Chrome"
set "ID5=TheDocumentFoundation.LibreOffice" & set "DS5=LibreOffice - suite da ufficio gratuita, apre i file Office"
set "ID6=Notepad++.Notepad++" & set "DS6=Notepad++ - editor di testo veloce"
set "ID7=DuongDieuPhap.ImageGlass" & set "DS7=ImageGlass - visualizzatore di immagini piu' rapido di Foto"
set "ID8=voidtools.Everything" & set "DS8=Everything - ricerca istantanea dei file"
set "ID9=Klocman.BulkCrapUninstaller" & set "DS9=Bulk Crap Uninstaller - rimuove programmi e relativi residui"
set "ID10=AntibodySoftware.WizTree" & set "DS10=WizTree - mostra cosa occupa spazio sul disco"
set "ID11=REALiX.HWiNFO" & set "DS11=HWiNFO - temperature, ventole e sensori in tempo reale"
set "ID12=CrystalDewWorld.CrystalDiskInfo" & set "DS12=CrystalDiskInfo - salute del disco"
set "N=12"
echo.
for /l %%i in (1,1,%N%) do call :installa_mostra %%i
echo.
echo   A. Installa tutti        0. Salta
echo.
set "SEL="
set /p "SEL=  Numeri separati da spazio (es. 1 2 4) oppure A: "
if not defined SEL exit /b
set "SEL=%SEL:"=%"
if not defined SEL exit /b
set "SEL=%SEL:&= %"
set "SEL=%SEL:|= %"
set "SEL=%SEL:<= %"
set "SEL=%SEL:>= %"
set "SEL=%SEL:(= %"
set "SEL=%SEL:)= %"
if "%SEL%"=="0" (call :log "Nessun programma installato" & exit /b)
if /i "%SEL%"=="A" set "SEL=1 2 3 4 5 6 7 8 9 10 11 12"
call :log "Programmi scelti: %SEL%"
for %%i in (%SEL%) do call :installa_uno %%i
exit /b

:installa_mostra
call echo   %~1. %%DS%~1%%
exit /b

:installa_uno
if not defined ID%~1 (echo   Numero %~1 non valido, ignorato.& exit /b)
call set "PKG=%%ID%~1%%"
echo.
call :log "Installo %PKG%"
winget install --id %PKG% -e -s winget --silent --accept-package-agreements --accept-source-agreements
call :esito_winget "Installazione %PKG%" %errorlevel%
exit /b

:: ==========================================================================
:prestazioni
call :titolo "PRESTAZIONI, RAM E SERVIZI"

set "REGERR=0"
call :log "Disattivo i Widget (restano attivi in background e consumano RAM)"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1

call :log "Tolgo i risultati web di Bing dalla ricerca del menu Start (piu' veloce)"
reg add "%UK%\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul 2>&1 || set /a REGERR+=1

call :log "Disattivo servizi superflui: telemetria, mappe offline, modalita' demo"
for %%s in (DiagTrack MapsBroker RetailDemo) do (
    sc stop %%s >nul 2>&1
    sc config %%s start= disabled >nul 2>&1
)

call :log "RAM: file di paging gestito da Windows e compressione della memoria attiva"
powershell -NoProfile -Command "try { Enable-MMAgent -MemoryCompression -ErrorAction Stop } catch {}; try { $cs=Get-CimInstance Win32_ComputerSystem -ErrorAction Stop; if(-not $cs.AutomaticManagedPagefile){ Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$true} -ErrorAction Stop }; exit 0 } catch { exit 1 }"
if errorlevel 1 (call :esito "Memoria virtuale gestita da Windows" ATT "non impostata: controlla Impostazioni di sistema avanzate") else (call :esito "Memoria virtuale gestita da Windows" OK "attiva")

call :log "Modalita' gioco attiva (priorita' al programma in primo piano)"
reg add "%UK%\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1 || set /a REGERR+=1

call :log "Spengo Copilot e le app in background, e tolgo il ritardo dei programmi all'avvio"
reg add "%UK%\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1 || set /a REGERR+=1
reg add "%UK%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1
reg add "%UK%\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul 2>&1 || set /a REGERR+=1
reg add "%UK%\Software\Microsoft\Windows\CurrentVersion\Search" /v BackgroundAppGlobalToggle /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1
reg add "%UK%\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1
call :log "Nota: se un'app dello Store non manda piu' notifiche quando e' chiusa, riattivala in Impostazioni - App - Opzioni avanzate"

call :log "Disattivo le attivita' pianificate di telemetria (Windows Update e gli aggiornamenti dei programmi restano attivi)"
set "TT=0"
for %%t in ("\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" "\Microsoft\Windows\Feedback\Siuf\DmClient" "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" "\Microsoft\Windows\Autochk\Proxy") do schtasks /Change /TN %%t /Disable >nul 2>&1 && set /a TT+=1
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $n=0; foreach($t in @(Get-ScheduledTask | Where-Object { $_.TaskPath -notlike '\Microsoft\*' -and $_.State -ne 'Disabled' -and $_.TaskName -match '(?i)telemetr|analytic|ceip|customer ?experience|feedback|survey|usage ?(stat|report)' -and $_.TaskName -notmatch '(?i)update|upgrade|secur|defender|backup|antivir' })){ if(Disable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath){ $n++; if($env:LOG){ Add-Content -LiteralPath $env:LOG -Value ('    telemetria disattivata: ' + $t.TaskName) -Encoding ASCII } } }; exit $n"
set /a TT+=%errorlevel%
call :esito "Attivita' pianificate di telemetria" OK "%TT% disattivate"

if %HW_RAM% GTR 0 if %HW_RAM% LEQ 8 (
    call :log "Con %HW_RAM% GB di RAM riduco automaticamente animazioni e trasparenze"
    goto prest_effetti
)
choice /c SN /t 20 /d S /m "  Ridurre animazioni e trasparenze per un sistema piu' reattivo (Si automatico tra 20 s)"
if errorlevel 2 (call :log "Animazioni e trasparenze lasciate come sono" & goto prest_avvio)
call :log "Riduco animazioni e trasparenze"
:prest_effetti
reg add "%UK%\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1
reg add "%UK%\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1 || set /a REGERR+=1
reg add "%UK%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1
reg add "%UK%\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1 || set /a REGERR+=1
reg add "%UK%\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 100 /f >nul 2>&1 || set /a REGERR+=1

:prest_avvio
if %REGERR% GTR 0 (call :esito "Prestazioni, privacy e animazioni" ATT "%REGERR% impostazioni non applicate") else (call :esito "Prestazioni, privacy e animazioni" OK "applicate")
call :avvio
call :log "Nota: alcune pagine di Impostazioni possono indicare 'gestito dall'organizzazione', e' normale"
exit /b

:: Programmi all'avvio: disattiva da solo quelli superflui, come fa Gestione attivita'
:: (niente viene disinstallato, si riattivano da li'). Restano attivi sicurezza, driver,
:: cloud, VPN, password e programmi del produttore. Elenco in %ProgramData%\RinascitaPC.
:avvio
if "%HW_GESTITO%"=="1" goto avvio_elenco
call :log "Programmi all'avvio: cerco quelli superflui"
set "PS=%PSAV%; $v=@(Voci | Where-Object { -not (Spento $_) }); $via=@($v | Where-Object { ($_.N + ' ' + $_.C) -notmatch $tieni }); $res=@($v | Where-Object { ($_.N + ' ' + $_.C) -match $tieni })"
set "PS=%PS%; if($env:AZIONE -eq 'elenca'){ if($res.Count){ Write-Host '  Restano attivi (sicurezza, driver, cloud, produttore):'; foreach($x in $res){ Write-Host ('    ' + $x.N) -ForegroundColor Green } }; if($via.Count){ Write-Host '  Superflui, da disattivare:'; foreach($x in $via){ Write-Host ('    ' + $x.N) -ForegroundColor Yellow } }; exit $via.Count }"
set "PS=%PS%; $lista=Join-Path $env:ProgramData 'RinascitaPC\avvio_disattivati.txt'; New-Item -ItemType Directory -Force -Path (Split-Path $lista) | Out-Null; $ok=0; foreach($x in $via){ try { if($x.T -eq 'S'){ Set-ItemProperty -LiteralPath $x.A -Name State -Value 1 -Type DWord -ErrorAction Stop } else { if(-not (Test-Path -LiteralPath $x.A)){ New-Item -Path $x.A -Force -ErrorAction Stop | Out-Null }; New-ItemProperty -LiteralPath $x.A -Name $x.N -PropertyType Binary -Value ([byte[]](3,0,0,0,0,0,0,0,0,0,0,0)) -Force -ErrorAction Stop | Out-Null }; $ok++; LogR ('    disattivato all''avvio: ' + $x.N); Add-Content -LiteralPath $lista -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm') + ';' + $x.T + ';' + $x.A + ';' + $x.N) -Encoding ASCII } catch { LogR ('    non disattivato: ' + $x.N) } }; exit $ok"
set "AZIONE=elenca"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%"
set "AV_N=%errorlevel%"
set "AZIONE="
if "%AV_N%"=="0" (call :esito "Programmi superflui all'avvio" OK "nessuno da disattivare" & exit /b)
choice /c SN /t 30 /d S /m "  Disattivare all'avvio i %AV_N% programmi superflui (Si automatico tra 30 s)"
if errorlevel 2 (call :log "Programmi all'avvio lasciati come sono" & exit /b)
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%" >nul 2>&1
set "AV_OK=%errorlevel%"
if "%AV_OK%"=="%AV_N%" (call :esito "Programmi superflui all'avvio" OK "%AV_OK% disattivati, si riattivano da Gestione attivita'") else (call :esito "Programmi superflui all'avvio" ATT "%AV_OK% disattivati su %AV_N%, gli altri da Gestione attivita'")
exit /b

:avvio_elenco
call :log "PC gestito: i programmi all'avvio li decide l'IT, li elenco soltanto:"
powershell -NoProfile -Command "function LogR($x){ if($env:LOG){ try { Add-Content -LiteralPath $env:LOG -Value $x -Encoding ASCII -ErrorAction Stop } catch {} } }; $st=@(Get-CimInstance Win32_StartupCommand | Select-Object Name, Location); $st | Format-Table -AutoSize | Out-String -Width 120; foreach($x in $st){ LogR ('    avvio automatico: ' + $x.Name + ' - ' + $x.Location) }"
start "" taskmgr /0 /startup
call :log "Ho aperto Gestione attivita': scegli App di avvio se non si apre gia' li'"
exit /b

:: ==========================================================================
:raffreddamento
call :titolo "RAFFREDDAMENTO E VENTOLA"
echo   La velocita' della ventola la decide il BIOS del PC. Windows puo'
echo   influire con la politica di raffreddamento e con il Turbo della CPU.
echo   Processore rilevato: %HW_CPU%
echo.
echo   1. PRESTAZIONI MASSIME - turbo aggressivo, ventola subito attiva
echo   2. BILANCIATO (consigliato) - turbo pieno in carica, efficiente a batteria
echo   3. FRESCO E SILENZIOSO - turbo disattivato: temperature molto piu' basse
echo      e ventola tranquilla, con un po' meno potenza di picco
echo.
choice /c 123 /t 30 /d 2 /n /m "  Profilo [1-3] (2 automatico tra 30 s): "
set "PROF=%errorlevel%"
set "SP=54533251-82be-4824-96c1-47b60b740d00"
set "BOOST=be337238-0d82-4146-a960-4f3749d470c7"
set "COOL=94d3a615-a899-4ac5-ae2b-e4d8f634367f"
set "PMAX=bc5038f7-23e0-4960-96da-33abaf5935ec"
powercfg -attributes %SP% %BOOST% -ATTRIB_HIDE >nul 2>&1
powercfg -attributes %SP% %COOL% -ATTRIB_HIDE >nul 2>&1
if "%PROF%"=="1" (set "BAC=2" & set "BDC=1" & set "CAC=1" & set "CDC=1" & set "PNOME=Prestazioni massime")
if "%PROF%"=="2" (set "BAC=1" & set "BDC=3" & set "CAC=1" & set "CDC=0" & set "PNOME=Bilanciato")
if "%PROF%"=="3" (set "BAC=0" & set "BDC=0" & set "CAC=1" & set "CDC=0" & set "PNOME=Fresco e silenzioso")
powercfg /setacvalueindex SCHEME_CURRENT %SP% %BOOST% %BAC% >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT %SP% %BOOST% %BDC% >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT %SP% %COOL% %CAC% >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT %SP% %COOL% %CDC% >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT %SP% %PMAX% 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT %SP% %PMAX% 100 >nul 2>&1
:: Profili 1 e 2: in carica la modalita' risparmio energia va su Prestazioni migliori.
if not "%PROF%"=="3" reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes" /v ActiveOverlayAcPowerScheme /t REG_SZ /d ded574b5-45a0-4f42-8737-46345c09c238 /f >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
powershell -NoProfile -Command "$m=[regex]::Matches(((& powercfg /q SCHEME_CURRENT $env:SP $env:BOOST) -join ' '),'0x([0-9a-fA-F]{8})'); if($m.Count -ge 2){ exit [Convert]::ToInt32($m[0].Groups[1].Value,16) }; exit 99"
if "%errorlevel%"=="%BAC%" (call :esito "Profilo termico %PNOME%" OK "applicato") else (call :esito "Profilo termico %PNOME%" ATT "non confermato da Windows: puo' essere gestito dall'app del produttore")
if not "%PROF%"=="3" call :log "In carica: modalita' risparmio energia su Prestazioni migliori"

set "APP="
echo %HW_MARCA% | findstr /i "lenovo" >nul && set "APP=Lenovo Vantage (su molti modelli Fn+Q cambia la modalita' termica)"
echo %HW_MARCA% | findstr /i "asus" >nul && set "APP=MyASUS (o Armoury Crate sui modelli gaming)"
echo %HW_MARCA% | findstr /i "hp hewlett" >nul && set "APP=HP Command Center (o OMEN Gaming Hub su OMEN e Victus)"
echo %HW_MARCA% | findstr /i "dell" >nul && set "APP=MyDell o Dell Power Manager (Alienware Command Center sugli Alienware)"
echo %HW_MARCA% | findstr /i "acer" >nul && set "APP=Acer Care Center (NitroSense o PredatorSense sui modelli gaming)"
echo %HW_MARCA% | findstr /i "msi micro-star" >nul && set "APP=MSI Center"
if not defined APP set "APP=l'app di controllo del produttore, o le modalita' termiche nel BIOS"
call :log "Per curve e modalita' della ventola del tuo %HW_NOME% usa: %APP%"
call :log "Nota: le modalita' termiche dell'app del produttore hanno la precedenza su questo profilo"
exit /b

:: ==========================================================================
:dischi
call :titolo "OTTIMIZZAZIONE DISCHI"
echo %HW_DISCO% | findstr /i "HDD" >nul && call :log "Disco meccanico rilevato: la deframmentazione puo' richiedere parecchio tempo"
call :log "Verifico che il TRIM per gli SSD sia attivo"
fsutil behavior set DisableDeleteNotify 0 >nul 2>&1
call :log "Controllo errori del file system (senza riavvio)"
chkdsk %SystemDrive% /scan
set "RC=%errorlevel%"
if "%RC%"=="0" call :esito "Controllo del file system" OK "nessun errore"
if "%RC%"=="1" call :esito "Controllo del file system" OK "errori trovati e corretti"
if "%RC%"=="2" call :esito "Controllo del file system" OK "nessun errore grave"
if "%RC%"=="3" call :esito "Controllo del file system" ATT "errori da correggere: esegui chkdsk %SystemDrive% /spotfix da Terminale Admin e riavvia"
call :log "Ottimizzazione: TRIM sugli SSD, deframmentazione solo sugli HDD"
set "DEFERR=0"
set "DEFN=0"
for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | ForEach-Object { $_.DriveLetter }" 2^>nul`) do (
    set /a DEFN+=1
    defrag %%v: /O /U /V
    if errorlevel 1 set /a DEFERR+=1
)
if %DEFN% EQU 0 set /a DEFERR+=1
if %DEFERR% GTR 0 (call :esito "Ottimizzazione dischi" ATT "non riuscita su %DEFERR% unita', leggi i messaggi qui sopra") else (call :esito "Ottimizzazione dischi" OK "completata")
exit /b

:: ==========================================================================
:diagnostica
call :titolo "DIAGNOSTICA HARDWARE E CONSIGLI"
powercfg /batteryreport /output "%OUT%\report_batteria.html" >nul 2>&1 && call :log "Report dettagliato della batteria salvato: report_batteria.html"
echo.
set "PS=$ErrorActionPreference='SilentlyContinue'; $f=Join-Path $env:OUT 'diagnostica.txt'; function W($s,$c='Gray'){ Write-Host $s -ForegroundColor $c; Add-Content -LiteralPath $f -Value $s }; $tips=@()"
set "PS=%PS%; $cpu=Get-CimInstance Win32_Processor | Select-Object -First 1; W ('  Modello : ' + $env:HW_NOME + ' - BIOS ' + $env:HW_BIOS + ' del ' + $env:HW_BIOSDATA); W ('  CPU     : ' + ([string]$cpu.Name).Trim() + ' - ' + $cpu.NumberOfCores + ' core, ' + $cpu.NumberOfLogicalProcessors + ' thread'); W ('  Grafica : ' + $env:HW_GPU)"
set "PS=%PS%; $mods=@(Get-CimInstance Win32_PhysicalMemory); $tot=[math]::Round(($mods | Measure-Object -Property Capacity -Sum).Sum/1GB); $slot=(Get-CimInstance Win32_PhysicalMemoryArray | Where-Object { $_.Use -eq 3 } | Measure-Object -Property MemoryDevices -Sum).Sum; if(-not $slot){ $slot=$mods.Count }; W ('  RAM     : ' + $tot + ' GB installati - moduli: ' + $mods.Count + ', posizioni: ' + $slot); foreach($m in $mods){ W ('            ' + [math]::Round($m.Capacity/1GB) + ' GB a ' + $m.ConfiguredClockSpeed + ' MHz (' + $m.DeviceLocator + ')') }"
set "PS=%PS%; if($tot -gt 0 -and $tot -lt 16){ if($mods.Count -lt $slot){ $tips+='RAM: risulta una posizione libera. Aggiungendo un modulo identico arrivi a 16 GB in dual channel, il potenziamento piu'' utile (verifica con HWiNFO o sulla scheda tecnica del modello).' } elseif($mods.Count -eq 1){ $tips+='RAM: un solo modulo, quindi niente dual channel. Se non e'' saldata, due moduli identici fanno una grande differenza.' } else { $tips+='RAM: meno di 16 GB. Se non e'' saldata, passare a 16 GB e'' il potenziamento piu'' utile.' } }"
set "PS=%PS%; foreach($d in Get-PhysicalDisk | Where-Object { $_.BusType -notmatch 'USB' }){ $r=$d | Get-StorageReliabilityCounter; W ('  Disco   : ' + $d.FriendlyName + ' - ' + $d.MediaType + ' ' + $d.BusType + ' - ' + [math]::Round($d.Size/1GB) + ' GB - stato: ' + $d.HealthStatus); if($r.Temperature){ W ('            temperatura ' + $r.Temperature + ' C, usura ' + $r.Wear + ' percento') }; if($d.MediaType -eq 'HDD'){ $tips+='DISCO: hai un disco meccanico (HDD). Passare a un SSD e'' il singolo potenziamento che cambia di piu'' la velocita''.' }; if($d.HealthStatus -and $d.HealthStatus -ne 'Healthy'){ $tips+=('DISCO: ' + $d.FriendlyName + ' segnala problemi. Fai subito un backup dei tuoi file.') } }"
set "PS=%PS%; $v=Get-Volume -DriveLetter $env:DRV; if($v.Size){ W ('  Spazio  : ' + [math]::Round($v.SizeRemaining/1GB) + ' GB liberi su ' + [math]::Round($v.Size/1GB) + ' GB'); if($v.SizeRemaining/$v.Size -lt 0.15){ $tips+='SPAZIO: meno del 15 percento libero rallenta Windows. Usa WizTree per trovare i file piu'' pesanti.' } }"
set "PS=%PS%; if($env:HW_BATT){ W ('  Batteria: ' + $env:HW_BATT + ' percento della capacita'' originale'); if([int]$env:HW_BATT -lt 70){ $tips+='BATTERIA: sotto il 70 percento della capacita'' originale. Una batteria nuova restituisce autonomia.' } }"
set "PS=%PS%; if([int]$env:HW_BIOSANNI -ge 2){ $tips+=('BIOS: la versione installata e'' del ' + $env:HW_BIOSDATA + '. Aggiornalo con l''app del produttore: spesso migliora stabilita'', consumi e gestione della ventola.') }"
set "PS=%PS%; $tips+='TEMPERATURE: se il PC ha qualche anno, pulire le ventole dalla polvere e rifare la pasta termica abbassa le temperature piu'' di qualsiasi software. Controllale con HWiNFO.'; W ''; W '  CONSIGLI PER IL TUO HARDWARE' 'Cyan'; foreach($t in $tips){ W ('  - ' + $t) 'Yellow' }"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%"
echo.
if "%HW_RETE%"=="1" (
    choice /c SN /t 20 /d S /m "  Aprire online la scheda tecnica del tuo modello per verificare RAM massima e upgrade (Si automatico tra 20 s)"
    if not errorlevel 2 powershell -NoProfile -Command "Start-Process -FilePath explorer.exe -ArgumentList ('https://www.google.com/search?q=' + [uri]::EscapeDataString([string]$env:HW_NOME + ' scheda tecnica RAM massima SSD upgrade'))"
)
choice /c SN /t 20 /d N /m "  Programmare il test della RAM (Diagnostica memoria Windows) (No automatico tra 20 s)"
if errorlevel 2 (call :log "Report salvati in %OUT%" & exit /b)
start "" mdsched.exe
call :log "Test della RAM: scegli quando eseguirlo nella finestra aperta"
call :log "Report salvati in %OUT%"
exit /b

:: ==========================================================================
:verifica
call :titolo "VERIFICA - SOLA LETTURA, NON MODIFICA NULLA"
set "VER=%OUT%\verifica.txt"
>"%VER%" echo VERIFICA RinascitaPC del %date% %time% - %HW_NOME%
set "V_ATT=0"
set "PS=$ErrorActionPreference='SilentlyContinue'; $global:a=0; function Riga($t,$x){ $c=@{OK='Green';ATT='Yellow';INFO='Gray'}[$t]; $g=@{OK='[OK] ';ATT='[!!] ';INFO='[i]  '}[$t]; Write-Host ('  ' + $g + $x) -ForegroundColor $c; Add-Content -LiteralPath $env:VER -Value ($g + $x); if($t -eq 'ATT'){ $global:a++ } }"
set "PS=%PS%; $dirs=@($env:DESKTOP, (Join-Path $env:PUBLIC 'Desktop')); $f=Get-ChildItem -Path $dirs -Filter 'registro.txt' -Recurse -Depth 1 | Where-Object { $_.DirectoryName -like '*RinascitaPC_*' -and $_.DirectoryName -ne $env:OUT -and (Select-String -LiteralPath $_.FullName -Pattern 'AVVIO MODALIT' -Quiet) } | Sort-Object LastWriteTime | Select-Object -Last 1"
set "PS=%PS%; if($f){ $r=@(Get-Content -LiteralPath $f.FullName); $d=$f.LastWriteTime.ToString('dd-MM-yyyy HH:mm'); $bad=@($r | Where-Object { $_ -cmatch '\] DA CONTROLLARE - ' }); if(-not ($r -match 'OTTIMIZZAZIONE COMPLETATA')){ Riga 'ATT' ('Ultima esecuzione completa del ' + $d + ': non e'' arrivata alla fine, ripeti l''opzione 1') } elseif($bad.Count -eq 0){ Riga 'OK' ('Ultima esecuzione completa del ' + $d + ': tutti i passaggi riusciti') } else { Riga 'ATT' ('Ultima esecuzione completa del ' + $d + ': ' + $bad.Count + ' passaggi da controllare'); foreach($b in $bad){ Riga 'INFO' ('     ' + ($b -replace '^.*DA CONTROLLARE - ','').Trim()) } } } else { Riga 'INFO' 'Nessuna esecuzione completa precedente trovata sul Desktop' }"
set "PS=%PS%; if((Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')){ Riga 'ATT' 'Riavvio in sospeso: riavvia il PC e ripeti la verifica' } else { Riga 'OK' 'Nessun riavvio in sospeso' }"
set "PS=%PS%; $rp=Get-ComputerRestorePoint | Where-Object { $_.Description -like 'Prima di RinascitaPC*' } | Select-Object -Last 1; if($rp){ $dt=[string]$rp.CreationTime; $txt=''; if($dt.Length -ge 14){ $txt=' del ' + [Management.ManagementDateTimeConverter]::ToDateTime($dt).ToString('dd-MM-yyyy HH:mm') }; Riga 'OK' ('Punto di ripristino di RinascitaPC presente' + $txt) } else { Riga 'ATT' 'Nessun punto di ripristino di RinascitaPC: crealo con l''opzione 2 prima di altre modifiche' }"
set "PS=%PS%; Write-Host '  ...controllo l''integrita'' di Windows con DISM'; $h=[string](Repair-WindowsImage -Online -CheckHealth).ImageHealthState; if($h -eq 'Healthy'){ Riga 'OK' 'Immagine di Windows integra - DISM' } elseif($h -eq 'Repairable'){ Riga 'ATT' 'Immagine di Windows danneggiata ma riparabile: esegui l''opzione 5' } elseif($h -eq 'NonRepairable'){ Riga 'ATT' 'Immagine di Windows non riparabile: usa Impostazioni - Sistema - Ripristino' } else { Riga 'INFO' 'Stato DISM non disponibile' }; exit $global:a"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%"
set /a V_ATT+=%errorlevel%
echo.
choice /c SN /t 20 /d S /m "  Controllare anche i file di sistema con SFC, circa 10-15 minuti (Si automatico tra 20 s)"
if errorlevel 2 goto verifica_rete
call :sfc_inizio
sfc /verifyonly
call :sfc_esito
if "%SFCRC%"=="0" call :vriga OK "File di sistema integri - SFC"
if "%SFCRC%"=="1" call :vriga OK "File di sistema integri - SFC"
if "%SFCRC%"=="2" call :vriga ATT "File di sistema danneggiati - SFC: esegui l'opzione 5 e riavvia"
if "%SFCRC%"=="3" call :vriga INFO "Esito SFC non leggibile dal registro di Windows: leggi il messaggio di SFC qui sopra"
:verifica_rete
if not "%HW_RETE%"=="1" (call :vriga INFO "Driver e app non verificati: internet non disponibile" & goto verifica_sistema)
call :winget_check
set "PS=$ErrorActionPreference='SilentlyContinue'; $global:a=0; function Riga($t,$x){ $c=@{OK='Green';ATT='Yellow';INFO='Gray'}[$t]; $g=@{OK='[OK] ';ATT='[!!] ';INFO='[i]  '}[$t]; Write-Host ('  ' + $g + $x) -ForegroundColor $c; Add-Content -LiteralPath $env:VER -Value ($g + $x); if($t -eq 'ATT'){ $global:a++ } }"
set "PS=%PS%; Write-Host '  ...cerco driver in attesa su Windows Update'; try { $q=(New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher(); $r=$q.Search('IsInstalled=0 and Type=''Driver'' and IsHidden=0'); $fw=@(); $dr=@(); foreach($u in $r.Updates){ $t=[string]$u.Title; if(([string]$u.DriverClass -match 'Firmware') -or ($t -match 'Firmware|BIOS|UEFI')){ $fw+=$t } else { $dr+=$t } }; if($dr.Count -eq 0){ Riga 'OK' 'Driver: nessun aggiornamento in attesa su Windows Update' } else { Riga 'ATT' ([string]$dr.Count + ' driver da installare: esegui l''opzione 6'); foreach($t in $dr){ Riga 'INFO' ('     ' + $t) } }; foreach($t in $fw){ Riga 'ATT' ('Aggiornamento BIOS o firmware disponibile, installalo con l''app del produttore: ' + $t) } } catch { Riga 'INFO' 'Windows Update non raggiungibile: driver non verificati' }"
set "PS=%PS%; if($env:WG -eq '1'){ Write-Host '  ...controllo gli aggiornamenti delle app'; [Console]::OutputEncoding=[Text.Encoding]::UTF8; $o=@(& winget upgrade --accept-source-agreements 2>$null); $i=0; while($i -lt $o.Count -and $o[$i] -notmatch '^-{10,}'){ $i++ }; $n=@(); for($j=$i+1; $j -lt $o.Count; $j++){ $w=[string]$o[$j]; if([string]::IsNullOrWhiteSpace($w)){ break }; if($w -notmatch '^\d+ \S'){ $n+=$w.Trim() } }; if($n.Count -eq 0){ Riga 'OK' 'App: nessun aggiornamento disponibile' } else { Riga 'ATT' ([string]$n.Count + ' app con aggiornamenti disponibili: esegui l''opzione 6'); foreach($x in $n){ Riga 'INFO' ('     ' + $x) } } } else { Riga 'INFO' 'winget non disponibile: app non verificate' }; exit $global:a"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%"
set /a V_ATT+=%errorlevel%
:verifica_sistema
set "PS=$ErrorActionPreference='SilentlyContinue'; $global:a=0; function Riga($t,$x){ $c=@{OK='Green';ATT='Yellow';INFO='Gray'}[$t]; $g=@{OK='[OK] ';ATT='[!!] ';INFO='[i]  '}[$t]; Write-Host ('  ' + $g + $x) -ForegroundColor $c; Add-Content -LiteralPath $env:VER -Value ($g + $x); if($t -eq 'ATT'){ $global:a++ } }"
set "PS=%PS%; $left=@(); foreach($x in @(%BLOAT%)){ $left+=@(Get-AppxPackage -AllUsers -Name $x | ForEach-Object { $_.Name }) }; $left=@($left | Select-Object -Unique); if($left.Count -eq 0){ Riga 'OK' 'App inutili: nessuna presente' } else { Riga 'ATT' ('App inutili presenti, ripeti l''opzione 3: ' + ($left -join ', ')) }"
set "PS=%PS%; $sv=@(Get-Service -Name DiagTrack,MapsBroker,RetailDemo | Where-Object { [string]$_.StartType -ne 'Disabled' }); if($sv.Count -eq 0){ Riga 'OK' 'Servizi superflui disattivati' } else { Riga 'ATT' ('Servizi ancora attivi, ripeti l''opzione 8: ' + (($sv | ForEach-Object { $_.Name }) -join ', ')) }"
set "PS=%PS%; $m=[regex]::Matches(((& powercfg /qh SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7) -join ' '),'0x([0-9a-fA-F]{8})'); if($m.Count -ge 2){ $ac=[Convert]::ToInt32($m[0].Groups[1].Value,16); $nm=@{0='Fresco e silenzioso';1='Bilanciato';2='Prestazioni massime'}[$ac]; if($nm){ Riga 'OK' ('Profilo termico attivo: ' + $nm) } else { Riga 'INFO' ('Profilo termico: impostazione di Windows o del produttore, valore ' + $ac) } } else { Riga 'INFO' 'Profilo termico non leggibile' }"
set "PS=%PS%; $mm=Get-MMAgent; $cs=Get-CimInstance Win32_ComputerSystem; if($mm.MemoryCompression -and $cs.AutomaticManagedPagefile){ Riga 'OK' 'Memoria: compressione attiva e file di paging gestito da Windows' } else { Riga 'ATT' 'Memoria: compressione o file di paging non ottimali, ripeti l''opzione 8' }"
set "PS=%PS%; $tr=(& fsutil behavior query DisableDeleteNotify) -join ' '; if($tr -match 'NTFS DisableDeleteNotify\s*=\s*0'){ Riga 'OK' 'TRIM attivo per gli SSD' } elseif($tr -match 'NTFS DisableDeleteNotify\s*=\s*1'){ Riga 'ATT' 'TRIM disattivato: ripeti l''opzione 10' } else { Riga 'INFO' 'Stato TRIM non leggibile' }"
set "PS=%PS%; $v=Get-Volume -DriveLetter $env:DRV; if($v.Size){ $pc=[math]::Round(100*$v.SizeRemaining/$v.Size); if($pc -ge 15){ Riga 'OK' ('Spazio libero sul disco di sistema: ' + $pc + ' percento') } else { Riga 'ATT' ('Spazio libero solo ' + $pc + ' percento: libera spazio con l''opzione 4 o con WizTree') } }"
set "PS=%PS%; $bd=@(Get-PhysicalDisk | Where-Object { $_.BusType -notmatch 'USB' -and $_.HealthStatus -and $_.HealthStatus -ne 'Healthy' }); if($bd.Count -eq 0){ Riga 'OK' 'Salute dei dischi interni: buona' } else { Riga 'ATT' ('Disco con problemi, fai subito un backup: ' + (($bd | ForEach-Object { $_.FriendlyName }) -join ', ')) }"
set "PS=%PS%; $mp=Get-MpComputerStatus; if(-not $mp){ Riga 'INFO' 'Stato antivirus non leggibile' } elseif($mp.AMRunningMode -and [string]$mp.AMRunningMode -ne 'Normal'){ Riga 'INFO' 'Antivirus di terze parti attivo: controllalo dalla sua app' } elseif($mp.AntivirusEnabled -and $mp.RealTimeProtectionEnabled -and $mp.AntivirusSignatureAge -le 3){ Riga 'OK' 'Antivirus attivo e aggiornato' } else { Riga 'ATT' 'Antivirus disattivato o con firme vecchie: apri Sicurezza di Windows' }; exit $global:a"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS%"
set /a V_ATT+=%errorlevel%
echo.
echo  ==========================================================
if %V_ATT% EQU 0 echo   RISULTATO: tutto a posto, nessun punto da controllare.
if %V_ATT% GTR 0 echo   RISULTATO: %V_ATT% punti da controllare, segnati qui sopra con [!!]
echo   Report salvato in: "%VER%"
echo  ==========================================================
>>"%VER%" echo RISULTATO: %V_ATT% punti da controllare
call :logfile "VERIFICA: %V_ATT% punti da controllare - report in verifica.txt"
exit /b

:vriga
if "%~1"=="ATT" set /a V_ATT+=1
set "VT=[i]  "
if "%~1"=="OK" set "VT=[OK] "
if "%~1"=="ATT" set "VT=[!!] "
echo   %VT%%~2
>>"%VER%" echo %VT%%~2
exit /b
:: ==========================================================================
:: Opzione 14: fa la verifica e ripara solo i punti che trova. Se c'e' un riavvio in
:: sospeso riavvia prima il PC e riparte da sola; alla fine riavvia e rifa' la verifica,
:: cosi' il rapporto finale arriva in chat senza fare altro.
:ripara_tutto
cls
echo.
echo RIPARA TUTTO - prima di iniziare:
echo  - salva il lavoro aperto: il PC si riavviera' da solo, anche piu' volte
echo  - durata: 30-60 minuti, resta connesso a internet e alla corrente
echo  - alla fine, dopo il riavvio, la verifica parte da sola e il rapporto arriva in chat
echo.
choice /c SN /m " Iniziare"
if errorlevel 2 goto menu
call :titolo "RIPARA TUTTO"
call :riavvio_sospeso
if not "%RIAVVIO%"=="1" goto ripara_tutto_fase2
call :log "Riavvio in sospeso: riavvio il PC tra 60 secondi, poi la riparazione riparte da sola"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v RinascitaPC /t REG_SZ /d "\"%SELF%\" ripara" /f >nul 2>&1
call :rapporto
shutdown /r /t 60 /c "RinascitaPC: riavvio per continuare la riparazione. Salva il lavoro aperto."
exit

:ripara_tutto_fase2
set "ARG1="
set "MODO=TUTTO"
call :log "=== RIPARA TUTTO su %HW_NOME% ==="
:: Prima la verifica (sola lettura), poi solo le correzioni dei punti segnalati.
call :verifica
for %%f in (RIPARA PREST AGG AV BLOAT DISCHI PULIZIA) do set "F_%%f="
findstr /l /c:"Immagine di Windows danneggiata" /c:"Immagine di Windows non riparabile" /c:"File di sistema danneggiati" "%VER%" >nul 2>&1 && set "F_RIPARA=1"
findstr /l /c:"Servizi ancora attivi" /c:"compressione o file di paging non ottimali" "%VER%" >nul 2>&1 && set "F_PREST=1"
findstr /l /c:"app con aggiornamenti disponibili" /c:"driver da installare" "%VER%" >nul 2>&1 && set "F_AGG=1"
findstr /l /c:"Antivirus disattivato" "%VER%" >nul 2>&1 && set "F_AV=1"
findstr /l /c:"App inutili presenti" "%VER%" >nul 2>&1 && set "F_BLOAT=1"
findstr /l /c:"TRIM disattivato" "%VER%" >nul 2>&1 && set "F_DISCHI=1"
findstr /l /c:"Spazio libero solo" "%VER%" >nul 2>&1 && set "F_PULIZIA=1"
set "PIANO="
if defined F_RIPARA set "PIANO=%PIANO% riparazione-Windows"
if defined F_PREST set "PIANO=%PIANO% servizi-e-memoria"
if defined F_AGG set "PIANO=%PIANO% aggiornamenti"
if defined F_AV set "PIANO=%PIANO% antivirus"
if defined F_BLOAT set "PIANO=%PIANO% app-inutili"
if defined F_DISCHI set "PIANO=%PIANO% dischi"
if defined F_PULIZIA set "PIANO=%PIANO% pulizia"
if not defined PIANO goto ripara_tutto_niente
call :log "Da sistemare secondo la verifica:%PIANO%"
:: RINASCITA_SOLOPIANO (usata nelle prove su GitHub): mostra il piano senza modificare nulla
if defined RINASCITA_SOLOPIANO goto ripara_tutto_niente_fine
if not defined RP_FATTO call :ripristino
if defined ANNULLA goto ripara_tutto_annulla
if defined F_BLOAT call :bloatware
if defined F_PULIZIA call :pulizia
if defined F_RIPARA call :ripara
if defined F_PREST call :prestazioni
if defined F_AGG call :aggiorna
if defined F_DISCHI call :dischi
if defined F_AV call :antivirus_on
call :log "=== RIPARA TUTTO COMPLETATO ==="
set "MODO="
call :esito_riepilogo
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v RinascitaPC /t REG_SZ /d "\"%SELF%\" verifica" /f >nul 2>&1
call :log "Riavvio il PC tra 2 minuti: dopo il riavvio la verifica parte da sola"
call :rapporto
shutdown /r /t 120 /c "RinascitaPC: riparazione finita. Riavvio tra 2 minuti, poi parte la verifica."
exit

:ripara_tutto_niente
call :log "La verifica non ha trovato niente da sistemare: nessuna modifica"
:ripara_tutto_niente_fine
set "MODO="
call :esito_riepilogo
call :rapporto
echo.
pause
goto menu

:ripara_tutto_annulla
call :log "Riparazione annullata: senza punto di ripristino non modifico Windows"
set "ANNULLA="
set "MODO="
call :rapporto
pause
goto menu

:verifica_dopo_ripara
set "ARG1="
call :esito_reset
call :verifica
call :rapporto
echo.
echo Verifica dopo la riparazione finita. Premi un tasto per tornare al menu.
pause >nul
goto menu

:riavvio_sospeso
set "RIAVVIO=0"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" >nul 2>&1 && set "RIAVVIO=1"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" >nul 2>&1 && set "RIAVVIO=1"
exit /b

:antivirus_on
call :log "Antivirus: riaccendo la protezione in tempo reale di Microsoft Defender, se e' l'antivirus in uso"
powershell -NoProfile -Command "$mp=Get-MpComputerStatus -ErrorAction SilentlyContinue; if(-not $mp){ exit 3 }; if($mp.AMRunningMode -and [string]$mp.AMRunningMode -ne 'Normal'){ exit 2 }; if(-not $mp.RealTimeProtectionEnabled){ try { Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop } catch {}; Start-Sleep -Seconds 3; $mp=Get-MpComputerStatus }; if($mp.RealTimeProtectionEnabled -and $mp.AntivirusSignatureAge -le 3){ exit 0 }; exit 1"
set "RC=%errorlevel%"
if "%RC%"=="0" (call :esito "Antivirus" OK "attivo e aggiornato" & exit /b)
if "%RC%"=="2" (call :esito "Antivirus" OK "antivirus di terze parti attivo: controllalo dalla sua app" & exit /b)
if "%RC%"=="3" (call :esito "Antivirus" ATT "stato non leggibile: apri Sicurezza di Windows" & exit /b)
call :esito "Antivirus" ATT "protezione in tempo reale spenta o firme vecchie: apri Sicurezza di Windows - Protezione da virus e minacce"
exit /b

:: ==========================================================================
:: Opzione 15: analisi completa, sola lettura. Lo script PowerShell e' in fondo a
:: questo file, dopo il segnaposto: viene estratto nella cartella della sessione.
:analisi_completa
call :titolo "ANALISI COMPLETA DEL PC - SOLA LETTURA"
call :log "Analizzo hardware, software, avvio, sicurezza ed errori di Windows (3-6 minuti)"
set "APS=%OUT%\analisi.ps1"
powershell -NoProfile -Command "$t=[IO.File]::ReadAllText($env:SELF); $p=($t -split ('#PS' + '_ANALISI#'),2); if($p.Count -lt 2){ exit 1 }; [IO.File]::WriteAllText($env:APS, $p[1], (New-Object Text.UTF8Encoding($true))); exit 0"
if errorlevel 1 (call :esito "Analisi completa" ATT "parte di analisi non trovata nello script" & exit /b)
powershell -NoProfile -ExecutionPolicy Bypass -File "%APS%"
set "RC=%errorlevel%"
del "%APS%" >nul 2>&1
if not exist "%OUT%\analisi_completa.txt" (call :esito "Analisi completa" ATT "file non creato" & exit /b)
if "%RC%"=="0" (call :esito "Analisi completa" OK "nessun problema trovato") else (call :esito "Analisi completa" OK "fatta, %RC% punti da controllare nella sezione ANALISI COMPLETA")
exit /b

:: Da qui in giu' c'e' solo lo script PowerShell dell'opzione 15: il batch non arriva mai qui.
#PS_ANALISI#
# ANALISI COMPLETA RinascitaPC - sola lettura, non modifica nulla
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
if ($env:OUT -and (Test-Path -LiteralPath $env:OUT)) { $dir = $env:OUT }
else { $dir = Join-Path ([Environment]::GetFolderPath('Desktop')) ("RinascitaPC_analisi_" + (Get-Date -Format 'yyyyMMdd_HHmm')) }
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$out = Join-Path $dir 'analisi_completa.txt'
$body = Join-Path $dir 'corpo.tmp'
$global:issues = New-Object System.Collections.Generic.List[string]
$start = Get-Date

function W([string]$t) { Add-Content -LiteralPath $body -Value $t -Encoding UTF8 }
function KV($k, $v) { '  {0,-36}: {1}' -f $k, $v }
function Flag([string]$t) { $global:issues.Add($t); "  [!!] $t" }
function Info([string]$t) { "  [i]  $t" }
function GB($b) { if ($b) { [math]::Round($b / 1GB, 1) } else { 0 } }
function Sec([string]$n, [scriptblock]$blocco) {
    Write-Host "Analizzo: $n" -ForegroundColor Cyan
    W ''; W ('=' * 78); W "  $n"; W ('=' * 78)
    try { $r = & $blocco 2>&1 | Out-String -Width 300; if ($r.Trim()) { W $r.TrimEnd() } }
    catch { W "  errore in questa sezione: $($_.Exception.Message)" }
}
function EvData($e) { $h = @{}; try { ([xml]$e.ToXml()).Event.EventData.Data | ForEach-Object { $h[$_.Name] = $_.'#text' } } catch {}; $h }
function FolderSize($p) { if (Test-Path -LiteralPath $p) { (Get-ChildItem -LiteralPath $p -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum } else { $null } }
function DataOra($d) { if ($d) { $d.ToString('dd-MM-yyyy HH:mm') } else { '?' } }
function Giorno($d) { if ($d) { $d.ToString('dd-MM-yyyy') } else { '?' } }
function Ev($h, $max) { try { if ($max) { @(Get-WinEvent -FilterHashtable $h -MaxEvents $max -ErrorAction Stop) } else { @(Get-WinEvent -FilterHashtable $h -ErrorAction Stop) } } catch { @() } }

$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$bios = Get-CimInstance Win32_BIOS
$bb = Get-CimInstance Win32_BaseBoard
$cpu = @(Get-CimInstance Win32_Processor)

# ---------------------------------------------------------------- SISTEMA
Sec 'SISTEMA' {
    $nt = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $tipo = switch ($cs.PCSystemType) { 1 { 'fisso' } 2 { 'portatile' } 3 { 'workstation' } default { "codice $($cs.PCSystemType)" } }
    KV 'Produttore' $cs.Manufacturer
    KV 'Modello' $cs.Model
    KV 'Tipo' $tipo
    KV 'Seriale' $bios.SerialNumber
    KV 'Scheda madre' "$($bb.Manufacturer) $($bb.Product) $($bb.Version)"
    KV 'BIOS' "$($bios.SMBIOSBIOSVersion) del $(Giorno $bios.ReleaseDate)"
    KV 'Windows' "$($os.Caption) $($nt.DisplayVersion) - build $($os.BuildNumber).$($nt.UBR) - $($os.OSArchitecture)"
    KV 'Installato il' (DataOra $os.InstallDate)
    KV 'Ultimo avvio' (DataOra $os.LastBootUpTime)
    $up = (Get-Date) - $os.LastBootUpTime
    KV 'Acceso da' ('{0} giorni {1} ore {2} minuti' -f $up.Days, $up.Hours, $up.Minutes)
    $secb = try { if (Confirm-SecureBootUEFI -ErrorAction Stop) { 'attivo' } else { 'disattivato' } } catch { 'non supportato (BIOS legacy)' }
    KV 'Secure Boot' $secb
    $tpm = Get-Tpm
    $tv = (Get-CimInstance -Namespace root/cimv2/security/microsofttpm -ClassName Win32_Tpm).SpecVersion
    KV 'TPM' $(if ($tpm.TpmPresent) { "presente, pronto: $($tpm.TpmReady), versione $(($tv -split ',')[0])" } else { 'assente o disattivato' })
    $lic = Get-CimInstance SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL AND ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f'" | Select-Object -First 1
    $ls = switch ($lic.LicenseStatus) { 1 { 'attivato' } 0 { 'non attivato' } default { "stato $($lic.LicenseStatus)" } }
    KV 'Attivazione Windows' $ls
    if ($lic -and $lic.LicenseStatus -ne 1) { Flag 'Windows non risulta attivato' }
    KV 'Lingua' (Get-Culture).Name
    KV 'Fuso orario' (Get-TimeZone).DisplayName
    KV 'Utente' "$env:USERNAME su $env:COMPUTERNAME"
}

# ---------------------------------------------------------------- PROCESSORE
Sec 'PROCESSORE' {
    foreach ($c in $cpu) {
        KV 'Modello' $c.Name.Trim()
        KV 'Core / thread' "$($c.NumberOfCores) / $($c.NumberOfLogicalProcessors)"
        KV 'Frequenza massima' "$($c.MaxClockSpeed) MHz"
        KV 'Cache L2 / L3' "$($c.L2CacheSize) KB / $($c.L3CacheSize) KB"
        KV 'Virtualizzazione nel BIOS' $(if ($c.VirtualizationFirmwareEnabled) { 'attiva' } else { 'disattivata' })
    }
    $load = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime
    KV 'Carico adesso' "$load %"
    if ($load -gt 80) { Flag "Processore molto carico durante l'analisi ($load %)" }
}

# ---------------------------------------------------------------- RAM
Sec 'MEMORIA RAM' {
    $tot = $cs.TotalPhysicalMemory; $free = $os.FreePhysicalMemory * 1KB
    $usedPct = [math]::Round(($tot - $free) / $tot * 100)
    KV 'Totale utilizzabile' "$(GB $tot) GB"
    KV 'Occupata adesso' "$(GB ($tot - $free)) GB ($usedPct %)"
    if ($usedPct -gt 85) { Flag "RAM occupata all'$usedPct %" }
    $arr = Get-CimInstance Win32_PhysicalMemoryArray
    $mods = @(Get-CimInstance Win32_PhysicalMemory)
    KV 'Slot totali / occupati' "$(($arr | Measure-Object MemoryDevices -Sum).Sum) / $($mods.Count)"
    KV 'Massimo supportato' "$([math]::Round((($arr | Measure-Object MaxCapacityEx -Sum).Sum) / 1MB)) GB"
    $i = 0
    foreach ($m in $mods) {
        $i++
        $pn = "$($m.PartNumber)".Trim()
        $mf = "$($m.Manufacturer)".Trim()
        if (-not $mf -or $mf -match 'Unknown|^0+$|Undefined') {
            $mf = switch -Regex ($pn) {
                '^CT|^BL' { 'Crucial (dal codice)'; break }
                '^MT|^\d+ATF' { 'Micron (dal codice)'; break }
                '^M3|^M4' { 'Samsung (dal codice)'; break }
                '^HMA|^HMT|^HMC' { 'SK hynix (dal codice)'; break }
                '^KVR|^KF|^KCP|^KHX' { 'Kingston (dal codice)'; break }
                '^F3|^F4|^F5' { 'G.Skill (dal codice)'; break }
                '^CM' { 'Corsair (dal codice)'; break }
                default { 'sconosciuto' }
            }
        }
        $type = switch ($m.SMBIOSMemoryType) { 24 { 'DDR3' } 26 { 'DDR4' } 30 { 'LPDDR4' } 34 { 'DDR5' } 35 { 'LPDDR5' } default { "tipo $($m.SMBIOSMemoryType)" } }
        KV "Modulo $i" ("{0} GB {1} - {2} {3} - nominale {4} MHz, in uso {5} MHz - slot '{6}' banco '{7}'" -f (GB $m.Capacity), $type, $mf, $pn, $m.Speed, $m.ConfiguredClockSpeed, $m.DeviceLocator, $m.BankLabel)
    }
    if (@($mods | Select-Object -ExpandProperty Capacity -Unique).Count -gt 1) { Info 'Moduli di capacita diversa: il dual channel lavora solo su una parte della RAM' }
    $mm = Get-MMAgent
    KV 'Compressione memoria' $(if ($mm.MemoryCompression) { 'attiva' } else { 'disattivata' })
    KV 'File di paging automatico' $cs.AutomaticManagedPagefile
    Get-CimInstance Win32_PageFileUsage | ForEach-Object { KV "File di paging $($_.Name)" "$($_.AllocatedBaseSize) MB, in uso $($_.CurrentUsage) MB, picco $($_.PeakUsage) MB" }
}

# ---------------------------------------------------------------- GRAFICA
Sec 'GRAFICA E SCHERMI' {
    foreach ($g in Get-CimInstance Win32_VideoController) {
        KV 'Scheda' $g.Name
        KV '  driver' "$($g.DriverVersion) del $(Giorno $g.DriverDate)"
        if ($g.CurrentHorizontalResolution) { KV '  risoluzione' "$($g.CurrentHorizontalResolution)x$($g.CurrentVerticalResolution) a $($g.CurrentRefreshRate) Hz" }
        if ($g.DriverDate -and $g.DriverDate -lt (Get-Date).AddYears(-2)) { Flag "Driver grafico vecchio: $($g.Name) del $(Giorno $g.DriverDate)" }
    }
    Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorID | ForEach-Object {
        $n = -join ($_.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })
        $p = -join ($_.ManufacturerName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })
        KV 'Schermo' "$p $n - anno $($_.YearOfManufacture)"
    }
}

# ---------------------------------------------------------------- DISCHI
Sec 'DISCHI E SPAZIO' {
    foreach ($d in Get-PhysicalDisk) {
        $r = $d | Get-StorageReliabilityCounter
        KV 'Disco' "$($d.FriendlyName) - $($d.MediaType) $($d.BusType) - $(GB $d.Size) GB - stato $($d.HealthStatus)"
        if ($r) {
            KV '  temperatura' "$($r.Temperature) C (massima registrata $($r.TemperatureMax) C)"
            KV '  usura' "$($r.Wear) %"
            KV '  ore di accensione' $r.PowerOnHours
            KV '  errori lettura / scrittura' "$($r.ReadErrorsTotal) / $($r.WriteErrorsTotal)"
            if ($r.Wear -ge 70) { Flag "Disco $($d.FriendlyName) consumato al $($r.Wear) %" }
            if ($r.Temperature -ge 65) { Flag "Disco $($d.FriendlyName) caldo: $($r.Temperature) C" }
        }
        if ($d.HealthStatus -ne 'Healthy') { Flag "Disco $($d.FriendlyName) in stato $($d.HealthStatus)" }
    }
    ''
    foreach ($v in Get-Volume | Where-Object { $_.DriveLetter } | Sort-Object DriveLetter) {
        $pct = if ($v.Size) { [math]::Round($v.SizeRemaining / $v.Size * 100) } else { 0 }
        KV "Unita $($v.DriveLetter):" "$($v.FileSystemLabel) $($v.FileSystem) - liberi $(GB $v.SizeRemaining) GB su $(GB $v.Size) GB ($pct %)"
        if ("$($v.DriveLetter):" -eq $env:SystemDrive -and $pct -lt 15) { Flag "Poco spazio sul disco di sistema: $pct % libero" }
    }
    $trim = fsutil behavior query DisableDeleteNotify
    KV 'TRIM (0 = attivo)' ((($trim | Select-Object -First 1) -replace '\s+', ' ').Trim())
    ''
    'Cartelle che occupano spazio:'
    $cart = [ordered]@{
        'Temp utente'                = $env:TEMP
        'Temp di Windows'            = "$env:windir\Temp"
        'Download di Windows Update' = "$env:windir\SoftwareDistribution\Download"
        'Windows.old'                = "$env:SystemDrive\Windows.old"
        'Cestino'                    = "$env:SystemDrive\`$Recycle.Bin"
        'Cartella Download'          = (Join-Path $env:USERPROFILE 'Downloads')
    }
    foreach ($k in $cart.Keys) { $s = FolderSize $cart[$k]; if ($null -ne $s) { KV "  $k" "$(GB $s) GB" } }
}

# ---------------------------------------------------------------- BATTERIA
Sec 'BATTERIA E ALIMENTAZIONE' {
    $bat = @(Get-CimInstance Win32_Battery)
    if ($bat.Count -eq 0) {
        Info 'Windows non vede nessuna batteria'
        Get-PnpDevice -Class Battery | ForEach-Object { KV '  dispositivo' "$($_.FriendlyName) - stato $($_.Status)" }
        if ($cs.PCSystemType -eq 2) { Flag 'Portatile senza batteria rilevata: batteria guasta o scollegata, oppure driver ACPI della batteria disattivato' }
    }
    else {
        foreach ($b in $bat) {
            KV 'Batteria' "$($b.Name) - carica $($b.EstimatedChargeRemaining) %"
            $st = switch ($b.BatteryStatus) { 1 { 'in scarica' } 2 { 'collegato alla corrente' } 3 { 'carica completa' } 6 { 'in carica' } default { "codice $($b.BatteryStatus)" } }
            KV '  stato' $st
        }
        $des = (Get-CimInstance -Namespace root/wmi -ClassName BatteryStaticData | Select-Object -First 1).DesignedCapacity
        $full = (Get-CimInstance -Namespace root/wmi -ClassName BatteryFullChargedCapacity | Select-Object -First 1).FullChargedCapacity
        $cyc = (Get-CimInstance -Namespace root/wmi -ClassName BatteryCycleCount | Select-Object -First 1).CycleCount
        $bs = Get-CimInstance -Namespace root/wmi -ClassName BatteryStatus | Select-Object -First 1
        if ($des -and $full) {
            $h = [math]::Round($full / $des * 100)
            KV '  capacita originale' "$des mWh"
            KV '  capacita oggi' "$full mWh ($h % dell'originale)"
            if ($h -lt 70) { Flag "Batteria consumata: tiene solo il $h % della carica originale" }
        }
        if ($cyc) { KV '  cicli di carica' $cyc }
        if ($bs) { KV '  alimentatore collegato' $bs.PowerOnline; KV '  tensione' "$($bs.Voltage) mV" }
    }
    powercfg /batteryreport /output "$dir\batteria.html" | Out-Null
    if (Test-Path "$dir\batteria.html") { Info 'Rapporto dettagliato della batteria salvato in batteria.html' }
    ''
    KV 'Piano di risparmio energia' ((powercfg /getactivescheme) -replace '^.*?:\s*', '')
    $hib = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power').HiberbootEnabled
    KV 'Avvio rapido' $(if ($hib -eq 1) { 'attivo' } else { 'disattivato' })
}

# ---------------------------------------------------------------- TEMPERATURE
Sec 'TEMPERATURE' {
    $lette = 0
    foreach ($t in Get-CimInstance Win32_PerfFormattedData_Counters_ThermalZoneInformation) {
        if ($t.Temperature) { $c = [math]::Round($t.Temperature - 273.15, 1); $lette++; KV $t.Name "$c C"; if ($c -ge 90) { Flag "Temperatura alta: $c C ($($t.Name))" } }
    }
    if (-not $lette) {
        foreach ($t in Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature) {
            $c = [math]::Round($t.CurrentTemperature / 10 - 273.15, 1); $lette++; KV $t.InstanceName "$c C"; if ($c -ge 90) { Flag "Temperatura alta: $c C" }
        }
    }
    if (-not $lette) { Info 'Sensori di temperatura non leggibili da Windows su questo PC (la temperatura dei dischi e'' nella sezione DISCHI)' }
}

# ---------------------------------------------------------------- RETE
Sec 'RETE E INTERNET' {
    foreach ($a in Get-NetAdapter | Sort-Object Status) { KV $a.Name "$($a.InterfaceDescription) - $($a.Status) - $($a.LinkSpeed) - MAC $($a.MacAddress)" }
    ''
    $attive = @(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway })
    foreach ($c in $attive) {
        KV 'Connessione attiva' $c.InterfaceAlias
        KV '  IP' (($c.IPv4Address.IPAddress) -join ', ')
        KV '  router' (($c.IPv4DefaultGateway.NextHop) -join ', ')
        KV '  DNS' ((($c.DNSServer | Where-Object { $_.AddressFamily -eq 2 }).ServerAddresses) -join ', ')
    }
    ''
    'Wi-Fi:'
    netsh wlan show interfaces | Where-Object { $_ -match ':' } | ForEach-Object { '  ' + $_.Trim() }
    ''
    $gw = if ($attive.Count) { $attive[0].IPv4DefaultGateway.NextHop | Select-Object -First 1 } else { $null }
    foreach ($t in @(@('router', $gw), @('Internet 8.8.8.8', '8.8.8.8'), @('Internet 1.1.1.1', '1.1.1.1'))) {
        if (-not $t[1]) { continue }
        $p = @(Test-Connection -ComputerName $t[1] -Count 4 -ErrorAction SilentlyContinue)
        if ($p.Count) {
            $avg = [math]::Round(($p | Measure-Object ResponseTime -Average).Average)
            KV "Ping $($t[0])" "$avg ms, risposte $($p.Count) su 4"
            if ($t[0] -ne 'router' -and $avg -gt 100) { Flag "Internet lento: ping $avg ms verso $($t[1])" }
        }
        else { KV "Ping $($t[0])" 'nessuna risposta'; Flag "Nessuna risposta dal ping verso $($t[0])" }
    }
    $dns = Measure-Command { Resolve-DnsName www.google.com -DnsOnly -ErrorAction SilentlyContinue | Out-Null }
    KV 'Tempo di risposta DNS' "$([math]::Round($dns.TotalMilliseconds)) ms"
}

# ---------------------------------------------------------------- PERIFERICHE
Sec 'PERIFERICHE E DRIVER' {
    $bad = @(Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne 'OK' -and $_.Status -ne 'Unknown' })
    if ($bad.Count) { foreach ($d in $bad) { Flag "Dispositivo con problemi: $(if ($d.FriendlyName) { $d.FriendlyName } else { $d.InstanceId }) [$($d.Class)] - stato $($d.Status) - codice $($d.ConfigManagerErrorCode)" } }
    else { Info 'Tutti i dispositivi funzionano' }
    KV 'Dispositivi presenti' (@(Get-PnpDevice -PresentOnly).Count)
    ''
    'Audio:'; Get-CimInstance Win32_SoundDevice | ForEach-Object { '  ' + $_.Name + ' - ' + $_.Status }
    'Bluetooth:'; Get-PnpDevice -Class Bluetooth -PresentOnly | ForEach-Object { '  ' + $_.FriendlyName + ' - ' + $_.Status }
    'Fotocamere:'; Get-PnpDevice -PresentOnly | Where-Object { $_.Class -in 'Camera', 'Image' } | ForEach-Object { '  ' + $_.FriendlyName + ' - ' + $_.Status }
    'USB:'; Get-PnpDevice -PresentOnly -Class USB | ForEach-Object { '  ' + $_.FriendlyName }
    ''
    'Driver non Microsoft (dal piu vecchio):'
    Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DriverProviderName -and $_.DriverProviderName -notmatch 'Microsoft' -and $_.DeviceName } | Sort-Object DriverDate | ForEach-Object {
        '  {0} - {1} - {2} - {3}' -f $(if ($_.DriverDate) { $_.DriverDate.ToString('dd-MM-yyyy') } else { '?' }), $_.DriverVersion, $_.DriverProviderName, $_.DeviceName
    }
}

# ---------------------------------------------------------------- PROGRAMMI
Sec 'PROGRAMMI INSTALLATI' {
    $keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $apps = @(Get-ItemProperty $keys | Where-Object { $_.DisplayName -and -not $_.SystemComponent -and -not $_.ParentKeyName } | Sort-Object DisplayName -Unique)
    KV 'Programmi desktop' $apps.Count
    '  nome | versione | editore | installato il | dimensione'
    foreach ($a in $apps) {
        $dt = if ("$($a.InstallDate)" -match '^\d{8}$') { $a.InstallDate.Substring(6, 2) + '-' + $a.InstallDate.Substring(4, 2) + '-' + $a.InstallDate.Substring(0, 4) } else { '' }
        $mb = if ($a.EstimatedSize) { '{0} MB' -f [math]::Round($a.EstimatedSize / 1024) } else { '' }
        '  {0} | {1} | {2} | {3} | {4}' -f $a.DisplayName, $a.DisplayVersion, $a.Publisher, $dt, $mb
    }
    ''
    $store = @(Get-AppxPackage | Where-Object { -not $_.IsFramework -and $_.SignatureKind -eq 'Store' -and $_.Name -notmatch '^Microsoft\.(VCLibs|NET|UI\.Xaml|WindowsAppRuntime)' } | Sort-Object Name)
    KV 'App dello Store' $store.Count
    $store | ForEach-Object { '  {0} {1}' -f $_.Name, $_.Version }
}

# ---------------------------------------------------------------- AGGIORNAMENTI
Sec 'AGGIORNAMENTI' {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $u = @(winget upgrade --include-unknown --accept-source-agreements --disable-interactivity 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -match '\w' })
        'Programmi da aggiornare (winget):'
        $u | ForEach-Object { '  ' + $_.Trim() }
        $n = @($u | Where-Object { $_ -match '\swinget\s*$' }).Count
        if ($n -gt 0) { Flag "$n programmi da aggiornare (RinascitaPC opzione 6)" }
    }
    else { Info 'winget non disponibile' }
    ''
    'Ultimi aggiornamenti di Windows installati:'
    $hf = @(Get-HotFix | Where-Object { $_.InstalledOn } | Sort-Object InstalledOn -Descending | Select-Object -First 8)
    $hf | ForEach-Object { '  {0} - {1} - {2}' -f $_.HotFixID, $_.Description, $_.InstalledOn.ToString('dd-MM-yyyy') }
    if ($hf.Count -and $hf[0].InstalledOn -lt (Get-Date).AddDays(-45)) { Flag "Windows Update fermo: ultimo aggiornamento il $($hf[0].InstalledOn.ToString('dd-MM-yyyy'))" }
}

# ---------------------------------------------------------------- AVVIO
Sec 'AVVIO DI WINDOWS' {
    $log = 'Microsoft-Windows-Diagnostics-Performance/Operational'
    $ev = @(Ev @{ LogName = $log; Id = 100 } 5)
    if ($ev.Count) {
        foreach ($e in $ev) {
            $d = EvData $e
            KV ('Avvio del ' + (DataOra $e.TimeCreated)) ('{0} s (fino al desktop {1} s + dopo il desktop {2} s)' -f [math]::Round([double]$d.BootTime / 1000, 1), [math]::Round([double]$d.MainPathBootTime / 1000, 1), [math]::Round([double]$d.BootPostBootTime / 1000, 1))
        }
        $bt = [math]::Round([double](EvData $ev[0]).BootTime / 1000)
        if ($bt -gt 60) { Flag "Avvio lento: $bt secondi" }
        $slow = @(Ev @{ LogName = $log; Id = 101..110; StartTime = (Get-Date).AddDays(-60) })
        if ($slow.Count) {
            'Cosa rallenta l''avvio (ultimi 60 giorni):'
            $slow | ForEach-Object { $d = EvData $_; [pscustomobject]@{ Nome = $(if ($d.FriendlyName) { $d.FriendlyName } else { $d.Name }); Ritardo = [double]$d.DegradationTime } } |
                Group-Object Nome | ForEach-Object { [pscustomobject]@{ Nome = $_.Name; Volte = $_.Count; Medio = [math]::Round(($_.Group | Measure-Object Ritardo -Average).Average) } } |
                Sort-Object Medio -Descending | Select-Object -First 15 | ForEach-Object { '  {0} - {1} volte - ritardo medio {2} ms' -f $_.Nome, $_.Volte, $_.Medio }
        }
    }
    else { Info 'Registro dei tempi di avvio non disponibile' }
    ''
    'Programmi all''avvio:'
    $appr = @{}
    foreach ($k in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder') {
        $p = Get-ItemProperty $k
        if ($p) { $p.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' -and $_.Value -is [byte[]] } | ForEach-Object { $appr[$_.Name] = ($_.Value[0] % 2 -eq 0) } }
    }
    $on = 0
    foreach ($s in Get-CimInstance Win32_StartupCommand) {
        $key = $s.Name
        $en = if ($appr.ContainsKey($key)) { $appr[$key] } elseif ($appr.ContainsKey("$key.lnk")) { $appr["$key.lnk"] } else { $true }
        if ($en) { $on++ }
        '  [{0}] {1} - {2}' -f $(if ($en) { 'attivo' } else { 'disattivato' }), $s.Name, $s.Command
    }
    KV 'Programmi attivi all''avvio' $on
    if ($on -gt 8) { Flag "Troppi programmi all'avvio: $on" }
    ''
    'Attivita pianificate non Microsoft:'
    Get-ScheduledTask | Where-Object { $_.State -ne 'Disabled' -and $_.TaskPath -notlike '\Microsoft\*' } | ForEach-Object { '  {0}{1} - {2}' -f $_.TaskPath, $_.TaskName, $_.State }
    ''
    'Servizi non Microsoft in esecuzione:'
    Get-CimInstance Win32_Service | Where-Object { $_.State -eq 'Running' -and $_.PathName -and $_.PathName -notmatch '\\Windows\\(system32|SysWOW64|servicing)\\|\\Windows Defender\\|\\Microsoft\\' } | Sort-Object DisplayName | ForEach-Object { '  {0} ({1}) - avvio {2}' -f $_.DisplayName, $_.Name, $_.StartMode }
    ''
    'Servizi automatici fermi:'
    Get-CimInstance Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } | Sort-Object DisplayName | ForEach-Object { '  {0} ({1})' -f $_.DisplayName, $_.Name }
}

# ---------------------------------------------------------------- PRESTAZIONI
Sec 'PRESTAZIONI IN QUESTO MOMENTO' {
    $procs = Get-Process
    KV 'Processi attivi' $procs.Count
    KV 'Handle aperti' (($procs | Measure-Object HandleCount -Sum).Sum)
    ''
    'I 15 programmi che usano piu RAM:'
    $procs | Group-Object ProcessName | ForEach-Object { [pscustomobject]@{ N = $_.Name; Q = $_.Count; MB = [math]::Round(($_.Group | Measure-Object WorkingSet64 -Sum).Sum / 1MB) } } |
        Sort-Object MB -Descending | Select-Object -First 15 | ForEach-Object { '  {0,-38} {1,6} MB  ({2} processi)' -f $_.N, $_.MB, $_.Q }
    ''
    'I 10 processi che usano piu processore adesso:'
    $nc = ($cpu | Measure-Object NumberOfLogicalProcessors -Sum).Sum
    if (-not $nc) { $nc = 1 }
    Get-CimInstance Win32_PerfFormattedData_PerfProc_Process | Where-Object { $_.Name -notin '_Total', 'Idle' } | Sort-Object PercentProcessorTime -Descending | Select-Object -First 10 |
        ForEach-Object { '  {0,-38} {1,5} %' -f $_.Name, [math]::Round($_.PercentProcessorTime / $nc, 1) }
}

# ---------------------------------------------------------------- SICUREZZA
Sec 'SICUREZZA' {
    $mp = Get-MpComputerStatus
    $av = @(Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct)
    foreach ($a in $av) { $acceso = ((([int]$a.productState) -shr 12) -band 0xF) -eq 1; KV 'Antivirus' "$($a.displayName) - $(if ($acceso) { 'attivo' } else { 'spento' })" }
    $other = @($av | Where-Object { $_.displayName -notmatch 'Defender' })
    if ($mp) {
        KV 'Defender protezione in tempo reale' $mp.RealTimeProtectionEnabled
        KV 'Defender firme aggiornate il' (DataOra $mp.AntivirusSignatureLastUpdated)
        KV 'Defender ultima scansione veloce' "$($mp.QuickScanAge) giorni fa"
        KV 'Protezione antimanomissione' $mp.IsTamperProtected
        if (-not $mp.RealTimeProtectionEnabled -and -not $other.Count) { Flag 'Antivirus spento: nessuna protezione in tempo reale' }
        if ($mp.AntivirusSignatureAge -gt 3 -and -not $other.Count) { Flag "Firme antivirus vecchie di $($mp.AntivirusSignatureAge) giorni" }
    }
    foreach ($f in Get-NetFirewallProfile) {
        KV "Firewall $($f.Name)" $(if ($f.Enabled) { 'attivo' } else { 'spento' })
        if (-not $f.Enabled) { Flag "Firewall $($f.Name) spento" }
    }
    $uac = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System').EnableLUA
    KV 'Controllo account utente (UAC)' $(if ($uac -eq 1) { 'attivo' } else { 'spento' })
    if ($uac -ne 1) { Flag 'Controllo account utente (UAC) spento' }
    $hvci = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity').Enabled
    KV 'Integrita della memoria' $(if ($hvci -eq 1) { 'attiva' } else { 'disattivata' })
    Get-BitLockerVolume | ForEach-Object { KV "Crittografia $($_.MountPoint)" "$($_.VolumeStatus) - protezione $($_.ProtectionStatus)" }
    $pend = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
    KV 'Riavvio in sospeso' $pend
    if ($pend) { Flag 'Riavvio in sospeso: riavvia il PC' }
}

# ---------------------------------------------------------------- INTEGRITA
Sec 'INTEGRITA DI WINDOWS' {
    $dism = @(DISM /Online /Cleanup-Image /CheckHealth 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -match '\S' })
    $dism | Select-Object -Last 3 | ForEach-Object { '  ' + $_.Trim() }
    if (@($dism | Where-Object { $_ -match 'riparabil|repairable|danneggiat|corrupt' }).Count) { Flag 'Immagine di Windows danneggiata: va riparata (DISM + SFC)' }
    ''
    'Ultimi risultati SFC (registro CBS):'
    Select-String -Path "$env:windir\Logs\CBS\CBS.log" -Pattern '\[SR\].*(Cannot repair|Repaired|corrupt|Verify complete)' | Select-Object -Last 8 | ForEach-Object { '  ' + $_.Line.Trim() }
}

# ---------------------------------------------------------------- ERRORI
Sec 'ERRORI, CRASH E SCHERMATE BLU' {
    $d30 = (Get-Date).AddDays(-30)
    $bsod = @(Ev @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'; Id = 1001; StartTime = (Get-Date).AddDays(-90) })
    KV 'Schermate blu (90 giorni)' $bsod.Count
    $bsod | Select-Object -First 5 | ForEach-Object { '    ' + (DataOra $_.TimeCreated) + ' - ' + ((("$($_.Message)") -split "`n")[0]).Trim() }
    if ($bsod.Count) { Flag "$($bsod.Count) schermate blu negli ultimi 90 giorni" }
    KV 'File minidump' (@(Get-ChildItem "$env:windir\Minidump" -Filter *.dmp).Count)
    $kp = @(Ev @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-Power'; Id = 41; StartTime = $d30 })
    KV 'Spegnimenti improvvisi (30 giorni)' $kp.Count
    if ($kp.Count -ge 3) { Flag "$($kp.Count) spegnimenti improvvisi negli ultimi 30 giorni" }
    $whea = @(Ev @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-WHEA-Logger'; StartTime = $d30 })
    KV 'Errori hardware WHEA (30 giorni)' $whea.Count
    if ($whea.Count) { Flag "$($whea.Count) errori hardware WHEA negli ultimi 30 giorni" }
    $de = @(Ev @{ LogName = 'System'; ProviderName = 'disk', 'Ntfs', 'stornvme', 'storahci'; Level = 1, 2, 3; StartTime = $d30 })
    KV 'Errori e avvisi del disco (30 giorni)' $de.Count
    if ($de.Count) { Flag "$($de.Count) errori o avvisi del disco negli ultimi 30 giorni" }
    ''
    'Programmi andati in crash (30 giorni):'
    Ev @{ LogName = 'Application'; Id = 1000; StartTime = $d30 } | ForEach-Object { "$($_.Properties[0].Value)" } |
        Group-Object | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object { '  {0} - {1} volte' -f $_.Name, $_.Count }
    foreach ($lg in 'System', 'Application') {
        ''
        "Errori piu frequenti nel registro $lg (7 giorni):"
        Ev @{ LogName = $lg; Level = 1, 2; StartTime = (Get-Date).AddDays(-7) } | Group-Object ProviderName, Id | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
            $m = "$($_.Group[0].Message)" -replace '\s+', ' '
            if ($m.Length -gt 160) { $m = $m.Substring(0, 160) + '...' }
            '  {0} volte - {1} - {2}' -f $_.Count, $_.Name, $m
        }
    }
}

# ---------------------------------------------------------------- FILE FINALE
$head = @()
$head += 'ANALISI COMPLETA RinascitaPC - vita, morte e miracoli del PC'
$head += "Creata il $(Get-Date -Format 'dd-MM-yyyy HH:mm') - $($cs.Manufacturer) $($cs.Model) - durata $([math]::Round(((Get-Date) - $start).TotalSeconds)) secondi"
$head += 'Sola lettura: questo controllo non ha modificato nulla.'
$head += ''
$head += ('=' * 78)
$head += '  RIEPILOGO'
$head += ('=' * 78)
if ($global:issues.Count) { $head += "  $($global:issues.Count) punti da controllare:"; $global:issues | ForEach-Object { $head += "  - $_" } }
else { $head += '  Nessun problema trovato' }
Set-Content -LiteralPath $out -Value $head -Encoding UTF8
Get-Content -LiteralPath $body -Encoding UTF8 | Add-Content -LiteralPath $out -Encoding UTF8
Remove-Item -LiteralPath $body -Force

Write-Host ''
Write-Host "Finito: $($global:issues.Count) punti da controllare." -ForegroundColor Green
Write-Host "Cartella: $dir"
if (-not $env:OUT) { Start-Process explorer.exe $dir }
exit ([math]::Min($global:issues.Count, 200))
