/**
 * ============================================
 * APP.JS — Point d'entrée principal du jeu
 * Future Roots — Campus de la Manouba
 * ============================================
 *
 * Ce module orchestre le lancement de tous les
 * systèmes du jeu et gère la séquence de démarrage.
 */

(async function FutureRootsApp() {
  'use strict';

  console.log('🌿 Future Roots — Campus de la Manouba');
  console.log('========================================');

  // ---- Étape 1 : Particules de loading ----
  UIController.createLoadingParticles();
  UIController.updateLoadingBar(10, 'Initialisation du jeu...');

  // ---- Étape 2 : Charger l'état du jeu ----
  await _delay(300);
  GameState.init();
  UIController.updateLoadingBar(25, 'Sauvegarde chargée...');

  await _delay(200);
  UIController.updateLoadingBar(28, 'Chargement des zones campus...');
  await ZoneService.load();

  // ---- Étape 3 : Initialiser la carte Mapbox ----
  await _delay(300);
  UIController.updateLoadingBar(40, 'Chargement de la carte 3D...');

  try {
    await MapManager.init((map) => {
      console.log('✅ Carte prête');
    });
    UIController.updateLoadingBar(65, 'Carte du campus chargée...');
  } catch (error) {
    console.error('❌ Erreur de chargement de la carte:', error);
    UIController.updateLoadingBar(65, 'Mode hors-ligne...');
  }

  // ---- Étape 4 : Placer les plantes sur la carte ----
  await _delay(300);
  UIController.updateLoadingBar(75, 'Placement de la végétation...');

  MapManager.placePlantMarkers(PLANTS_DATABASE, (plant) => {
    // Callback au clic sur un marqueur de plante
    console.log(`🌿 Elite Specimen Hub: ${plant.name}`);
    UIController.openBotanicalHub(plant);
  });

  // ---- Étape 5 : Initialiser le système d'avatar GPS ----
  await _delay(300);
  UIController.updateLoadingBar(85, 'Activation du GPS...');

  AvatarSystem.init(MapManager.getMap(), {
    onPositionUpdate: (position) => {
      ZoneDetector.updateFromPosition(position);
    },
    onProximityAlert: (plant, distance) => {
      // Alerte quand le joueur s'approche d'une plante
      if (!GameState.isPlantCaptured(plant.id) && distance <= CONFIG.GPS.INTERACTION_RADIUS) {
        UIController.showToast('success', `${plant.emoji} ${plant.name} repéré${plant.name.endsWith('e') ? 'e' : ''} !`,
          `À ${Math.round(distance)}m — Appuyez pour scanner`);
      }
    },
  });

  ZoneDetector.on('enter', (zone) => {
    if (typeof ZoneUI !== 'undefined') {
      ZoneUI.setZoneIndicator(zone);
      ZoneUI.showZoneEntryBanner(zone);
    }
    const bonus = GameState.tryGrantZoneEntryBonus(zone.id);
    if (bonus.granted) {
      UIController.showToast('info', 'Bonus de découverte', `+${bonus.xp} XP · +${bonus.coins} pièces`);
      UIController.refreshPlayerBar();
    }
  });

  ZoneDetector.on('exit', () => {
    if (typeof ZoneUI !== 'undefined') ZoneUI.setZoneIndicator(null);
  });

    // Démarrer le suivi GPS
    // AvatarSystem.startTracking(); // DESACTIVÉ: On utilise syncGPS depuis Flutter pour éviter les conflits

    const initialPos = AvatarSystem.getPosition();
    if (initialPos) ZoneDetector.updateFromPosition(initialPos);

    // ---- Étape 6 : Initialiser le module caméra ----
    await _delay(200);
    UIController.updateLoadingBar(92, 'Préparation du scanner...');

    CameraModule.init({
      onPhotoTaken: (photoUrl) => {
        UIController.onPhotoTaken(photoUrl);
      },
    });

    // ---- Étape 7 : Initialiser l'UI ----
    await _delay(200);
    UIController.updateLoadingBar(100, 'Prêt à explorer !');
    UIController.init();

    // S'assurer que le nom est synchronisé si GameState a déjà des données
    UIController.refreshPlayerBar();

    // ---- Étape 8 : Lancement ! ----
    await _delay(800);
    UIController.hideLoadingScreen();

    // Message de bienvenue
    setTimeout(() => {
      const player = GameState.getPlayer();
      const herbierCount = GameState.getHerbier().length;

      const welcomeName = player.name !== 'Explorateur' ? player.name : 'Explorateur';

      if (herbierCount === 0) {
        UIController.showToast('info', `🌿 Bienvenue, ${welcomeName} !`,
          'Explorez le campus pour découvrir et photographier les plantes.');
      } else {
        UIController.showToast('info', `👋 Bon retour, ${welcomeName} !`,
          `Vous avez découvert ${herbierCount}/${PLANTS_DATABASE.length} plantes.`);
      }
    }, 1500);

  console.log('🎮 Jeu lancé avec succès !');


  // ========================
  // MODE DÉMO (clic sur la carte)
  // ========================
  // Permet de déplacer l'avatar en cliquant sur la carte
  // (utile pour tester sans GPS)
  const map = MapManager.getMap();
  if (map) {
    map.on('click', (e) => {
      // Ne pas interférer avec les marqueurs
      if (e.originalEvent.target.closest('.plant-marker')) return;

      // Console : AvatarSystem.simulateDemoPosition(lat, lng) pour tester les zones
    });
  }

  /**
   * Fonction utilitaire — Délai asynchrone
   * @param {number} ms - Millisecondes
   * @returns {Promise}
   */
  function _delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

})();
