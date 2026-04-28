@echo off
echo Starting GeoCampus Backends...

echo Starting Web Assets Server Map and Simulation on port 8080...
start cmd /k "cd web_assets && python -m http.server 8080 --bind 0.0.0.0"

echo Starting AI Scanner (PlantNet) on port 8888...
start cmd /k "cd backend\plant_recognition && python plant_game_server.py"

echo Backends are running!
echo Ensure your phone is connected to the same Wi-Fi network as this PC (192.168.1.44).
echo Now, plug in your phone and build the Flutter app:
echo.
echo    cd frontend
echo    flutter run
echo.
pause
