@echo off
REM Script to help determine accurate crop coordinates
echo Icon Coordinate Calculator
echo ==========================
echo.
echo This will help you determine precise crop coordinates for your icons.
echo.

REM Get image dimensions
echo Getting source image dimensions:
magick identify "app icons.jpg"

echo.
echo To determine precise coordinates, you can:
echo 1. Open the image in an image editor (like GIMP, Photoshop, or Paint.NET)
echo 2. Measure the exact pixel coordinates for each icon
echo 3. Update the coordinates in generate_icons_precise.bat
echo.
echo Icon Layout (pixels from top-left corner):
echo - Left column (X+40):   120x120 icons starting at Y+60, +140 spacing
echo - Middle column (X+220): 120x120 icons starting at Y+60, +140 spacing
echo - Right column (X+400):  120x120 icons starting at Y+60, +140 spacing
echo.
echo Current crop regions:
echo rolloff_container: 120x120+40+60
echo photo_log_phone: 120x120+40+200
echo photo_log_phone_app: 120x120+40+340
echo sustainability_leaf: 120x120+40+480
echo.
echo mobile_car_crusher: 160x120+220+60
echo secure_alerts: 120x120+220+200
echo notifications_analysis: 120x120+220+340
echo user_profile: 120x120+220+480
echo.
echo user_services: 120x120+400+60
echo scrap_hauler_logistics: 120x120+400+200
echo hook_truck_services: 160x120+400+340
echo safety_inspection: 160x120+400+480
echo.
echo Press any key to continue and help measure exact coordinates...
pause > nul
