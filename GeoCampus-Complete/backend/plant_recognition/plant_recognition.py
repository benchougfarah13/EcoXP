import os
import pickle
import cv2
from glob import glob
from typing import Optional, Tuple

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
REFERENCE_DIR = os.path.join(BASE_DIR, 'plant_reference')
MODEL_DIR = os.path.join(BASE_DIR, 'models')
MODEL_PATH = os.path.join(MODEL_DIR, 'plant_database.pkl')

# ORB matcher settings
ORB_FEATURES = 500
MATCH_DISTANCE_THRESHOLD = 60
SCORE_THRESHOLD = float(os.getenv('PLANT_SCORE_THRESHOLD', '0.40'))


def ensure_model_folder():
    os.makedirs(MODEL_DIR, exist_ok=True)


def normalize_plant_name_from_filename(file_name: str) -> str:
    """
    Convert reference image filenames into a plant label.

    Supports:
      - bougainvillea.jpg                      -> "bougainvillea"
      - yellow_oleander.jpg                    -> "yellow oleander"
      - olea_europaea_1.jpg                    -> "olea europaea"
      - Euryops pectinatus 'Viridis'.jpg       -> "euryops pectinatus viridis"
      - Ficus carica L..jpg                    -> "ficus carical"
      - Lantana camara 'Mutabilis'.JPG         -> "lantana camara mutabilis"
      - Plumbago auriculata Lam.jpg            -> "plumbago auriculata lam"
    """
    base = os.path.splitext(file_name)[0]
    # Strip trailing dots (e.g. "Ficus carica L." from "Ficus carica L..jpg")
    base = base.rstrip('.')
    # Remove apostrophes/quotes (e.g. cultivar names like 'Viridis')
    base = base.replace("'", '').replace('"', '')
    # Replace underscores and hyphens with spaces
    base = base.replace('_', ' ').replace('-', ' ')
    # Split, drop trailing numeric suffixes, rejoin
    parts = [p for p in base.split() if p]
    if parts and parts[-1].isdigit():
        parts = parts[:-1]
    return ' '.join(parts).strip().lower()


def load_image(path: str):
    image = cv2.imread(path)
    if image is None:
        return None
    return image


def extract_histogram(image):
    # Resize to a fixed size so phone photos and reference images are compared
    # at the same scale — prevents resolution mismatch from skewing scores.
    image = cv2.resize(image, (640, 480))
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    # Mask out background pixels: ignore anything too gray, too dark, or
    # too washed-out. Only score on pixels that carry actual plant color.
    # H: all hues | S >= 40 (colorful) | V: 40–235 (not pure black/white)
    mask = cv2.inRange(hsv, (0, 40, 40), (180, 255, 235))
    hist = cv2.calcHist([hsv], [0, 1], mask, [50, 60], [0, 180, 0, 256])
    cv2.normalize(hist, hist)
    return hist.flatten()


def extract_orb_descriptors(image):
    # Resize to standard size so ORB keypoints are at comparable scales
    # regardless of whether the image came from a phone or reference folder.
    image = cv2.resize(image, (640, 480))
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    orb = cv2.ORB_create(nfeatures=ORB_FEATURES)
    _, descriptors = orb.detectAndCompute(gray, None)
    return descriptors


def augment_image(image):
    """
    Generate 8 augmented variants from a single reference image:
      - Original
      - Rotated 90°, 180°, 270°
      - Horizontal flip
      - Vertical flip
      - Brighter (+40% exposure)
      - Darker  (-40% exposure)

    This replaces the need for multiple photos per plant species.
    16 reference images → 128 database entries.
    """
    variants = [image]

    # Rotations
    variants.append(cv2.rotate(image, cv2.ROTATE_90_CLOCKWISE))
    variants.append(cv2.rotate(image, cv2.ROTATE_180))
    variants.append(cv2.rotate(image, cv2.ROTATE_90_COUNTERCLOCKWISE))

    # Flips
    variants.append(cv2.flip(image, 1))   # horizontal
    variants.append(cv2.flip(image, 0))   # vertical

    # Brightness variants (saturating arithmetic — no overflow)
    variants.append(cv2.convertScaleAbs(image, alpha=1.4, beta=0))   # brighter
    variants.append(cv2.convertScaleAbs(image, alpha=0.6, beta=0))   # darker

    return variants


def build_database():
    ensure_model_folder()
    plant_db = {}
    image_files = []

    for pattern in ('*.jpg', '*.jpeg', '*.png', '*.bmp'):
        image_files.extend(glob(os.path.join(REFERENCE_DIR, pattern)))
        image_files.extend(glob(os.path.join(REFERENCE_DIR, pattern.upper())))

    if not image_files:
        print('⚠️ No reference images found in', REFERENCE_DIR)
        return {}

    for image_path in image_files:
        file_name = os.path.basename(image_path)
        plant_name = normalize_plant_name_from_filename(file_name)
        image = load_image(image_path)
        if image is None:
            continue

        for variant in augment_image(image):
            descriptors = extract_orb_descriptors(variant)
            histogram = extract_histogram(variant)
            plant_db.setdefault(plant_name, []).append({
                'path': image_path,
                'descriptors': descriptors,
                'histogram': histogram,
            })

    with open(MODEL_PATH, 'wb') as f:
        pickle.dump(plant_db, f)

    total_variants = sum(len(v) for v in plant_db.values())
    print(f'✅ Plant database built with {len(plant_db)} plants ({total_variants} variants total)')
    return plant_db


def _latest_reference_mtime() -> Optional[float]:
    latest = None
    for pattern in ('*.jpg', '*.jpeg', '*.png', '*.bmp'):
        for path in glob(os.path.join(REFERENCE_DIR, pattern)) + glob(os.path.join(REFERENCE_DIR, pattern.upper())):
            try:
                mtime = os.path.getmtime(path)
            except OSError:
                continue
            latest = mtime if latest is None else max(latest, mtime)
    return latest


def database_is_stale() -> bool:
    if not os.path.exists(MODEL_PATH):
        return True
    ref_mtime = _latest_reference_mtime()
    if ref_mtime is None:
        return False
    try:
        model_mtime = os.path.getmtime(MODEL_PATH)
    except OSError:
        return True
    return ref_mtime > model_mtime


def load_database():
    if not os.path.exists(MODEL_PATH) or database_is_stale():
        return build_database()

    try:
        with open(MODEL_PATH, 'rb') as f:
            return pickle.load(f)
    except Exception as e:
        print('⚠️ Failed to load plant database:', e)
        return build_database()


class PlantRecognizer:
    def __init__(self):
        self.database = load_database()
        self.bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)

    def recognize(self, image_path: str):
        if database_is_stale():
            self.database = build_database()

        image = load_image(image_path)
        if image is None:
            return {
                'plant': None,
                'match': False,
                'confidence': 0.0,
                'message': 'Could not read uploaded image.',
                'scores': {'overall': 0.0, 'hist': 0.0, 'orb': 0.0},
            }

        descriptors = extract_orb_descriptors(image)
        histogram = extract_histogram(image)

        best_score = 0.0
        best_plant = None
        best_hist = 0.0
        best_orb = 0.0

        for plant_name, entries in self.database.items():
            for entry in entries:
                score, hist_score, orb_score = self._compare(entry, descriptors, histogram)
                if score > best_score:
                    best_score = score
                    best_plant = plant_name
                    best_hist = hist_score
                    best_orb = orb_score

        if best_plant is None or best_score < SCORE_THRESHOLD:
            return {
                'plant': None,
                'match': False,
                'confidence': float(best_score),
                'message': 'No matching plant found.',
                'scores': {'overall': float(best_score), 'hist': float(best_hist), 'orb': float(best_orb)},
            }

        return {
            'plant': best_plant,
            'match': True,
            'confidence': float(best_score),
            'message': f'Matched plant: {best_plant} ({best_score:.2f})',
            'scores': {'overall': float(best_score), 'hist': float(best_hist), 'orb': float(best_orb)},
        }

    def _compare(self, entry, descriptors, histogram) -> Tuple[float, float, float]:
        hist_score = 0.0
        if entry.get('histogram') is not None and histogram is not None:
            hist_score = 1.0 - cv2.compareHist(entry['histogram'], histogram, cv2.HISTCMP_BHATTACHARYYA)
            hist_score = max(0.0, min(hist_score, 1.0))

        orb_score = 0.0
        if entry.get('descriptors') is not None and descriptors is not None:
            try:
                matches = self.bf.match(descriptors, entry['descriptors'])
                good = [m for m in matches if m.distance < MATCH_DISTANCE_THRESHOLD]
                orb_score = min(1.0, len(good) / 15.0)
            except Exception:
                orb_score = 0.0

        # Histogram carries most of the weight — plant colors are distinctive
        # and reliable across lighting changes; ORB is a weak secondary signal.
        overall = 0.75 * hist_score + 0.25 * orb_score
        return overall, hist_score, orb_score
