@echo off
REM Script to inspect generated icon files
echo Inspecting Generated Icons
echo ========================
echo.

REM Count total PNG files
echo Total PNG files found:
dir *.png /b | find /c ".png" > tempcount.txt
set /p ICONCOUNT=<tempcount.txt
del tempcount.txt
echo %ICONCOUNT% icons generated
echo.

REM Show file listings with sizes
echo Icon Files with Sizes:
echo ----------------------
dir *.png /b > iconlist.txt

echo --- MY GENERATED ICONS (precise script) ---
for %%f in (rolloff_container.png photo_log_phone.png photo_log_phone_app.png sustainability_leaf.png mobile_car_crusher.png secure_alerts.png notifications_analysis.png user_profile.png user_services.png scrap_hauler_logistics.png hook_truck_services.png safety_inspection.png) do (
    if exist "%%f" (
        echo   ✅ %%f - & for %%s in (%%f) do echo Size: %%~zs bytes
    ) else (
        echo   ❌ %%f - MISSING
    )
)

echo.

if exist "roll_off.png" (
    echo --- USER GENERATED ICONS ---
    for %%f in (roll_off.png photo_log.png truck.png) do (
        if exist "%%f" (
            echo   🔍 %%f - & for %%s in (%%f) do echo Size: %%~zs bytes
        )
    )
)

echo.

REM Analyze sizes to check if they're reasonable
echo Analysis:
echo ---------
echo Expected: 128x128 px icons (file sizes vary by complexity)
echo Large files may indicate oversized crops or poor compression
echo Small files may indicate empty/invalid crops
echo.

REM Check for any unusually large or small files
echo File Size Check:
for %%f in (*.png) do (
    for /f %%s in ("%%~zf") do (
        if %%s gtr 50000 echo   ⚠️ LARGE: %%f (%%~zfs bytes)
        if %%s lss 500 echo   ⚠️ SMALL: %%f (%%~zfs bytes)
    )
)

echo.
echo If file sizes look incorrect, the crop coordinates need adjustment.
echo Press any key to continue...
pause > nul

del iconlist.txt 2>nul
