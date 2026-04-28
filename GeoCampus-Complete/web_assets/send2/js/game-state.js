/**
 * ============================================
 * GAME-STATE.JS — Gestion de l'état du jeu
 * Future Roots — Campus de la Manouba
 * ============================================
 *
 * Ce module gère :
 * - La persistance des données (localStorage)
 * - Le système de progression (XP, niveaux)
 * - L'herbier (plantes capturées)
 * - Les quêtes et récompenses
 */

window.GameState = (() => {
  // Clé de sauvegarde dans le localStorage
  const STORAGE_KEY = 'future_roots_save';

  // État par défaut du jeu
  const DEFAULT_STATE = {
    player: {
      name: 'Explorateur',
      xp: 0,
      level: 1,
      coins: 0,
      totalCaptures: 0,
      totalPhotos: 0,
    },
    herbier: [],          // IDs des plantes capturées
    photos: [],           // Photos prises { plantId, dataUrl, timestamp }
    quests: {},           // État des quêtes { questId: { progress, completed } }
    settings: {
      soundEnabled: true,
      vibrationEnabled: true,
    },
    firstLaunch: true,
    lastPlayed: null,
    /** Smart zones — contenu complété (anti-abus : une récompense par activité) */
    zoneContent: {},
    /** Dernier timestamp bonus d’entrée par zone_id */
    zoneEntryBonusAt: {},
    badges: [],
    leaderboardScore: 0,
  };

  // État courant en mémoire
  let _state = null;

  /**
   * Initialise l'état du jeu (charge ou crée une sauvegarde)
   */
  function init() {
    _state = _loadFromStorage();

    if (!_state) {
      _state = JSON.parse(JSON.stringify(DEFAULT_STATE));
      console.log('🎮 Nouvelle partie créée');
    } else {
      console.log(`🎮 Sauvegarde chargée — Niveau ${_state.player.level}, ${_state.herbier.length} plantes`);
    }

    if (_state.player.coins === undefined || _state.player.coins === null) _state.player.coins = 0;
    if (!_state.zoneContent) _state.zoneContent = {};
    if (!_state.zoneEntryBonusAt) _state.zoneEntryBonusAt = {};
    if (!_state.badges) _state.badges = [];
    if (_state.leaderboardScore === undefined || _state.leaderboardScore === null) _state.leaderboardScore = 0;

    // Initialiser les quêtes manquantes
    QUESTS_DATABASE.forEach(quest => {
      if (!_state.quests[quest.id]) {
        _state.quests[quest.id] = { progress: 0, completed: false };
      }
    });

    _state.lastPlayed = new Date().toISOString();
    _saveToStorage();
  }

  /**
   * Charge la sauvegarde depuis le localStorage
   * @private
   * @returns {Object|null}
   */
  function _loadFromStorage() {
    try {
      const data = localStorage.getItem(STORAGE_KEY);
      return data ? JSON.parse(data) : null;
    } catch (error) {
      console.warn('⚠️ Erreur de chargement de la sauvegarde:', error);
      return null;
    }
  }

  /**
   * Sauvegarde l'état dans le localStorage
   * @private
   */
  function _saveToStorage() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(_state));
    } catch (error) {
      console.warn('⚠️ Erreur de sauvegarde:', error);
    }
  }

  /**
   * Ajoute de l'XP au joueur et vérifie la montée de niveau
   * @param {number} amount - Quantité d'XP à ajouter
   * @returns {Object} { newXp, newLevel, leveledUp }
   */
  function addXP(amount) {
    const oldLevel = _state.player.level;
    _state.player.xp += amount;

    // Vérifier la montée de niveau
    let newLevel = oldLevel;
    for (let i = CONFIG.GAME.LEVELS.length - 1; i >= 0; i--) {
      if (_state.player.xp >= CONFIG.GAME.LEVELS[i]) {
        newLevel = i + 1;
        break;
      }
    }

    const leveledUp = newLevel > oldLevel;
    _state.player.level = newLevel;

    _saveToStorage();

    return {
      newXp: _state.player.xp,
      newLevel,
      leveledUp,
      levelTitle: CONFIG.GAME.LEVEL_TITLES[newLevel - 1] || 'Maître',
    };
  }

  function addCoins(amount) {
    _state.player.coins = (_state.player.coins || 0) + amount;
    _saveToStorage();
    return _state.player.coins;
  }

  /**
   * Bonus discret à l’entrée d’une zone (cooldown par zone).
   * @returns {{ granted: boolean, xp?: number, coins?: number }}
   */
  function tryGrantZoneEntryBonus(zoneId) {
    const now = Date.now();
    const last = _state.zoneEntryBonusAt[zoneId] || 0;
    const cd = CONFIG.ZONES?.ENTRY_BONUS_COOLDOWN_MS ?? 1800000;
    if (now - last < cd) return { granted: false };

    _state.zoneEntryBonusAt[zoneId] = now;
    const xp = CONFIG.ZONES?.ENTRY_BONUS_XP ?? 5;
    const coins = CONFIG.ZONES?.ENTRY_BONUS_COINS ?? 2;
    addXP(xp);
    addCoins(coins);
    _state.leaderboardScore += xp + coins * 2;
    _saveToStorage();
    return { granted: true, xp, coins };
  }

  function isZoneContentCompleted(contentId) {
    return !!(_state.zoneContent[contentId]?.completed);
  }

  /**
   * Applique récompense fin d’activité zone (mission / quiz / mini-jeu).
   * @returns {{ ok: boolean, reason?: string, xpResult?: object, coins?: number, badgeId?: string }}
   */
  function completeZoneContent(payload) {
    const { contentId, xp: xpReward, coins: coinReward, badgeId } = payload;
    if (_state.zoneContent[contentId]?.completed) {
      return { ok: false, reason: 'already_completed' };
    }

    _state.zoneContent[contentId] = {
      completed: true,
      completedAt: new Date().toISOString(),
    };

    const xpResult = addXP(xpReward || 0);
    const totalCoins = addCoins(coinReward || 0);
    if (badgeId && !_state.badges.includes(badgeId)) {
      _state.badges.push(badgeId);
    }
    _state.leaderboardScore += (xpReward || 0) + (coinReward || 0) * 3;

    _saveToStorage();

    return {
      ok: true,
      xpResult,
      coins: totalCoins,
      badgeId: badgeId || null,
    };
  }

  function getZoneContentStates() {
    return { ..._state.zoneContent };
  }

  function getBadges() {
    return [...(_state.badges || [])];
  }

  function getLeaderboardScore() {
    return _state.leaderboardScore || 0;
  }

  /**
   * Capture une plante (ajout à l'herbier)
   * @param {string} plantId - ID de la plante
   * @param {string} photoUrl - URL de la photo (optionnel)
   * @returns {Object} { isNew, xpGained, result }
   */
  function capturePlant(plantId, photoUrl = null) {
    const isNew = !_state.herbier.includes(plantId);
    let xpGained = CONFIG.GAME.XP_PER_CAPTURE;

    // Bonus XP pour première découverte
    if (isNew) {
      _state.herbier.push(plantId);
      xpGained += CONFIG.GAME.XP_PER_FIRST_DISCOVERY;
    }

    _state.player.totalCaptures++;

    // Sauvegarder la photo si fournie
    if (photoUrl) {
      _state.photos.push({
        plantId,
        dataUrl: photoUrl,
        timestamp: new Date().toISOString(),
      });
      _state.player.totalPhotos++;
    }

    // Ajouter l'XP
    const xpResult = addXP(xpGained);

    // Mettre à jour les quêtes
    _updateQuests(plantId);

    _saveToStorage();

    return {
      isNew,
      xpGained,
      xpResult,
      herbierCount: _state.herbier.length,
    };
  }

  /**
   * Met à jour la progression des quêtes
   * @private
   * @param {string} plantId - ID de la plante capturée
   */
  function _updateQuests(plantId) {
    QUESTS_DATABASE.forEach(quest => {
      const questState = _state.quests[quest.id];
      if (questState.completed) return;

      switch (quest.type) {
        case 'discovery':
          questState.progress = _state.herbier.length;
          break;
        case 'collection':
          questState.progress = _state.herbier.length;
          break;
        case 'photo':
          questState.progress = _state.player.totalPhotos;
          break;
        case 'specific':
          if (quest.targetPlantId === plantId) {
            questState.progress = 1;
          }
          break;
      }

      // Vérifier si la quête est complétée
      if (questState.progress >= quest.target && !questState.completed) {
        questState.completed = true;
        addXP(quest.xpReward);

        // Notifier l'UI
        setTimeout(() => {
          UIController.showToast('success', '🎉 Quête Complétée !',
            `${quest.title} — +${quest.xpReward} XP`);
        }, 1500);
      }
    });
  }

  /**
   * Vérifie si une plante a été capturée
   * @param {string} plantId - ID de la plante
   * @returns {boolean}
   */
  function isPlantCaptured(plantId) {
    return _state ? _state.herbier.includes(plantId) : false;
  }

  /**
   * Retourne les données du joueur
   * @returns {Object}
   */
  function getPlayer() {
    return _state ? { ..._state.player } : DEFAULT_STATE.player;
  }

  /**
   * Retourne la liste des plantes capturées
   * @returns {Array} Liste des IDs
   */
  function getHerbier() {
    return _state ? [..._state.herbier] : [];
  }

  /**
   * Retourne les photos capturées
   * @returns {Array}
   */
  function getPhotos() {
    return _state ? [..._state.photos] : [];
  }

  /**
   * Retourne l'état d'une quête
   * @param {string} questId - ID de la quête
   * @returns {Object} { progress, completed }
   */
  function getQuestState(questId) {
    return _state && _state.quests[questId]
      ? { ..._state.quests[questId] }
      : { progress: 0, completed: false };
  }

  /**
   * Retourne le pourcentage de progression XP vers le prochain niveau
   * @returns {number} Pourcentage (0-100)
   */
  function getXPProgress() {
    if (!_state) return 0;
    const level = _state.player.level;
    const currentLevelXP = CONFIG.GAME.LEVELS[level - 1] || 0;
    const nextLevelXP = CONFIG.GAME.LEVELS[level] || CONFIG.GAME.LEVELS[CONFIG.GAME.LEVELS.length - 1];
    const progress = (((_state.player.xp - currentLevelXP) / (nextLevelXP - currentLevelXP)) * 100);
    return Math.min(Math.max(progress, 0), 100);
  }

  /**
   * Retourne l'XP nécessaire pour le prochain niveau
   * @returns {Object} { current, needed }
   */
  function getXPInfo() {
    if (!_state) return { current: 0, needed: 100 };
    const level = _state.player.level;
    const currentLevelXP = CONFIG.GAME.LEVELS[level - 1] || 0;
    const nextLevelXP = CONFIG.GAME.LEVELS[level] || CONFIG.GAME.LEVELS[CONFIG.GAME.LEVELS.length - 1];
    return {
      current: _state.player.xp - currentLevelXP,
      needed: nextLevelXP - currentLevelXP,
    };
  }

  /**
   * Synchronise les données depuis l'application Flutter.
   * @param {Object} data - { fullName, xp, level, trophies }
   */
  function syncFromFlutter(data) {
    if (!_state) init();
    if (data.fullName) _state.player.name = data.fullName;
    if (data.xp !== undefined) _state.player.xp = data.xp;
    if (data.level !== undefined) _state.player.level = data.level;
    if (data.trophies !== undefined) _state.player.coins = data.trophies; // Utiliser les trophées comme monnaie pour le démo?
    
    _saveToStorage();
    UIController.refreshPlayerBar();
    
    // Forcer la mise à jour immédiate du DOM pour le nom (correction du bug "Explorateur")
    const nameEl = document.getElementById('player-name');
    if (nameEl && data.fullName) {
      nameEl.textContent = data.fullName;
    }
    
    console.log('🔄 Données synchronisées depuis Flutter');
  }

  // API publique
  return {
    init,
    syncFromFlutter,
    addXP,
    addCoins,
    tryGrantZoneEntryBonus,
    isZoneContentCompleted,
    completeZoneContent,
    getZoneContentStates,
    getBadges,
    getLeaderboardScore,
    capturePlant,
    isPlantCaptured,
    getPlayer,
    getHerbier,
    getPhotos,
    getQuestState,
    getXPProgress,
    getXPInfo,
  };
})();
