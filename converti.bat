@echo off
setlocal enabledelayedexpansion
:: Forza Windows a lavorare ESATTAMENTE in questa cartella
cd /d "%~dp0"

echo ====================================================
echo Convertitore WebP - L'Ottimizzazione Intelligente
echo ====================================================

if not exist cwebp.exe (
    echo ERRORE: cwebp.exe mancante in questa cartella!
    pause
    exit
)

echo.
echo Scegli l'opzione desiderata:
echo.
echo [1] BILANCIATA (Auto-Intelligente) : 800px. Minimo peso possibile (es. 10KB), ma MAI oltre i 24 KB.
echo [2] ESTREMA    (Sotto i 10 KB)     : 500px. Peso forzato massimo a 9 KB.
echo [3] MANUALE                        : Decidi solo la percentuale di qualita' (larghezza fissa 800px).
echo.
set /p "scelta=Digita 1, 2 o 3 e premi Invio (se premi solo Invio usa la 1): "

if "%scelta%"=="2" goto ESTREMA
if "%scelta%"=="3" goto MANUALE
goto BILANCIATA

:BILANCIATA
set "modalita=bilanciata"
echo.
echo ---^> Modalita' BILANCIATA: 800px, ottimizzazione intelligente...
goto START_CONVERSION

:ESTREMA
set "modalita=estrema"
echo.
echo ---^> Modalita' ESTREMA: 500px, forzato a ~9 KB...
goto START_CONVERSION

:MANUALE
set "modalita=manuale"
echo.
set /p "qual=Inserisci solo la percentuale di qualita' (es. 30, 50, 70): "
echo.
echo ---^> Modalita' MANUALE: 800px, qualita' %qual%%%.
goto START_CONVERSION

:START_CONVERSION
echo.
set "trovati=0"

for %%f in (*.jpg *.jpeg *.png *.heic *.HEIC *.JPG *.PNG) do (
    set "trovati=1"
    echo Sto elaborando: "%%f"
    
    if "!modalita!"=="bilanciata" (
        :: PASSO 1: Prova a comprimerla mantenendo la qualita' al 40%. Se la foto e' semplice uscira' piccolissima.
        cwebp.exe -q 40 -resize 800 0 -m 6 -pass 10 -af -sharp_yuv -metadata none "%%f" -o "%%~nf.webp" >nul 2>&1
        
        :: Il programma legge quanto pesa il file appena creato
        for %%A in ("%%~nf.webp") do set "peso=%%~zA"
        
        :: PASSO 2: Se il file pesa piu' di 24.500 byte (circa 24.5 KB), lo "schiaccia" forzatamente
        if !peso! GTR 24500 (
            echo      [!] Foto complessa. Riduco forzatamente sotto i 24 KB...
            cwebp.exe -size 24000 -resize 800 0 -m 6 -pass 10 -af -metadata none "%%f" -o "%%~nf.webp" >nul 2>&1
        )
    )
    
    if "!modalita!"=="estrema" (
        cwebp.exe -size 9000 -resize 500 0 -m 6 -pass 10 -af -metadata none "%%f" -o "%%~nf.webp" >nul 2>&1
    )
    
    if "!modalita!"=="manuale" (
        cwebp.exe -q !qual! -resize 800 0 -m 6 -pass 10 -af -sharp_yuv -metadata none "%%f" -o "%%~nf.webp" >nul 2>&1
    )
    
    :: Controllo e cancellazione file originale
    if exist "%%~nf.webp" (
        del /f /q "%%f"
        echo      [OK] Fatto! Originale eliminato.
    ) else (
        echo      [X] ERRORE nella conversione di "%%f".
    )
)

if "!trovati!"=="0" (
    echo ATTENZIONE: Nessuna immagine trovata in questa cartella!
)

echo.
echo ====================================================
echo Operazione conclusa con successo!
echo ====================================================
pause