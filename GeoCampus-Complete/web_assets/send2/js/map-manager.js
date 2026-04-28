/**
 * ============================================
 * MAP-MANAGER.JS — MapLibre GL (3D natif, GRATUIT)
 * Future Roots — Campus de la Manouba
 * ============================================
 *
 * MapLibre GL JS = fork gratuit de Mapbox GL
 * → Pitch/bearing 3D natif
 * → Bâtiments 3D extrudés
 * → Tuiles vectorielles OpenFreeMap (aucune clé API)
 * → Atmosphère, brouillard, ciel
 */

window.MapManager = (() => {
  let _map = null;
  let _plantMarkers = [];
  let _isReady = false;

  /**
   * Initialise la carte MapLibre GL avec 3D
   */
  function init(onReady) {
    return new Promise((resolve, reject) => {
      try {
        _map = new maplibregl.Map({
          container: 'map',
          style: CONFIG.MAP.STYLE,
          center: [CONFIG.CAMPUS_CENTER.lng, CONFIG.CAMPUS_CENTER.lat],
          zoom: CONFIG.MAP.INITIAL_ZOOM,
          pitch: CONFIG.MAP.INITIAL_PITCH,
          bearing: CONFIG.MAP.INITIAL_BEARING,
          minZoom: CONFIG.MAP.MIN_ZOOM,
          maxZoom: CONFIG.MAP.MAX_ZOOM,
          antialias: true,
          attributionControl: false,
          // Touch mobile
          touchZoomRotate: true,
          touchPitch: true,
          dragRotate: true,
        });

        // Attribution discrète
        _map.addControl(
          new maplibregl.AttributionControl({ compact: true }),
          'bottom-left'
        );

        _map.on('load', () => {
          console.log('🗺️ MapLibre GL chargé — 3D natif activé !');

          // Ajouter les bâtiments 3D
          _add3DBuildings();

          // Atmosphère (removed to prevent blue screen bug)
          // _addAtmosphere();

          window.MapManager._isReady = true;
          if (onReady) onReady(_map);
          resolve(_map);
        });

        _map.on('error', (e) => {
          console.error('❌ Erreur MapLibre:', e);
        });
      } catch (error) {
        console.error('❌ Erreur init carte:', error);
        reject(error);
      }
    });
  }

  /**
   * Bâtiments 3D extrudés (natif MapLibre)
   * @private
   */
  function _add3DBuildings() {
    // Trouver la première couche de labels pour insérer les bâtiments en-dessous
    const layers = _map.getStyle().layers;
    let labelLayerId;
    for (let i = 0; i < layers.length; i++) {
      if (layers[i].type === 'symbol' && layers[i].layout && layers[i].layout['text-field']) {
        labelLayerId = layers[i].id;
        break;
      }
    }

    // Vérifier si la source 'openmaptiles' existe (OpenFreeMap)
    const sources = _map.getStyle().sources;
    let buildingSource = 'openmaptiles';
    let sourceLayer = 'building';

    // Ajouter la couche de bâtiments si la source existe
    try {
      _map.addLayer(
        {
          id: '3d-buildings',
          source: buildingSource,
          'source-layer': sourceLayer,
          type: 'fill-extrusion',
          minzoom: 14,
          filter: ['!=', 'hide_3d', true],
          paint: {
            // Couleurs pastel — bâtiments style jeu vidéo
            'fill-extrusion-color': [
              'interpolate', ['linear'], ['get', 'render_height'],
              0, '#e8dfd0',
              8, '#ddd4c0',
              15, '#d4c5a9',
              30, '#c8b896',
            ],
            'fill-extrusion-height': [
              'interpolate', ['linear'], ['zoom'],
              14, 0,
              15, ['get', 'render_height'],
            ],
            'fill-extrusion-base': [
              'interpolate', ['linear'], ['zoom'],
              14, 0,
              15, ['get', 'render_min_height'],
            ],
            'fill-extrusion-opacity': 0.85,
          },
        },
        labelLayerId
      );
      console.log('🏢 Bâtiments 3D ajoutés');
    } catch (e) {
      console.warn('⚠️ Pas de couche bâtiments disponible:', e.message);
    }
  }

  /**
   * Ciel et atmosphère
   * @private
   */
  function _addAtmosphere() {
    try {
      _map.setFog({
        'color': '#dceefa',
        'high-color': '#a8d4f5',
        'horizon-blend': 0.12,
        'space-color': '#87ceeb',
        'star-intensity': 0.0,
      });
    } catch (e) {
      // Fog pas supporté dans toutes les versions
      console.warn('⚠️ Fog non supporté');
    }
  }

  /**
   * Place les marqueurs de plantes
   */
  function placePlantMarkers(plants, onClick) {
    // Nettoyer
    _plantMarkers.forEach(m => m.remove());
    _plantMarkers = [];

    plants.forEach((plant) => {
      const captured = GameState.isPlantCaptured(plant.id);
      const rarityColor = getRarityColor(plant.rarity);

      // Créer l'élément HTML du marqueur
      const el = document.createElement('div');
      el.className = 'plant-marker';
      el.id = `marker-${plant.id}`;
      el.innerHTML = `
        <div class="plant-marker-inner rarity-${plant.rarity} ${captured ? 'captured' : ''}"
             style="--rarity-color: ${rarityColor}">
          <div class="plant-marker-float">
            <span class="plant-marker-emoji">${plant.emoji}</span>
          </div>
          <div class="plant-marker-base"></div>
          <div class="plant-marker-ring"></div>
        </div>
      `;

      // Créer le marqueur MapLibre
      const marker = new maplibregl.Marker({
        element: el,
        anchor: 'bottom',
      })
        .setLngLat([plant.position.lng, plant.position.lat])
        .addTo(_map);

      // Force clickability
      el.style.pointerEvents = 'auto';
      el.style.cursor = 'pointer';

      const handleTouch = (e) => {
        e.stopPropagation();
        console.log(`🌲 Marker Clicked: ${plant.name}`);
        if (onClick) onClick(plant);
      };

      el.addEventListener('click', handleTouch);
      el.addEventListener('touchstart', handleTouch);

      marker._plantId = plant.id;
      _plantMarkers.push(marker);
    });

    console.log(`🌿 ${plants.length} marqueurs placés`);
  }

  /**
   * Met à jour l'état d'un marqueur
   */
  function updateMarkerState(plantId, captured) {
    const marker = _plantMarkers.find(m => m._plantId === plantId);
    if (marker) {
      const inner = marker.getElement().querySelector('.plant-marker-inner');
      if (inner) {
        if (captured) inner.classList.add('captured');
        else inner.classList.remove('captured');
      }
    }
  }

  /**
   * Vol vers une position
   */
  function flyTo(lng, lat, options = {}) {
    if (!_map) return;
    _map.flyTo({
      center: [lng, lat],
      zoom: options.zoom || CONFIG.MAP.INITIAL_ZOOM,
      pitch: options.pitch || CONFIG.MAP.INITIAL_PITCH,
      bearing: options.bearing || _map.getBearing(),
      duration: options.duration || 1500,
      essential: true,
    });
  }

  /**
   * Pan doux vers une position
   */
  function panTo(lng, lat) {
    if (!_map) return;
    _map.easeTo({
      center: [lng, lat],
      duration: 800,
      easing: (t) => t * (2 - t),
    });
  }

  function getMap() { return _map; }
  function isReady() { return _isReady; }

  return {
    init,
    getMap,
    placePlantMarkers,
    updateMarkerState,
    flyTo,
    panTo,
    isReady
  };
})();
