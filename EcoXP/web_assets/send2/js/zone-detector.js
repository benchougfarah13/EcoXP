/**
 * Détection entrée/sortie de zone — GPS continu (Haversine).
 * Chevauchement : priorité à la zone dont le centre est le plus proche du joueur.
 */
const ZoneDetector = (() => {
  let _currentZoneId = null;
  let _listeners = { enter: [], exit: [], moveInside: [] };

  function _haversineM(lat1, lng1, lat2, lng2) {
    const R = 6371000;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  /**
   * @param {number} lat
   * @param {number} lng
   * @returns {Object|null} zone la plus pertinente ou null
   */
  function resolveZone(lat, lng) {
    const zones = ZoneService.getZones();
    if (!zones.length) return null;

    const inside = zones
      .map(z => ({
        zone: z,
        dist: _haversineM(lat, lng, z.latitude, z.longitude),
      }))
      .filter(x => x.dist <= x.zone.radius);

    if (!inside.length) return null;
    inside.sort((a, b) => a.dist - b.dist);
    return inside[0].zone;
  }

  function on(event, fn) {
    if (_listeners[event]) _listeners[event].push(fn);
  }

  function updateFromPosition(position) {
    if (!position || ZoneService.getZones().length === 0) return;

    const next = resolveZone(position.lat, position.lng);
    const nextId = next ? next.id : null;

    if (nextId === _currentZoneId) {
      if (next) _listeners.moveInside.forEach(fn => fn(next, position));
      return;
    }

    const prevId = _currentZoneId;
    const prevZone = prevId ? ZoneService.getZoneById(prevId) : null;

    _currentZoneId = nextId;

    if (prevId && !nextId) {
      _listeners.exit.forEach(fn => fn(prevZone, position));
    }
    if (nextId && nextId !== prevId) {
      _listeners.enter.forEach(fn => fn(next, position));
    }
  }

  function getCurrentZone() {
    if (!_currentZoneId) return null;
    return ZoneService.getZoneById(_currentZoneId);
  }

  function getCurrentZoneId() {
    return _currentZoneId;
  }

  return {
    resolveZone,
    updateFromPosition,
    on,
    getCurrentZone,
    getCurrentZoneId,
  };
})();
