/**
 * ============================================
 * CONFIG.JS — Configuration globale du jeu
 * Future Roots — Campus de la Manouba
 * ============================================
 *
 * MapLibre GL JS + OpenFreeMap (100% gratuit, 3D natif)
 * Pas de clé API nécessaire !
 */

const CONFIG = {

  // ---- Coordonnées du Campus de la Manouba ----
  CAMPUS_CENTER: {
    lng: 10.0635,
    lat: 36.8136,
  },

  // ---- Paramètres MapLibre (3D natif, gratuit) ----
  MAP: {
    // OpenFreeMap — tuiles vectorielles gratuites, avec bâtiments 3D
    STYLE: 'https://tiles.openfreemap.org/styles/bright',
    INITIAL_ZOOM: 17.5,
    INITIAL_PITCH: 55,         // Inclinaison 3D native (vue au sol)
    INITIAL_BEARING: -20,      // Rotation initiale
    MIN_ZOOM: 14,
    MAX_ZOOM: 20,
    MAX_BOUNDS_PADDING: 0.02,
  },

  // ---- Système GPS ----
  GPS: {
    WATCH_OPTIONS: {
      enableHighAccuracy: true,
      timeout: 10000,
      maximumAge: 0,
    },
    INTERACTION_RADIUS: 25,
    PROXIMITY_ALERT_RADIUS: 50,
    SCAN_UNLOCK_RADIUS: 30,
    MIN_UPDATE_INTERVAL: 500,
    WALK_THRESHOLD: 1.2,
    HEADING_THRESHOLD: 1.5,
    SMOOTHING_FACTOR: 0.3,
  },

  // ---- Avatar ----
  AVATAR: {
    SCALE: 15,
    WALK_SPEED: 300,
    WALK_LEAN: 3,
  },

  // ---- Plantes ----
  PLANTS: {
    DEFAULT_SCALE: 10,
  },

  // ---- Expérience & Niveaux ----
  GAME: {
    XP_PER_CAPTURE: 25,
    XP_PER_FIRST_DISCOVERY: 50,
    XP_PER_QUEST: 100,
    LEVELS: [0, 100, 250, 500, 1000, 2000, 3500, 5000, 7500, 10000],
    LEVEL_TITLES: [
      'Graine', 'Pousse', 'Bourgeon', 'Jeune Plante',
      'Arbuste', 'Arbre', 'Chêne', 'Séquoia',
      'Gardien de la Forêt', 'Maître Botaniste',
    ],
  },

  // ---- Appareil Photo ----
  CAMERA: {
    PREFERRED_FACING: 'environment',
    PHOTO_QUALITY: 0.85,
    PHOTO_MAX_WIDTH: 1080,
  },

  // ---- UI ----
  UI: {
    LOADING_DURATION: 3000,
    TOAST_DURATION: 4000,
    MODAL_ANIMATION_DURATION: 400,
  },

  // ---- Smart Zone System ----
  ZONES: {
    /** Ex: 'http://localhost:3840' — laisser null pour catalogue local uniquement */
    API_BASE: null,
    /** Anti-abus : bonus d’entrée de zone (XP/pièces) — une fois par fenêtre temporelle */
    ENTRY_BONUS_COOLDOWN_MS: 30 * 60 * 1000,
    ENTRY_BONUS_XP: 5,
    ENTRY_BONUS_COINS: 2,
  },
};

Object.freeze(CONFIG);
