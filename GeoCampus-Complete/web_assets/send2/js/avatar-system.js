/**
 * ============================================
 * AVATAR-SYSTEM.JS — Avatar MapLibre GL (3D)
 * Future Roots — Campus de la Manouba
 * ============================================
 *
 * L'avatar est un marqueur MapLibre sur la carte 3D.
 * Le GPS contrôle la position et l'animation de marche.
 * La caméra suit le joueur avec pitch + bearing.
 */

window.AvatarSystem = (() => {
  let _map = null;
  let _avatarMarker = null;
  let _watchId = null;
  let _currentPosition = null;
  let _previousPosition = null;
  let _heading = 0;
  let _lastUpdateTime = 0;
  let _onPositionUpdate = null;
  let _onProximityAlert = null;
  let _isTracking = false;
  let _isFollowing = true;
  let _nearestPlantInfo = null;
  let _proximityAlerted = {};
  let _isWalking = false;
  let _walkTimeout = null;
  let _speedKmh = 0;
  let _totalDistance = 0;
  let _avatarEl = null;

  function init(map, callbacks = {}) {
    _map = map;
    _onPositionUpdate = callbacks.onPositionUpdate || null;
    _onProximityAlert = callbacks.onProximityAlert || null;

    _injectAvatarCSS();
    _createAvatarMarker();
    _createGPSSource();

    _map.on('dragstart', () => {
      _isFollowing = false;
      const widget = document.getElementById('btn-center-gps')?.closest('.compass-widget');
      if (widget) widget.classList.add('follow-off');
    });

    console.log('🧑‍🌾 Avatar 3D MapLibre — marche = GPS réel');
  }

  function _injectAvatarCSS() {
    if (document.getElementById('avatar-styles')) return;
    const style = document.createElement('style');
    style.id = 'avatar-styles';
    style.textContent = `
      .avatar-marker-el { background: none !important; border: none !important; }

      .avatar-container {
        position: relative;
        width: 60px; height: 100px;
        pointer-events: none;
      }

      .avatar-gps-pulse {
        position: absolute;
        bottom: -6px; left: 50%;
        transform: translateX(-50%);
        width: 60px; height: 20px;
        border-radius: 50%;
        background: radial-gradient(ellipse, rgba(16,185,129,0.35) 0%, transparent 70%);
        animation: gps-ground 2s ease-in-out infinite;
      }
      @keyframes gps-ground {
        0%,100% { transform: translateX(-50%) scale(1); opacity:0.8; }
        50% { transform: translateX(-50%) scale(2.5); opacity:0.1; }
      }

      .avatar-shadow {
        position: absolute; bottom: -4px; left: 50%;
        transform: translateX(-50%);
        width: 40px; height: 12px;
        background: radial-gradient(ellipse, rgba(0,0,0,0.3) 0%, transparent 70%);
        border-radius: 50%;
      }

      .avatar-character {
        position: relative;
        display: flex; flex-direction: column; align-items: center;
        filter: drop-shadow(0 3px 6px rgba(0,0,0,0.25));
      }

      .avatar-head {
        width: 34px; height: 34px;
        background: linear-gradient(135deg, #fbbf24, #f59e0b);
        border-radius: 50%;
        display: flex; align-items: center; justify-content: center;
        z-index: 3; border: 3px solid #fff;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
      }
      .avatar-face { font-size: 18px; line-height: 1; }

      .avatar-torso {
        width: 26px; height: 22px;
        background: linear-gradient(135deg, #10b981, #059669);
        border-radius: 5px 5px 3px 3px;
        margin-top: -4px; z-index: 2; border: 2.5px solid #fff;
      }

      .avatar-legs { display: flex; gap: 4px; margin-top: -2px; z-index: 1; }

      .avatar-leg {
        width: 10px; height: 16px;
        background: linear-gradient(180deg, #1d4ed8, #1e3a8a);
        border-radius: 3px 3px 4px 4px; border: 2px solid #fff;
        transform-origin: top center;
      }

      .avatar-direction {
        width: 0; height: 0;
        border-left: 7px solid transparent;
        border-right: 7px solid transparent;
        border-bottom: 12px solid #10b981;
        margin-bottom: 4px;
        filter: drop-shadow(0 0 4px rgba(16,185,129,0.5));
        transition: transform 0.4s ease;
      }

      /* Marche GPS */
      .avatar-container.walking .avatar-leg.left { animation: wl .32s ease-in-out infinite alternate; }
      .avatar-container.walking .avatar-leg.right { animation: wr .32s ease-in-out infinite alternate; }
      .avatar-container.walking .avatar-character { animation: wb .32s ease-in-out infinite alternate; }
      .avatar-container.walking .avatar-shadow { animation: ws .32s ease-in-out infinite alternate; }

      @keyframes wl { 0%{transform:rotate(-20deg)} 100%{transform:rotate(20deg)} }
      @keyframes wr { 0%{transform:rotate(20deg)} 100%{transform:rotate(-20deg)} }
      @keyframes wb { 0%{transform:translateY(0) rotate(-1.5deg)} 100%{transform:translateY(-3px) rotate(1.5deg)} }
      @keyframes ws { 0%{width:40px;opacity:.5} 100%{width:30px;opacity:.2} }

      /* Course */
      .avatar-container.running .avatar-leg.left { animation: rl .2s ease-in-out infinite alternate; }
      .avatar-container.running .avatar-leg.right { animation: rr .2s ease-in-out infinite alternate; }
      .avatar-container.running .avatar-character { animation: rb .2s ease-in-out infinite alternate; }

      @keyframes rl { 0%{transform:rotate(-30deg)} 100%{transform:rotate(30deg)} }
      @keyframes rr { 0%{transform:rotate(30deg)} 100%{transform:rotate(-30deg)} }
      @keyframes rb { 0%{transform:translateY(0) rotate(-2.5deg)} 100%{transform:translateY(-5px) rotate(2.5deg)} }

      /* Plante proche */
      .avatar-container.plant-nearby .avatar-gps-pulse {
        background: radial-gradient(ellipse, rgba(245,158,11,0.4) 0%, transparent 70%);
        animation: gps-alert 1.2s ease-in-out infinite;
      }
      @keyframes gps-alert {
        0%,100%{transform:translateX(-50%) scale(1);opacity:1}
        50%{transform:translateX(-50%) scale(3);opacity:.1}
      }

      /* Vitesse */
      .speed-indicator {
        position:fixed; left:12px; bottom:120px; z-index:90;
        background:white; padding:6px 12px; border-radius:12px;
        box-shadow:0 2px 8px rgba(0,0,0,.12); text-align:center;
        opacity:0; transform:translateX(-60px); transition:all .3s ease;
      }
      .speed-indicator.visible { opacity:1; transform:translateX(0); }
      .speed-value { display:block; font-size:20px; font-weight:800; color:#10b981; font-family:'Space Grotesk',monospace; line-height:1; }
      .speed-unit { font-size:9px; color:#94a3b8; text-transform:uppercase; letter-spacing:1px; font-weight:600; }

      .compass-widget.follow-off .compass-btn {
        background:#f59e0b; color:white;
        animation: recenter-pulse 1.5s ease-in-out infinite alternate;
      }
      @keyframes recenter-pulse {
        0%{box-shadow:0 2px 8px rgba(245,158,11,.3)} 100%{box-shadow:0 4px 20px rgba(245,158,11,.6)}
      }
    `;
    document.head.appendChild(style);

    const speedEl = document.createElement('div');
    speedEl.id = 'speed-indicator';
    speedEl.className = 'speed-indicator';
    speedEl.innerHTML = `<span class="speed-value" id="speed-value">0</span><span class="speed-unit">km/h</span>`;
    document.body.appendChild(speedEl);
  }

  function _createAvatarMarker() {
    const el = document.createElement('div');
    el.className = 'avatar-marker-el';
    el.innerHTML = `
      <div class="avatar-container" id="avatar-container">
        <div class="avatar-direction" id="avatar-direction"></div>
        <div class="avatar-character">
          <div class="avatar-head"><div class="avatar-face">😊</div></div>
          <div class="avatar-torso"></div>
          <div class="avatar-legs">
            <div class="avatar-leg left"></div>
            <div class="avatar-leg right"></div>
          </div>
        </div>
        <div class="avatar-shadow"></div>
        <div class="avatar-gps-pulse"></div>
      </div>
    `;

    _avatarMarker = new maplibregl.Marker({
      element: el,
      anchor: 'bottom',
    })
      .setLngLat([CONFIG.CAMPUS_CENTER.lng, CONFIG.CAMPUS_CENTER.lat])
      .addTo(_map);
  }

  function _createGPSSource() {
    // Cercle de précision via source GeoJSON
    _map.addSource('gps-accuracy', {
      type: 'geojson',
      data: { type: 'Feature', geometry: { type: 'Point', coordinates: [CONFIG.CAMPUS_CENTER.lng, CONFIG.CAMPUS_CENTER.lat] } },
    });
    _map.addLayer({
      id: 'gps-accuracy-fill',
      type: 'circle',
      source: 'gps-accuracy',
      paint: {
        'circle-radius': ['interpolate', ['linear'], ['zoom'], 14, 4, 18, 30],
        'circle-color': 'rgba(16,185,129,0.08)',
        'circle-stroke-color': 'rgba(16,185,129,0.25)',
        'circle-stroke-width': 1,
      },
    });
  }

  function _getAvatarEl() {
    if (!_avatarEl) _avatarEl = document.getElementById('avatar-container');
    return _avatarEl;
  }

  // ======= GPS =======

  function startTracking() {
    if (_isTracking) return true;
    if (!navigator.geolocation) {
      UIController.showToast('error', 'GPS Indisponible', 'Géolocalisation non supportée.');
      _setPosition(CONFIG.CAMPUS_CENTER.lat, CONFIG.CAMPUS_CENTER.lng, 50);
      return false;
    }
    navigator.geolocation.getCurrentPosition(_onGPSSuccess, _onGPSError, { enableHighAccuracy: true, timeout: 8000 });
    _watchId = navigator.geolocation.watchPosition(_onGPSSuccess, _onGPSError, CONFIG.GPS.WATCH_OPTIONS);
    _isTracking = true;
    console.log('📍 GPS activé — marchez !');
    return true;
  }

  function stopTracking() {
    if (_watchId !== null) { navigator.geolocation.clearWatch(_watchId); _watchId = null; }
    _isTracking = false;
  }

  function _onGPSSuccess(position) {
    const now = Date.now();
    if (now - _lastUpdateTime < CONFIG.GPS.MIN_UPDATE_INTERVAL) return;
    const { latitude, longitude, accuracy, heading, speed } = position.coords;
    const timeDelta = (now - _lastUpdateTime) / 1000;
    _lastUpdateTime = now;

    let distanceMoved = 0;
    if (_currentPosition) {
      distanceMoved = _dist(_currentPosition.lat, _currentPosition.lng, latitude, longitude);
    }

    if (speed !== null && !isNaN(speed) && speed >= 0) _speedKmh = speed * 3.6;
    else if (timeDelta > 0 && distanceMoved > 0.5) _speedKmh = (distanceMoved / timeDelta) * 3.6;

    if (distanceMoved > 0.5 && distanceMoved < 100) _totalDistance += distanceMoved;

    if (heading !== null && !isNaN(heading) && heading > 0) _heading = heading;
    else if (distanceMoved > CONFIG.GPS.HEADING_THRESHOLD && _currentPosition) {
      _heading = _bearing(_currentPosition.lat, _currentPosition.lng, latitude, longitude);
    }

    const dirEl = document.getElementById('avatar-direction');
    if (dirEl) dirEl.style.transform = `rotate(${_heading}deg)`;

    _previousPosition = _currentPosition ? { ..._currentPosition } : null;
    _currentPosition = { lat: latitude, lng: longitude, accuracy };

    // Déplacer le marqueur avatar
    if (_avatarMarker) _avatarMarker.setLngLat([longitude, latitude]);

    // GPS accuracy circle
    const src = _map.getSource('gps-accuracy');
    if (src) src.setData({ type: 'Feature', geometry: { type: 'Point', coordinates: [longitude, latitude] } });

    // Caméra suit le joueur (avec bearing natif 3D)
    if (_isFollowing) {
      _map.easeTo({
        center: [longitude, latitude],
        bearing: _heading,
        pitch: CONFIG.MAP.INITIAL_PITCH,
        duration: 800,
        easing: (t) => t * (2 - t),
      });
    }

    _detectWalk(distanceMoved);
    _updateSpeed();
    _checkProximity();
    if (_onPositionUpdate) _onPositionUpdate(_currentPosition);
  }

  function _detectWalk(dist) {
    const el = _getAvatarEl();
    if (!el) return;
    if (dist > CONFIG.GPS.WALK_THRESHOLD) {
      const running = _speedKmh > 8;
      if (running) { el.classList.remove('walking'); el.classList.add('running'); }
      else { el.classList.remove('running'); el.classList.add('walking'); }
      _isWalking = true;
      if (_walkTimeout) clearTimeout(_walkTimeout);
      _walkTimeout = setTimeout(() => {
        el.classList.remove('walking', 'running');
        _isWalking = false; _speedKmh = 0; _updateSpeed();
      }, 2500);
      if (navigator.vibrate && dist > 2) navigator.vibrate(12);
    }
  }

  function _updateSpeed() {
    const el = document.getElementById('speed-indicator');
    const val = document.getElementById('speed-value');
    if (!el || !val) return;
    if (_speedKmh > 0.5) { el.classList.add('visible'); val.textContent = _speedKmh.toFixed(1); }
    else el.classList.remove('visible');
  }

  function _onGPSError(error) {
    const msgs = { 1: 'Activez la localisation.', 2: 'Signal GPS indisponible.', 3: 'Délai GPS dépassé.' };
    console.warn('⚠️ GPS:', msgs[error.code]);
    UIController.showToast('warning', 'Signal GPS', msgs[error.code] || 'Erreur GPS');
    if (!_currentPosition) _setPosition(CONFIG.CAMPUS_CENTER.lat, CONFIG.CAMPUS_CENTER.lng, 100);
  }

  function _setPosition(lat, lng, acc) {
    _currentPosition = { lat, lng, accuracy: acc };
    if (_avatarMarker) _avatarMarker.setLngLat([lng, lat]);
    const src = _map.getSource('gps-accuracy');
    if (src) src.setData({ type: 'Feature', geometry: { type: 'Point', coordinates: [lng, lat] } });
    _map.jumpTo({ center: [lng, lat], zoom: CONFIG.MAP.INITIAL_ZOOM, pitch: CONFIG.MAP.INITIAL_PITCH });
    _checkProximity();
    if (_onPositionUpdate) _onPositionUpdate(_currentPosition);
  }

  // ======= PROXIMITÉ =======

  function _checkProximity() {
    if (!_currentPosition) return;
    let nearest = null, nearDist = Infinity, hasNearby = false;
    const el = _getAvatarEl();

    PLANTS_DATABASE.forEach(plant => {
      const d = _dist(_currentPosition.lat, _currentPosition.lng, plant.position.lat, plant.position.lng);
      if (d < nearDist) { nearDist = d; nearest = plant; }
      if (d <= CONFIG.GPS.PROXIMITY_ALERT_RADIUS) {
        hasNearby = true;
        if (d <= CONFIG.GPS.SCAN_UNLOCK_RADIUS && !_proximityAlerted[plant.id]) {
          _proximityAlerted[plant.id] = true;
          if (_onProximityAlert) _onProximityAlert(plant, d);
        }
      }
      if (d > CONFIG.GPS.PROXIMITY_ALERT_RADIUS * 1.5) _proximityAlerted[plant.id] = false;
    });

    _nearestPlantInfo = nearest ? { plant: nearest, distance: nearDist } : null;
    if (el) { if (hasNearby) el.classList.add('plant-nearby'); else el.classList.remove('plant-nearby'); }
    const distEl = document.getElementById('nearest-plant-distance');
    if (distEl && nearDist < 9999) distEl.textContent = Math.round(nearDist);
  }

  // ======= MATH =======

  function _dist(lat1, lng1, lat2, lng2) {
    const R = 6371000, dLat = (lat2-lat1)*Math.PI/180, dLng = (lng2-lng1)*Math.PI/180;
    const a = Math.sin(dLat/2)**2 + Math.cos(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*Math.sin(dLng/2)**2;
    return R*2*Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  }

  function _bearing(lat1, lng1, lat2, lng2) {
    const dLng = (lng2-lng1)*Math.PI/180;
    const y = Math.sin(dLng)*Math.cos(lat2*Math.PI/180);
    const x = Math.cos(lat1*Math.PI/180)*Math.sin(lat2*Math.PI/180) - Math.sin(lat1*Math.PI/180)*Math.cos(lat2*Math.PI/180)*Math.cos(dLng);
    return (Math.atan2(y,x)*180/Math.PI+360)%360;
  }

  // ======= API =======

  function centerOnPlayer() {
    _isFollowing = true;
    const widget = document.getElementById('btn-center-gps')?.closest('.compass-widget');
    if (widget) widget.classList.remove('follow-off');
    if (_currentPosition) {
      _map.flyTo({
        center: [_currentPosition.lng, _currentPosition.lat],
        zoom: CONFIG.MAP.INITIAL_ZOOM,
        pitch: CONFIG.MAP.INITIAL_PITCH,
        bearing: _heading,
        duration: 1000,
      });
    }
  }

  function getPosition() { return _currentPosition; }
  function getNearestPlant() { return _nearestPlantInfo; }
  function getSpeed() { return _speedKmh; }
  function getTotalDistance() { return _totalDistance; }

  function isInScanRange(plant) {
    if (!_currentPosition) return false;
    if (plant) return _dist(_currentPosition.lat, _currentPosition.lng, plant.position.lat, plant.position.lng) <= CONFIG.GPS.SCAN_UNLOCK_RADIUS;
    return _nearestPlantInfo && _nearestPlantInfo.distance <= CONFIG.GPS.SCAN_UNLOCK_RADIUS;
  }

  function distanceToPlant(plant) {
    if (!_currentPosition) return Infinity;
    return _dist(_currentPosition.lat, _currentPosition.lng, plant.position.lat, plant.position.lng);
  }

  /** Met à jour la position depuis une source externe (ex: Flutter) */
  function syncGPS(arg1, arg2 = null, arg3 = null, arg4 = null) {
    if (!_map) return;
    
    let lat, lng, heading = null, speed = null;
    
    // Si passage d'un seul argument objet (JSON Flutter)
    if (typeof arg1 === 'object' && arg1 !== null) {
      lat = arg1.lat;
      lng = arg1.lng;
      heading = arg1.heading;
      speed = arg1.speed;
    } else {
      lat = arg1;
      lng = arg2;
      heading = arg3;
      speed = arg4;
    }

    if (lat === undefined || lng === undefined) return;
    
    // Ignore Null Island (middle of the ocean, which appears entirely blue)
    if (Math.abs(lat) < 0.1 && Math.abs(lng) < 0.1) {
      console.warn('⚠️ Ignored invalid GPS coordinates (0, 0)');
      return;
    }

    const mockPosition = {
      coords: {
        latitude: lat,
        longitude: lng,
        accuracy: 10,
        heading: heading,
        speed: speed
      },
      timestamp: Date.now()
    };
    _onGPSSuccess(mockPosition);
  }

  return {
    init,
    startTracking,
    stopTracking,
    centerOnPlayer,
    getPosition,
    getNearestPlant,
    getSpeed,
    getTotalDistance,
    isInScanRange,
    distanceToPlant,
    syncGPS,
  };
})();

// Bridge Flutter -> Web
window.syncGPS = AvatarSystem.syncGPS;
