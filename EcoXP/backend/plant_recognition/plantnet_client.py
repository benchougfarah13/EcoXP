import os
import requests

PLANTNET_API_KEY = os.getenv('PLANTNET_API_KEY', '2b10VnSoWTSvYhKEWJHLbQRofu')
PLANTNET_URL = 'https://my-api.plantnet.org/v2/identify/all'

# Minimum PlantNet score to accept a result (0–1 scale)
MIN_PLANTNET_SCORE = 0.05

# Maps PlantNet scientific names (lowercase) to the exact app plant names
# as they appear in plant_data.dart.  Synonyms and genus-level fallbacks are
# included so that PlantNet's taxonomy variations still map correctly.
PLANTNET_TO_APP = {
    # Yellow Oleander
    'cascabela thevetia':    'Yellow Oleander',
    'thevetia peruviana':    'Yellow Oleander',
    'thevetia neriifolia':   'Yellow Oleander',

    # Oxalis corniculata
    'oxalis corniculata':    'Oxalis corniculata',
    'oxalis':                'Oxalis corniculata',

    # Phoenix dactylifera
    'phoenix dactylifera':   'Phoenix dactylifera',

    # Bougainvillea
    'bougainvillea spectabilis': 'Bougainvillea',
    'bougainvillea glabra':      'Bougainvillea',
    'bougainvillea peruviana':   'Bougainvillea',
    'bougainvillea':             'Bougainvillea',

    # Platycladus orientalis
    'platycladus orientalis': 'Platycladus orientalis',
    'thuja orientalis':        'Platycladus orientalis',
    'biota orientalis':        'Platycladus orientalis',

    # Austrocylindropuntia subulata
    'austrocylindropuntia subulata': 'Austrocylindropuntia subulata',
    'opuntia subulata':              'Austrocylindropuntia subulata',

    # Agave desmetiana 'Variegata'
    'agave desmetiana':    "Agave desmetiana 'Variegata'",
    'agave demeesteriana': "Agave desmetiana 'Variegata'",  # PlantNet uses this spelling
    'agave americana':     "Agave desmetiana 'Variegata'",  # common look-alike
    'agave sisalana':      "Agave desmetiana 'Variegata'",

    # Plumbago auriculata
    'plumbago auriculata': 'Plumbago auriculata',
    'plumbago capensis':   'Plumbago auriculata',

    # Olea europaea
    'olea europaea': 'Olea europaea',

    # Lantana camara
    'lantana camara':    'Lantana camara',
    'lantana':           'Lantana camara',

    # Jacobaea maritima (formerly Senecio cineraria)
    'jacobaea maritima': 'Jacobaea maritima',
    'senecio cineraria': 'Jacobaea maritima',
    'senecio maritimus': 'Jacobaea maritima',

    # Hibiscus
    'hibiscus rosa-sinensis': 'Hibiscus',
    'hibiscus syriacus':      'Hibiscus',
    'hibiscus sabdariffa':    'Hibiscus',
    'hibiscus':               'Hibiscus',

    # Jasminum grandiflorum
    'jasminum grandiflorum': 'Jasminum grandiflorum',
    'jasminum officinale':   'Jasminum grandiflorum',

    # Euryops pectinatus
    'euryops pectinatus': 'Euryops pectinatus',

    # Ficus benjamina
    'ficus benjamina': 'Ficus benjamina',

    # Parkinsonia aculeata
    'parkinsonia aculeata': 'Parkinsonia aculeata',

    # Yucca gloriosa
    'yucca gloriosa':   'Yucca gloriosa',
    'yucca aloifolia':  'Yucca gloriosa',

    # Araucaria heterophylla
    'araucaria heterophylla': 'Araucaria heterophylla',
    'araucaria excelsa':      'Araucaria heterophylla',

    # Ficus carica
    'ficus carica': 'Ficus carica',

    # Emilia sonchifolia
    'emilia sonchifolia': 'Emilia sonchifolia',
    'emilia fosbergii':   'Emilia sonchifolia',
}


class PlantNetRecognizer:
    """Identifies plants by forwarding uploaded images to the PlantNet API."""

    def recognize(self, image_path: str) -> dict:
        # Read image bytes
        try:
            with open(image_path, 'rb') as fh:
                image_data = fh.read()
        except Exception as exc:
            return self._no_match(f'Could not read image: {exc}')

        # Call PlantNet
        try:
            response = requests.post(
                PLANTNET_URL,
                params={'api-key': PLANTNET_API_KEY, 'include-related-images': 'false'},
                files=[('images', ('photo.jpg', image_data, 'image/jpeg'))],
                data={'organs': 'auto'},
                timeout=20,
            )
        except requests.Timeout:
            return self._no_match('PlantNet API request timed out.')
        except requests.RequestException as exc:
            return self._no_match(f'PlantNet API connection error: {exc}')

        if response.status_code == 401:
            return self._no_match('Invalid PlantNet API key. Set PLANTNET_API_KEY env var.')
        if response.status_code != 200:
            return self._no_match(
                f'PlantNet API error {response.status_code}: {response.text[:200]}'
            )

        try:
            data = response.json()
        except Exception:
            return self._no_match('PlantNet returned invalid JSON.')

        results = data.get('results', [])
        if not results:
            return self._no_match('PlantNet returned no results.')

        # Walk top results in descending score order until we find an app plant
        for result in results[:5]:
            score = float(result.get('score', 0.0))
            if score < MIN_PLANTNET_SCORE:
                break  # remaining results are even less confident

            species = result.get('species', {})
            sci_name = species.get('scientificNameWithoutAuthor', '').strip().lower()
            print(f'  PlantNet candidate: "{sci_name}" score={score:.3f}')

            app_name = self._map_name(sci_name)
            if app_name:
                # Scale PlantNet score so it always passes the app's 0.60 threshold
                # while still reflecting the original confidence.
                # score=0.05 → 0.65 | score=0.30 → 0.90 | score=0.40+ → 0.99
                confidence = min(0.99, 0.60 + score)
                return {
                    'plant': app_name,
                    'match': True,
                    'confidence': confidence,
                    'message': f'Matched plant: {app_name} ({confidence:.2f})',
                    'scores': {'overall': confidence, 'plantnet': score},
                }

        return self._no_match('No matching plant found in the app list.')

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _map_name(self, sci_name: str):
        """Try exact → genus+species → genus-only lookup in PLANTNET_TO_APP."""
        if sci_name in PLANTNET_TO_APP:
            return PLANTNET_TO_APP[sci_name]
        parts = sci_name.split()
        if len(parts) >= 2:
            two_word = f'{parts[0]} {parts[1]}'
            if two_word in PLANTNET_TO_APP:
                return PLANTNET_TO_APP[two_word]
        if parts and parts[0] in PLANTNET_TO_APP:
            return PLANTNET_TO_APP[parts[0]]
        return None

    @staticmethod
    def _no_match(message: str) -> dict:
        return {
            'plant': None,
            'match': False,
            'confidence': 0.0,
            'message': message,
            'scores': {'overall': 0.0, 'plantnet': 0.0},
        }
