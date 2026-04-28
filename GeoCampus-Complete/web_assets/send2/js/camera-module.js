/**
 * ============================================
 * CAMERA-MODULE.JS — Module Appareil Photo
 * Future Roots — Campus de la Manouba
 * ============================================
 *
 * Ce module gère :
 * - L'ouverture de la caméra du smartphone
 * - La capture de photos via MediaStream API
 * - Le basculement caméra avant/arrière
 * - Le traitement et la sauvegarde des images
 */

const CameraModule = (() => {
  // Variables privées
  let _stream = null;
  let _videoElement = null;
  let _canvasElement = null;
  let _isOpen = false;
  let _facingMode = CONFIG.CAMERA.PREFERRED_FACING;
  let _onPhotoTaken = null;

  /**
   * Initialise le module caméra
   * @param {Object} callbacks - Callbacks d'événements
   */
  function init(callbacks = {}) {
    _videoElement = document.getElementById('camera-feed');
    _canvasElement = document.getElementById('camera-canvas');
    _onPhotoTaken = callbacks.onPhotoTaken || null;

    // Boutons de contrôle
    const btnTakePhoto = document.getElementById('btn-take-photo');
    const btnSwitchCamera = document.getElementById('btn-switch-camera');
    const btnCloseCamera = document.getElementById('btn-close-camera');

    if (btnTakePhoto) {
      btnTakePhoto.addEventListener('click', takePhoto);
    }
    if (btnSwitchCamera) {
      btnSwitchCamera.addEventListener('click', switchCamera);
    }
    if (btnCloseCamera) {
      btnCloseCamera.addEventListener('click', close);
    }

    console.log('📷 Module caméra initialisé');
  }

  /**
   * Ouvre la caméra du smartphone
   * @returns {Promise<boolean>} true si la caméra est ouverte
   */
  async function open() {
    try {
      // Vérifier le support de getUserMedia
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        UIController.showToast('error', 'Caméra Indisponible',
          'Votre navigateur ne supporte pas l\'accès à la caméra.');
        return false;
      }

      // Arrêter tout flux existant
      _stopStream();

      // Demander l'accès à la caméra
      const constraints = {
        video: {
          facingMode: _facingMode,
          width: { ideal: CONFIG.CAMERA.PHOTO_MAX_WIDTH },
          height: { ideal: CONFIG.CAMERA.PHOTO_MAX_WIDTH },
        },
        audio: false,
      };

      _stream = await navigator.mediaDevices.getUserMedia(constraints);

      // Connecter le flux vidéo à l'élément <video>
      if (_videoElement) {
        _videoElement.srcObject = _stream;
        await _videoElement.play();
      }

      // Afficher le modal caméra
      const modal = document.getElementById('camera-modal');
      if (modal) modal.classList.remove('hidden');

      _isOpen = true;
      console.log('📷 Caméra ouverte');
      return true;
    } catch (error) {
      console.error('❌ Erreur caméra:', error);

      let message = 'Impossible d\'accéder à la caméra.';
      if (error.name === 'NotAllowedError') {
        message = 'Accès à la caméra refusé. Vérifiez les permissions.';
      } else if (error.name === 'NotFoundError') {
        message = 'Aucune caméra détectée sur cet appareil.';
      } else if (error.name === 'NotReadableError') {
        message = 'La caméra est déjà utilisée par une autre application.';
      }

      UIController.showToast('error', 'Erreur Caméra', message);
      return false;
    }
  }

  /**
   * Ferme la caméra et libère les ressources
   */
  function close() {
    _stopStream();

    // Cacher le modal
    const modal = document.getElementById('camera-modal');
    if (modal) modal.classList.add('hidden');

    _isOpen = false;
    console.log('📷 Caméra fermée');
  }

  /**
   * Arrête le flux vidéo
   * @private
   */
  function _stopStream() {
    if (_stream) {
      _stream.getTracks().forEach(track => track.stop());
      _stream = null;
    }
    if (_videoElement) {
      _videoElement.srcObject = null;
    }
  }

  /**
   * Capture une photo à partir du flux vidéo
   * @returns {string|null} URL de l'image capturée (data URL)
   */
  function takePhoto() {
    if (!_stream || !_videoElement || !_canvasElement) {
      console.warn('⚠️ Caméra non prête pour la capture');
      return null;
    }

    // Configurer le canvas aux dimensions de la vidéo
    const width = _videoElement.videoWidth;
    const height = _videoElement.videoHeight;

    // Limiter la taille pour les performances
    const maxWidth = CONFIG.CAMERA.PHOTO_MAX_WIDTH;
    let canvasWidth = width;
    let canvasHeight = height;

    if (width > maxWidth) {
      canvasWidth = maxWidth;
      canvasHeight = Math.round(height * (maxWidth / width));
    }

    _canvasElement.width = canvasWidth;
    _canvasElement.height = canvasHeight;

    // Dessiner la frame actuelle
    const ctx = _canvasElement.getContext('2d');
    ctx.drawImage(_videoElement, 0, 0, canvasWidth, canvasHeight);

    // Convertir en Data URL (JPEG pour la compression)
    const imageDataUrl = _canvasElement.toDataURL(
      'image/jpeg',
      CONFIG.CAMERA.PHOTO_QUALITY
    );

    // Effet visuel de flash
    _flashEffect();

    // Fermer la caméra
    close();

    // Notifier l'observateur
    if (_onPhotoTaken) {
      _onPhotoTaken(imageDataUrl);
    }

    console.log('📸 Photo capturée avec succès');
    return imageDataUrl;
  }

  /**
   * Bascule entre la caméra avant et arrière
   */
  async function switchCamera() {
    _facingMode = _facingMode === 'environment' ? 'user' : 'environment';
    if (_isOpen) {
      await open(); // Re-ouvrir avec le nouveau mode
    }
    console.log(`📷 Caméra basculée vers: ${_facingMode}`);
  }

  /**
   * Effet de flash lors de la prise de photo
   * @private
   */
  function _flashEffect() {
    const flash = document.createElement('div');
    flash.style.cssText = `
      position: fixed;
      inset: 0;
      background: white;
      z-index: 9999;
      animation: camera-flash 0.3s ease-out forwards;
      pointer-events: none;
    `;

    // Ajouter l'animation de flash
    const style = document.createElement('style');
    style.textContent = `
      @keyframes camera-flash {
        0% { opacity: 0.8; }
        100% { opacity: 0; }
      }
    `;
    document.head.appendChild(style);
    document.body.appendChild(flash);

    // Supprimer après l'animation
    setTimeout(() => {
      flash.remove();
      style.remove();
    }, 400);
  }

  /**
   * Vérifie si la caméra est ouverte
   * @returns {boolean}
   */
  function isOpen() {
    return _isOpen;
  }

  // API publique
  return {
    init,
    open,
    close,
    takePhoto,
    switchCamera,
    isOpen,
  };
})();
