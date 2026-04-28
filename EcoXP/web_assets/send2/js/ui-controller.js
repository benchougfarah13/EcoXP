/**
 * ============================================
 * UI-CONTROLLER.JS — Interface Pokémon GO
 * Future Roots — Campus de la Manouba
 * ============================================
 *
 * Ce module gère :
 * - Le verrouillage/déverrouillage du scanner selon la proximité GPS
 * - La détection de végétation via PlantDetector
 * - Les modals, l'herbier, les quêtes
 * - Les notifications toast
 * - La mise à jour continue de l'UI
 */

window.UIController = (() => {
  let _selectedPlant = null;
  let _lastPhotoUrl = null;
  let _scanUnlocked = false;           // Scanner verrouillé par défaut
  let _nearbyPlant = null;             // Plante à portée de scan
  let _proximityCheckInterval = null;
  
  // 3D Specimen Lab state
  let _labScene, _labCamera, _labRenderer, _labTree, _labClock;
  let _labIsRotating = true;
  let _labRequestID = null;

  /**
   * Initialise tous les contrôleurs d'interface
   */
  function init() {
    _bindNavigationEvents();
    _bindModalEvents();
    _bindCompassEvents();
    if (typeof ZoneUI !== 'undefined') ZoneUI.init();
    _updatePlayerUI();

    // Vérifier la proximité toutes les secondes pour le scanner
    _proximityCheckInterval = setInterval(_updateScannerState, 1000);

    _bindBotanicalHubEvents();

    console.log('🎨 Interface utilisateur initialisée');
  }

  /**
   * Met à jour l'état du bouton scanner selon la distance GPS
   * @private
   */
  function _updateScannerState() {
    const scanBtn = document.getElementById('btn-scan-plant');
    if (!scanBtn) return;

    const nearest = AvatarSystem.getNearestPlant();

    if (nearest && nearest.distance <= CONFIG.GPS.SCAN_UNLOCK_RADIUS) {
      // DÉBLOQUÉ — Plante à portée !
      if (!_scanUnlocked || _nearbyPlant?.id !== nearest.plant.id) {
        _scanUnlocked = true;
        _nearbyPlant = nearest.plant;
        scanBtn.classList.remove('locked');
        scanBtn.classList.add('unlocked');
        _vibrate([30, 50, 30]);
      }
    } else {
      // VERROUILLÉ — Trop loin
      if (_scanUnlocked) {
        _scanUnlocked = false;
        _nearbyPlant = null;
        scanBtn.classList.remove('unlocked');
        scanBtn.classList.add('locked');
      }
    }
  }

  // ============================
  // ÉVÉNEMENTS DE NAVIGATION
  // ============================

  function _bindNavigationEvents() {
    // Onglets
    document.querySelectorAll('.nav-btn[data-tab]').forEach(btn => {
      btn.addEventListener('click', () => {
        _activateNavTab(btn);
        _handleTabSwitch(btn.dataset.tab);
      });
    });

    // Bouton Scanner — Vérifie la proximité avant d'ouvrir
    const btnScan = document.getElementById('btn-scan-plant');
    if (btnScan) {
      btnScan.classList.add('locked'); // Verrouillé au départ
      btnScan.addEventListener('click', _onScanButtonClick);
    }

    // Fermeture panneaux
    document.getElementById('btn-close-herbier')?.addEventListener('click', () => _closePanel('herbier-panel'));
    document.getElementById('btn-close-quests')?.addEventListener('click', () => _closePanel('quests-panel'));
  }

  function _activateNavTab(activeBtn) {
    document.querySelectorAll('.nav-btn[data-tab]').forEach(btn => btn.classList.remove('active'));
    activeBtn.classList.add('active');
  }

  function _handleTabSwitch(tab) {
    _closePanel('herbier-panel');
    _closePanel('quests-panel');
    _closePanel('prediction-panel');

    switch (tab) {
      case 'herbier': _openHerbierPanel(); break;
      case 'quests': _openQuestsPanel(); break;
      case 'prediction': _openPredictionPanel(); break;
      case 'profile':
        const player = GameState.getPlayer();
        const coins = player.coins ?? 0;
        const lb = GameState.getLeaderboardScore();
        const badges = GameState.getBadges().length;
        showToast('info', `Niveau ${player.level}`,
          `${CONFIG.GAME.LEVEL_TITLES[player.level - 1]} — ${player.totalCaptures} captures — ${coins} pièces — score ${lb} — ${badges} badge(s)`);
        break;
    }
  }

  function _bindModalEvents() {
    document.getElementById('btn-close-plant-modal')?.addEventListener('click', closePlantModal);
    document.getElementById('btn-capture-plant')?.addEventListener('click', _onCapturePlantClick);
    document.getElementById('btn-add-to-herbier')?.addEventListener('click', _onAddToHerbier);
    document.getElementById('btn-close-capture')?.addEventListener('click', closeCaptureResultModal);

    // Fermer au clic sur overlay
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
      overlay.addEventListener('click', (e) => {
        if (e.target === overlay) overlay.classList.add('hidden');
      });
    });
  }

  function _bindCompassEvents() {
    document.getElementById('btn-center-gps')?.addEventListener('click', () => {
      AvatarSystem.centerOnPlayer();
      _vibrate(50);
    });
  }

  function _vibrate(pattern) {
    if (navigator.vibrate) navigator.vibrate(pattern);
  }

  // ============================
  // ÉCRAN DE CHARGEMENT
  // ============================

  function updateLoadingBar(percent, text) {
    const bar = document.getElementById('loading-bar');
    const textEl = document.getElementById('loading-text');
    if (bar) bar.style.width = `${percent}%`;
    if (textEl) textEl.textContent = text;
  }

  function hideLoadingScreen() {
    const screen = document.getElementById('loading-screen');
    if (screen) {
      screen.classList.add('fade-out');
      setTimeout(() => screen.style.display = 'none', 800);
    }
    setTimeout(() => {
      document.getElementById('top-bar')?.classList.remove('hidden');
      document.getElementById('bottom-nav')?.classList.remove('hidden');
      document.getElementById('compass-widget')?.classList.remove('hidden');
    }, 400);
  }

  function createLoadingParticles() {
    const container = document.getElementById('loading-particles');
    if (!container) return;
    for (let i = 0; i < 25; i++) {
      const p = document.createElement('div');
      p.className = 'particle';
      p.style.left = `${Math.random() * 100}%`;
      p.style.animationDelay = `${Math.random() * 5}s`;
      p.style.animationDuration = `${4 + Math.random() * 3}s`;
      p.style.width = `${3 + Math.random() * 5}px`;
      p.style.height = p.style.width;
      container.appendChild(p);
    }
  }

  // ============================
  // MODAL FICHE PLANTE
  // ============================

  function openPlantModal(plant) {
    _selectedPlant = plant;

    const nameEl = document.getElementById('plant-modal-name');
    const latinEl = document.getElementById('plant-modal-latin');
    const descEl = document.getElementById('plant-modal-description');
    const viewerEl = document.getElementById('plant-3d-viewer');
    const headerEl = document.getElementById('plant-card-header');
    const rarityEl = document.getElementById('plant-card-rarity');

    if (nameEl) nameEl.textContent = plant.name;
    if (latinEl) latinEl.textContent = plant.latinName;
    if (descEl) descEl.innerHTML = `
      <p>${plant.description}</p>
      <p style="margin-top: 10px; color: #b45309; font-weight: 700;">
        💡 ${plant.funFact}
      </p>
      <div style="margin-top: 12px; display: flex; flex-wrap: wrap; gap: 6px;">
        <span style="padding: 4px 10px; background: #f1f5f9; border-radius: 8px; font-size: 11px; font-weight: 600;">
          🌿 ${plant.family}
        </span>
        <span style="padding: 4px 10px; background: #f1f5f9; border-radius: 8px; font-size: 11px; font-weight: 600;">
          📍 ${plant.origin}
        </span>
        <span style="padding: 4px 10px; background: #f1f5f9; border-radius: 8px; font-size: 11px; font-weight: 600;">
          📏 ${plant.maxHeight}
        </span>
        <span style="padding: 4px 10px; background: #f1f5f9; border-radius: 8px; font-size: 11px; font-weight: 600;">
          🌸 ${plant.floweringSeason}
        </span>
      </div>
    `;

    if (viewerEl) viewerEl.textContent = plant.emoji;

    if (headerEl) {
      const gradients = {
        common: 'linear-gradient(135deg, #f8fafc, #e2e8f0)',
        uncommon: 'linear-gradient(135deg, #ecfdf5, #d1fae5)',
        rare: 'linear-gradient(135deg, #eff6ff, #dbeafe)',
        epic: 'linear-gradient(135deg, #f5f3ff, #ede9fe)',
        legendary: 'linear-gradient(135deg, #fffbeb, #fef3c7)',
      };
      headerEl.style.background = gradients[plant.rarity] || gradients.common;
    }

    if (rarityEl) {
      rarityEl.textContent = getRarityLabel(plant.rarity);
      rarityEl.className = `plant-card-rarity rarity-${plant.rarity}`;
    }

    _setStatBar('stat-water', plant.stats.water);
    _setStatBar('stat-sun', plant.stats.sun);
    _setStatBar('stat-resistance', plant.stats.resistance);
    _setStatBar('stat-growth', plant.stats.growth);

    // Bouton de capture — actif seulement si à portée
    const btnCapture = document.getElementById('btn-capture-plant');
    if (btnCapture) {
      const inRange = AvatarSystem.isInScanRange(plant);
      const dist = AvatarSystem.distanceToPlant(plant);

      if (inRange) {
        btnCapture.disabled = false;
        if (GameState.isPlantCaptured(plant.id)) {
          btnCapture.innerHTML = '<span>📸</span> Re-photographier';
        } else {
          btnCapture.innerHTML = '<span>📸</span> Scanner cette plante';
        }
      } else {
        btnCapture.disabled = true;
        btnCapture.innerHTML = `<span>🔒</span> Approchez-vous (${Math.round(dist)}m)`;
      }
    }

    document.getElementById('plant-modal')?.classList.remove('hidden');
    _vibrate(30);
  }

  function _setStatBar(elementId, value) {
    const el = document.getElementById(elementId);
    if (!el) return;
    el.style.width = '0%';
    setTimeout(() => {
      el.style.width = `${value}%`;
      if (value >= 80) el.style.background = 'linear-gradient(90deg, #10b981, #6ee7b7)';
      else if (value >= 50) el.style.background = 'linear-gradient(90deg, #3b82f6, #93c5fd)';
      else if (value >= 30) el.style.background = 'linear-gradient(90deg, #f59e0b, #fcd34d)';
      else el.style.background = 'linear-gradient(90deg, #ef4444, #fca5a5)';
    }, 100);
  }

  function closePlantModal() {
    document.getElementById('plant-modal')?.classList.add('hidden');
    _selectedPlant = null;
  }

  // ============================
  // SCANNER & DÉTECTION
  // ============================

  /**
   * Clic sur le bouton Scanner central
   * Vérifie la proximité GPS avant d'ouvrir la caméra
   * @private
   */
  function _onScanButtonClick() {
    _vibrate(50);

    if (!_scanUnlocked) {
      // Scanner verrouillé — afficher un message
      const nearest = AvatarSystem.getNearestPlant();
      if (nearest) {
        showToast('warning', '🔒 Trop loin !',
          `Approchez-vous de ${nearest.plant.emoji} ${nearest.plant.name} (${Math.round(nearest.distance)}m)`);
      } else {
        showToast('warning', '🔒 Aucune plante détectée',
          'Déplacez-vous sur le campus pour trouver de la végétation.');
      }
      return;
    }

    // Scanner débloqué — Appeler le pont Flutter pour le Science Walk
    console.log('📡 Appel du Scanner Bridge Flutter...');
    const currentZoneId = typeof ZoneDetector !== 'undefined' ? ZoneDetector.getCurrentZoneId() : null;
    
    if (window.ScannerBridge) {
      window.ScannerBridge.postMessage(currentZoneId || '');
    } else {
      // Fallback si pas de bridge (ex: navigateur web)
      showToast('info', `🌿 ${_nearbyPlant.name} détecté !`, 'Scanner interne...');
      CameraModule.open();
    }
  }

  /**
   * Clic sur "Capturer cette plante" dans la fiche
   * @private
   */
  function _onCapturePlantClick() {
    if (!_selectedPlant) return;

    const inRange = AvatarSystem.isInScanRange(_selectedPlant);
    if (!inRange) {
      const dist = AvatarSystem.distanceToPlant(_selectedPlant);
      showToast('warning', '🔒 Trop loin',
        `Approchez-vous à moins de ${CONFIG.GPS.SCAN_UNLOCK_RADIUS}m (actuellement ${Math.round(dist)}m)`);
      return;
    }

    closePlantModal();
    CameraModule.open();
  }

  /**
   * Callback quand une photo est prise par le module caméra
   * Lance la détection de végétation
   * @param {string} photoUrl - Data URL de la photo
   */
  async function onPhotoTaken(photoUrl) {
    _lastPhotoUrl = photoUrl;

    // Afficher un toast de chargement
    showToast('info', '🔬 Analyse en cours...', 'Détection de la végétation...');

    // Lancer la détection via PlantDetector
    const gpsPosition = AvatarSystem.getPosition();
    const detection = await PlantDetector.analyzeImage(photoUrl, gpsPosition);

    if (detection.detected && detection.plant) {
      // Plante détectée !
      const result = GameState.capturePlant(detection.plant.id, photoUrl);
      _showCaptureResult(detection.plant, result, photoUrl, detection);
      MapManager.updateMarkerState(detection.plant.id, true);
      _updatePlayerUI();
    } else if (detection.vegetationDetected) {
      // Végétation visible mais pas de plante connue identifiable
      showToast('warning', '🌿 Végétation détectée',
        'Plante non identifiable à cette distance. Rapprochez-vous !');
    } else {
      // Aucune végétation détectée dans l'image
      showToast('error', '❌ Aucune plante détectée',
        'Centrez bien la plante dans le cadre et réessayez.');
    }

    _selectedPlant = null;
  }

  /**
   * Affiche le résultat de la capture
   * @private
   */
  function _showCaptureResult(plant, result, photoUrl, detection) {
    const nameEl = document.getElementById('capture-plant-name');
    const imgEl = document.getElementById('captured-image');
    const xpEl = document.querySelector('.capture-xp');
    const badgeEl = document.getElementById('capture-badge');

    if (nameEl) nameEl.textContent = `${plant.emoji} ${plant.name} identifié${plant.name.endsWith('e') ? 'e' : ''} !`;
    if (imgEl) imgEl.src = photoUrl;
    if (xpEl) xpEl.textContent = `+${result.xpGained} XP`;

    if (badgeEl) {
      if (result.isNew) {
        badgeEl.textContent = '🏆 Nouvelle espèce découverte !';
        badgeEl.style.display = 'inline-block';
      } else {
        badgeEl.textContent = '📸 Photo ajoutée à l\'herbier';
        badgeEl.style.display = 'inline-block';
      }
    }

    if (result.xpResult.leveledUp) {
      showToast('success', '🎉 Niveau supérieur !',
        `${result.xpResult.levelTitle} (Niv. ${result.xpResult.newLevel})`);
    }

    document.getElementById('capture-result-modal')?.classList.remove('hidden');
    _vibrate([50, 100, 50]);
  }

  function _onAddToHerbier() {
    closeCaptureResultModal();
    setTimeout(() => _openHerbierPanel(), 300);
  }

  function closeCaptureResultModal() {
    document.getElementById('capture-result-modal')?.classList.add('hidden');
  }

  // ============================
  // HERBIER
  // ============================

  function _openHerbierPanel() {
    const panel = document.getElementById('herbier-panel');
    const grid = document.getElementById('herbier-grid');
    if (!panel || !grid) return;

    grid.innerHTML = '';
    const capturedIds = GameState.getHerbier();

    document.getElementById('herbier-count').textContent = capturedIds.length;
    document.getElementById('herbier-total').textContent = PLANTS_DATABASE.length;
    document.getElementById('herbier-percent').textContent =
      `${Math.round((capturedIds.length / PLANTS_DATABASE.length) * 100)}%`;

    PLANTS_DATABASE.forEach(plant => {
      const isCaptured = capturedIds.includes(plant.id);
      const item = document.createElement('div');
      item.className = `herbier-item ${isCaptured ? 'discovered' : 'undiscovered'}`;
      item.innerHTML = `
        <span class="herbier-item-icon">${isCaptured ? plant.emoji : '❓'}</span>
        <div class="herbier-item-name">${isCaptured ? plant.name : '???'}</div>
        <div class="herbier-item-latin">${isCaptured ? plant.latinName : 'Non découvert'}</div>
        ${isCaptured ? '<span class="herbier-item-badge">✅</span>' : ''}
      `;
      if (isCaptured) {
        item.addEventListener('click', () => {
          _closePanel('herbier-panel');
          setTimeout(() => openPlantModal(plant), 300);
        });
      }
      grid.appendChild(item);
    });

    panel.classList.remove('hidden');
  }

  // ============================
  // QUÊTES
  // ============================

  function _openQuestsPanel() {
    const panel = document.getElementById('quests-panel');
    const list = document.getElementById('quests-list');
    if (!panel || !list) return;

    list.innerHTML = '';

    const zone = typeof ZoneDetector !== 'undefined' ? ZoneDetector.getCurrentZone() : null;
    if (zone && typeof ZoneService !== 'undefined') {
      const section = document.createElement('div');
      section.className = 'zone-quests-section';
      const contents = ZoneService.getContentsForZone(zone.id);
      const completed = GameState.getZoneContentStates();
      section.innerHTML = `<h3 class="zone-quests-heading">📍 Activités — ${zone.name}</h3>
        <p class="zone-quests-sub">Contenu adapté à votre position (même progression XP / pièces).</p>`;
      const wrap = document.createElement('div');
      wrap.className = 'zone-activity-list';
      contents.forEach(c => {
        const done = !!completed[c.id]?.completed;
        const row = document.createElement('button');
        row.type = 'button';
        row.className = `zone-activity-row ${done ? 'done' : ''}`;
        row.disabled = done;
        const typeIcon = c.content_type === 'quiz' ? '❓' : c.content_type === 'game' ? '🎮' : '📌';
        row.innerHTML = `
          <span class="zone-act-icon">${typeIcon}</span>
          <span class="zone-act-body">
            <span class="zone-act-title">${c.title}</span>
            <span class="zone-act-meta">+${c.reward_xp} XP · +${c.reward_coins} pièces${done ? ' · ✅' : ''}</span>
          </span>`;
        if (!done) {
          row.addEventListener('click', () => {
            if (typeof ZoneUI !== 'undefined') ZoneUI.openActivity(c);
          });
        }
        wrap.appendChild(row);
      });
      section.appendChild(wrap);
      list.appendChild(section);
    }

    QUESTS_DATABASE.forEach(quest => {
      const state = GameState.getQuestState(quest.id);
      const progress = Math.min(state.progress, quest.target);
      const percent = (progress / quest.target) * 100;

      const item = document.createElement('div');
      item.className = `quest-item ${state.completed ? 'completed' : 'active'}`;
      item.innerHTML = `
        <div class="quest-header">
          <span class="quest-icon">${quest.icon}</span>
          <span class="quest-title">${quest.title}</span>
        </div>
        <p class="quest-desc">${quest.description}</p>
        <div class="quest-progress-bar">
          <div class="quest-progress-fill" style="width: ${percent}%"></div>
        </div>
        <div class="quest-progress-text">
          <span>${progress} / ${quest.target}</span>
          <span>${state.completed ? '✅ Complétée' : 'En cours'}</span>
        </div>
        <div class="quest-reward">⭐ +${quest.xpReward} XP</div>
      `;
      list.appendChild(item);
    });

    panel.classList.remove('hidden');
  }

  function _closePanel(panelId) {
    document.getElementById(panelId)?.classList.add('hidden');
    const mapBtn = document.getElementById('btn-nav-map');
    if (mapBtn) _activateNavTab(mapBtn);
  }

  // ============================
  // MISE À JOUR UI JOUEUR
  // ============================

  function _updatePlayerUI() {
    const player = GameState.getPlayer();
    const xpInfo = GameState.getXPInfo();
    const xpProgress = GameState.getXPProgress();

    const nameEl = document.getElementById('player-name');
    const levelEl = document.getElementById('player-level');
    const xpBar = document.getElementById('xp-bar');
    const xpText = document.getElementById('xp-text');

    if (nameEl) nameEl.textContent = player.name;
    if (levelEl) levelEl.textContent = player.level;
    if (xpBar) xpBar.style.width = `${xpProgress}%`;
    if (xpText) xpText.textContent = `${xpInfo.current} / ${xpInfo.needed} XP`;

    const coinEl = document.getElementById('player-coins');
    if (coinEl) coinEl.textContent = String(player.coins ?? 0);
  }

  // ============================
  // NOTIFICATIONS TOAST
  // ============================

  function showToast(type, title, message) {
    // SILENCE non-critical popups in native mode to avoid cluttering the HUD
    const isNative = document.documentElement.classList.contains('is-native');
    if (isNative && type !== 'success' && type !== 'error') return;

    const container = document.getElementById('toast-container');
    if (!container) return;

    const icons = { success: '✅', warning: '⚠️', info: 'ℹ️', error: '❌' };

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `
      <span class="toast-icon">${icons[type] || icons.info}</span>
      <div class="toast-content">
        <div class="toast-title">${title}</div>
        ${message ? `<div class="toast-message">${message}</div>` : ''}
      </div>
    `;

    container.appendChild(toast);

    setTimeout(() => {
      toast.classList.add('toast-exit');
      setTimeout(() => toast.remove(), 300);
    }, CONFIG.UI.TOAST_DURATION);
  }

  /**
   * Synchronise les données utilisateur depuis le pont Flutter
   * @param {Object} data - {name, xp, level}
   */
  function syncFromFlutter(data) {
    if (!data) return;
    console.log('📡 Sync Flutter: Data received', data);
    
    const player = GameState.getPlayer();
    if (data.name) player.name = data.name;
    if (data.xp !== undefined) player.totalXp = data.xp;
    if (data.level !== undefined) player.level = data.level;
    
    _updatePlayerUI();
  }

  // ============================================
  // ELITE BOTANICAL HUB (EZ-TREE)
  // ============================================

  function _bindBotanicalHubEvents() {
    document.getElementById('btn-close-prediction-hub')?.addEventListener('click', _closeBotanicalHub);
  }

  function _openPredictionPanel() {
    document.getElementById('prediction-panel')?.classList.remove('hidden');
  }

  function openBotanicalHub(plant) {
    // Left empty or reimplemented if they need 3D plant viewing back
  }

  function _closeBotanicalHub() {
    _vibrate(20);
  }

  // API publique
  return {
    init,
    updateLoadingBar,
    hideLoadingScreen,
    createLoadingParticles,
    openPlantModal,
    closePlantModal,
    openBotanicalHub,
    syncFromFlutter,
    closeCaptureResultModal,
    onPhotoTaken,
    showToast,
    refreshPlayerBar: _updatePlayerUI,
  };
})();

// Bridge Flutter -> Web
window.syncFromFlutter = UIController.syncFromFlutter;
window.openBotanicalHub = UIController.openBotanicalHub;
