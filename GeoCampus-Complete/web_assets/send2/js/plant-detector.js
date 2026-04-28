/**
 * ============================================
 * PLANT-DETECTOR.JS — Détection de végétation
 * Future Roots — Campus de la Manouba
 * ============================================
 *
 * Ce module gère :
 * - L'analyse de l'image capturée pour détecter la végétation
 * - L'identification du type de plante basée sur la couleur
 *   et la position GPS de l'utilisateur
 * - Le scoring de confiance pour chaque détection
 * 
 * Note : Ce module utilise une approche hybride :
 * 1. Analyse colorimétrique de l'image (détection de vert/végétation)
 * 2. Correspondance GPS avec les plantes connues du campus
 * 3. Fusion des deux signaux pour identifier la plante
 */

const PlantDetector = (() => {

  // Seuils de détection
  const GREEN_THRESHOLD = 0.15;     // % minimum de pixels verts pour valider
  const CONFIDENCE_MIN = 0.3;       // Confiance minimum pour accepter

  /**
   * Analyse une image capturée et tente d'identifier la plante
   * @param {string} imageDataUrl - Data URL de l'image
   * @param {Object} gpsPosition - Position GPS actuelle { lat, lng }
   * @returns {Promise<Object>} Résultat de la détection
   */
  async function analyzeImage(imageDataUrl, gpsPosition) {
    console.log('🔬 Analyse de l\'image en cours...');

    // Étape 1 : Analyser la végétation dans l'image
    const colorAnalysis = await _analyzeColors(imageDataUrl);

    // Étape 2 : Trouver la plante la plus proche par GPS
    const nearestPlant = _findNearestPlant(gpsPosition);

    // Étape 3 : Calculer le score de confiance
    const result = _computeDetectionResult(colorAnalysis, nearestPlant);

    console.log(`🌿 Détection: ${result.detected ? result.plant.name : 'Aucune plante'} (confiance: ${Math.round(result.confidence * 100)}%)`);

    return result;
  }

  /**
   * Analyse les couleurs dominantes de l'image
   * pour détecter la présence de végétation
   * @private
   * @param {string} imageDataUrl - Data URL de l'image
   * @returns {Promise<Object>} Analyse colorimétrique
   */
  function _analyzeColors(imageDataUrl) {
    return new Promise((resolve) => {
      const img = new Image();
      img.onload = () => {
        // Créer un canvas temporaire pour analyser les pixels
        const canvas = document.createElement('canvas');
        const size = 100; // Réduire pour la performance
        canvas.width = size;
        canvas.height = size;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, size, size);

        const imageData = ctx.getImageData(0, 0, size, size);
        const pixels = imageData.data;
        const totalPixels = size * size;

        let greenPixels = 0;
        let brownPixels = 0;
        let flowerPixels = 0;  // Rose/violet/rouge
        let skyPixels = 0;

        for (let i = 0; i < pixels.length; i += 4) {
          const r = pixels[i];
          const g = pixels[i + 1];
          const b = pixels[i + 2];

          // Détecter les pixels verts (végétation)
          if (g > 80 && g > r * 1.15 && g > b * 1.15) {
            greenPixels++;
          }
          // Détecter les pixels bruns (troncs, terre)
          if (r > 80 && g > 50 && b < 80 && r > g * 0.9 && r < g * 1.8) {
            brownPixels++;
          }
          // Détecter les fleurs (rose, violet, rouge vif)
          if ((r > 150 && g < 100 && b < 150) ||
              (r > 100 && b > 120 && g < 100) ||
              (r > 180 && g < 80)) {
            flowerPixels++;
          }
          // Ciel bleu
          if (b > 150 && b > r * 1.3 && b > g * 1.1) {
            skyPixels++;
          }
        }

        resolve({
          greenRatio: greenPixels / totalPixels,
          brownRatio: brownPixels / totalPixels,
          flowerRatio: flowerPixels / totalPixels,
          skyRatio: skyPixels / totalPixels,
          hasVegetation: (greenPixels / totalPixels) > GREEN_THRESHOLD,
          dominantType: _getDominantType(greenPixels, brownPixels, flowerPixels, totalPixels),
        });
      };
      img.onerror = () => {
        resolve({ greenRatio: 0, brownRatio: 0, flowerRatio: 0, skyRatio: 0, hasVegetation: false, dominantType: 'unknown' });
      };
      img.src = imageDataUrl;
    });
  }

  /**
   * Détermine le type dominant de végétation détecté
   * @private
   */
  function _getDominantType(green, brown, flower, total) {
    const greenPct = green / total;
    const brownPct = brown / total;
    const flowerPct = flower / total;

    if (flowerPct > 0.08) return 'flowering';      // Plante à fleurs
    if (greenPct > 0.4 && brownPct > 0.1) return 'tree';  // Arbre
    if (greenPct > 0.3) return 'shrub';             // Arbuste/buisson
    if (greenPct > GREEN_THRESHOLD) return 'plant';  // Plante générique
    if (brownPct > 0.15) return 'trunk';            // Tronc d'arbre
    return 'unknown';
  }

  /**
   * Trouve la plante la plus proche par position GPS
   * @private
   * @param {Object} gpsPosition - { lat, lng }
   * @returns {Object} { plant, distance }
   */
  function _findNearestPlant(gpsPosition) {
    if (!gpsPosition) return { plant: null, distance: Infinity };

    let nearest = null;
    let minDist = Infinity;

    PLANTS_DATABASE.forEach(plant => {
      const dist = _haversineDistance(
        gpsPosition.lat, gpsPosition.lng,
        plant.position.lat, plant.position.lng
      );
      if (dist < minDist) {
        minDist = dist;
        nearest = plant;
      }
    });

    return { plant: nearest, distance: minDist };
  }

  /**
   * Combine l'analyse couleur et GPS pour un résultat final
   * @private
   */
  function _computeDetectionResult(colorAnalysis, nearestPlant) {
    const { plant, distance } = nearestPlant;

    // Pas de plante à portée
    if (!plant || distance > CONFIG.GPS.SCAN_UNLOCK_RADIUS) {
      return {
        detected: false,
        plant: null,
        confidence: 0,
        reason: 'Aucune plante connue à proximité',
        vegetationDetected: colorAnalysis.hasVegetation,
        colorAnalysis,
      };
    }

    // Calculer la confiance basée sur la distance GPS (plus proche = plus confiant)
    const distanceConfidence = Math.max(0, 1 - (distance / CONFIG.GPS.SCAN_UNLOCK_RADIUS));

    // Confiance basée sur la détection visuelle
    let visualConfidence = 0;
    if (colorAnalysis.hasVegetation) {
      visualConfidence = Math.min(colorAnalysis.greenRatio * 2, 0.8);

      // Bonus si le type visuel correspond au type de plante
      if (colorAnalysis.dominantType === 'flowering' &&
          ['jasmine', 'bush_flowers'].includes(plant.id)) {
        visualConfidence += 0.2;
      }
      if (colorAnalysis.dominantType === 'tree' &&
          ['olive_tree', 'pine_tree', 'orange_tree', 'apple_tree', 'pear_tree', 'palm_tree'].includes(plant.id)) {
        visualConfidence += 0.15;
      }
    }

    // Score final : 60% GPS + 40% visuel
    const confidence = Math.min((distanceConfidence * 0.6) + (visualConfidence * 0.4), 1);

    return {
      detected: confidence >= CONFIDENCE_MIN,
      plant: plant,
      confidence: confidence,
      distance: Math.round(distance),
      vegetationDetected: colorAnalysis.hasVegetation,
      visualType: colorAnalysis.dominantType,
      colorAnalysis,
    };
  }

  /**
   * Calcul de distance Haversine
   * @private
   */
  function _haversineDistance(lat1, lng1, lat2, lng2) {
    const R = 6371000;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) ** 2 +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  // API publique
  return {
    analyzeImage,
  };
})();
