// GeoCampus backend contract (Django REST + PostGIS) — implement on server.
//
// Core tables (PostgreSQL):
// - users(id, firebase_uid, username, faculty, xp, coins, title, avatar_tier, streak, updated_at)
// - campus_zones(id, name, polygon geography, base_health, current_health)
// - plant_scans(id, user_id, zone_id, image_url, recognized_name, confidence, gps geography, created_at)
// - missions(id, title, kind, xp_reward, coin_reward, resets_daily)
// - user_missions(user_id, mission_id, completed_at, claim_state)
// - events(id, title, organizer_id, starts_at, qr_secret_hmac, location geography)
// - event_checkins(id, event_id, user_id, qr_payload, validated_at)
// - leaderboards(scope, period_start, user_id, score)  -- scope: global | faculty | weekly
//
// REST sketch:
// POST /api/v1/scans          body: multipart image + zone_id + lat + lng
// POST /api/v1/events/verify body: { event_id, qr_payload }
// GET  /api/v1/zones/health   returns GeoJSON + health per zone
// GET  /api/v1/leaderboard    query: scope, faculty?, week?
// POST /api/v1/missions/claim body: { mission_id }
// GET  /api/v1/missions/daily query: user_id
//
// Flutter today uses Firebase for XP/trophies to match the merged Mother Earth app.
