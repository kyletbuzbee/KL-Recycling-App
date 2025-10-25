@echo off
REM Precise Icon Generation script with validation
REM Updated to ensure accurate cropping and quality output

set INPUT=app^ icons.jpg

echo Starting precise icon generation process...
echo Input file: %INPUT%
echo ===========================================

REM Get input image dimensions for reference
echo Getting input image info...
magick identify "%INPUT%" 2>nul
if errorlevel 1 (
    echo ERROR: Cannot access input file
    pause
    exit /b 1
)
echo ===========================================

echo Generating icons with precise cropping...

REM 1. Roll-off container icon (120x120, top-left)
echo Crop: rolloff_container (120x120+40+60)
magick "%INPUT%" -crop 120x120+40+60 +repage -resize 128x128 -quality 100 "rolloff_container.png"
if exist "rolloff_container.png" echo ✓ rolloff_container.png created

REM 2. Photo log smartphone icon (120x120, second row left)
echo Crop: photo_log_phone (120x120+40+200)
magick "%INPUT%" -crop 120x120+40+200 +repage -resize 128x128 -quality 100 "photo_log_phone.png"
if exist "photo_log_phone.png" echo ✓ photo_log_phone.png created

REM 3. Photo log smartphone app icon (120x120, third row left)
echo Crop: photo_log_phone_app (120x120+40+340)
magick "%INPUT%" -crop 120x120+40+340 +repage -resize 128x128 -quality 100 "photo_log_phone_app.png"
if exist "photo_log_phone_app.png" echo ✓ photo_log_phone_app.png created

REM 4. Sustainability compliance leaf icon (120x120, fourth row left)
echo Crop: sustainability_leaf (120x120+40+480)
magick "%INPUT%" -crop 120x120+40+480 +repage -resize 128x128 -quality 100 "sustainability_leaf.png"
if exist "sustainability_leaf.png" echo ✓ sustainability_leaf.png created

REM 5. Mobile car crusher icon (160x120, second column top)
echo Crop: mobile_car_crusher (160x120+220+60)
magick "%INPUT%" -crop 160x120+220+60 +repage -resize 128x128 -quality 100 "mobile_car_crusher.png"
if exist "mobile_car_crusher.png" echo ✓ mobile_car_crusher.png created

REM 6. Secure alerts padlock icon (120x120, second column second row)
echo Crop: secure_alerts (120x120+220+200)
magick "%INPUT%" -crop 120x120+220+200 +repage -resize 128x128 -quality 100 "secure_alerts.png"
if exist "secure_alerts.png" echo ✓ secure_alerts.png created

REM 7. Notifications analysis icon (120x120, second column third row)
echo Crop: notifications_analysis (120x120+220+340)
magick "%INPUT%" -crop 120x120+220+340 +repage -resize 128x128 -quality 100 "notifications_analysis.png"
if exist "notifications_analysis.png" echo ✓ notifications_analysis.png created

REM 8. User profile app icon (120x120, second column fourth row)
echo Crop: user_profile (120x120+220+480)
magick "%INPUT%" -crop 120x120+220+480 +repage -resize 128x128 -quality 100 "user_profile.png"
if exist "user_profile.png" echo ✓ user_profile.png created

REM 9. User services icon (120x120, third column top)
echo Crop: user_services (120x120+400+60)
magick "%INPUT%" -crop 120x120+400+60 +repage -resize 128x128 -quality 100 "user_services.png"
if exist "user_services.png" echo ✓ user_services.png created

REM 10. Scrap hauler logistics icon (120x120, third column second row)
echo Crop: scrap_hauler_logistics (120x120+400+200)
magick "%INPUT%" -crop 120x120+400+200 +repage -resize 128x128 -quality 100 "scrap_hauler_logistics.png"
if exist "scrap_hauler_logistics.png" echo ✓ scrap_hauler_logistics.png created

REM 11. Hook truck services icon (160x120, third column third row)
echo Crop: hook_truck_services (160x120+400+340)
magick "%INPUT%" -crop 160x120+400+340 +repage -resize 128x128 -quality 100 "hook_truck_services.png"
if exist "hook_truck_services.png" echo ✓ hook_truck_services.png created

REM 12. Safety inspection icon (160x120, third column fourth row)
echo Crop: safety_inspection (160x120+400+480)
magick "%INPUT%" -crop 160x120+400+480 +repage -resize 128x128 -quality 100 "safety_inspection.png"
if exist "safety_inspection.png" echo ✓ safety_inspection.png created

echo ===========================================
echo Validating generated icons...

REM Count generated icons
dir /b *.png | find /c ".png" > tempcount.txt
set /p ICONCOUNT=<tempcount.txt
del tempcount.txt

echo Generated %ICONCOUNT% icon files

REM List all generated icons with sizes
echo File sizes:
for %%f in (*.png) do (
    echo  - %%f
)

echo ===========================================
echo Icon generation complete!
echo.
echo Precise cropping specifications used:
echo - All icons cropped using +geometry+X+Y coordinates
echo - +repage applied for proper geometry handling
echo - Resized to consistent 128x128 final dimensions
echo - 100%% quality for optimal clarity
echo ===========================================

pause
