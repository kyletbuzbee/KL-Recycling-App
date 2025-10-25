REM Replace input.jpg with the image file you saved from this chat
set INPUT=app^ icons.jpg

REM Roll-off container icon (example crop — adjust +X+Y as needed)
magick "%INPUT%" -crop 120x120+40+60 +repage -resize 128x128 rolloff_container.png

REM Photo log smartphone icon (example crop)
magick "%INPUT%" -crop 120x120+40+200 +repage -resize 128x128 photo_log_phone.png

REM Photo log smartphone app icon (second instance)
magick "%INPUT%" -crop 120x120+40+340 +repage -resize 128x128 photo_log_phone_app.png

REM Sustainability compliance leaf icon
magick "%INPUT%" -crop 120x120+40+480 +repage -resize 128x128 sustainability_leaf.png

REM Mobile car crusher icon
magick "%INPUT%" -crop 160x120+220+60 +repage -resize 128x128 mobile_car_crusher.png

REM Secure alerts padlock icon
magick "%INPUT%" -crop 120x120+220+200 +repage -resize 128x128 secure_alerts.png

REM Notifications analysis icon
magick "%INPUT%" -crop 120x120+220+340 +repage -resize 128x128 notifications_analysis.png

REM User profile app icon
magick "%INPUT%" -crop 120x120+220+480 +repage -resize 128x128 user_profile.png

REM User services icon
magick "%INPUT%" -crop 120x120+400+60 +repage -resize 128x128 user_services.png

REM Scrap hauler logistics icon
magick "%INPUT%" -crop 120x120+400+200 +repage -resize 128x128 scrap_hauler_logistics.png

REM Hook truck services icon
magick "%INPUT%" -crop 160x120+400+340 +repage -resize 128x128 hook_truck_services.png

REM Safety inspection reliable icon (clipboard/check)
magick "%INPUT%" -crop 160x120+400+480 +repage -resize 128x128 safety_inspection.png
