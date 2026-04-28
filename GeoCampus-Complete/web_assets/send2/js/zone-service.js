/**
 * Charge zones + contenus depuis l’API backend, avec repli sur ZONES_CATALOG.
 */
const ZoneService = (() => {
  let _cache = { zones: [], contents: [] };
  let _loaded = false;

  function _cloneCatalog() {
    return JSON.parse(JSON.stringify(ZONES_CATALOG));
  }

  /**
   * @returns {Promise<{ zones: Array, contents: Array }>}
   */
  async function load() {
    const url = CONFIG.ZONES?.API_BASE;
    if (!url) {
      _cache = _cloneCatalog();
      _loaded = true;
      return _cache;
    }
    try {
      const res = await fetch(`${url.replace(/\/$/, '')}/api/zones`, { cache: 'no-store' });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      if (!Array.isArray(data.zones) || !Array.isArray(data.contents)) throw new Error('Invalid payload');
      _cache = { zones: data.zones, contents: data.contents };
      _loaded = true;
      console.log('🗺️ Zones chargées depuis l’API');
      return _cache;
    } catch (e) {
      console.warn('⚠️ API zones indisponible, catalogue local:', e.message);
      _cache = _cloneCatalog();
      _loaded = true;
      return _cache;
    }
  }

  function getZones() {
    return _cache.zones;
  }

  function getContentsForZone(zoneId) {
    return _cache.contents.filter(c => c.zone_id === zoneId);
  }

  function getZoneById(zoneId) {
    return _cache.zones.find(z => z.id === zoneId) || null;
  }

  function isReady() {
    return _loaded;
  }

  return { load, getZones, getContentsForZone, getZoneById, isReady };
})();
