import requests

API_KEY = '2b10VnSoWTSvYhKEWJHLbQRofu'
URL = 'https://my-api.plantnet.org/v2/identify/all'

# Use a small test image from the plant_reference folder
import os, glob
ref_dir = os.path.join(os.path.dirname(__file__), 'plant_reference')
images = glob.glob(os.path.join(ref_dir, '*.jpg')) + glob.glob(os.path.join(ref_dir, '*.png'))

if not images:
    print('❌ No reference images found to test with.')
    exit(1)

test_image = images[0]
print(f'Testing with: {os.path.basename(test_image)}')

with open(test_image, 'rb') as f:
    image_data = f.read()

try:
    response = requests.post(
        URL,
        params={'api-key': API_KEY, 'include-related-images': 'false'},
        files=[('images', ('photo.jpg', image_data, 'image/jpeg'))],
        data={'organs': 'auto'},
        timeout=20,
    )
    print(f'Status: {response.status_code}')
    if response.status_code == 200:
        data = response.json()
        results = data.get('results', [])
        print(f'✅ API works! Top results:')
        for r in results[:3]:
            sci = r['species']['scientificNameWithoutAuthor']
            score = r['score']
            print(f'   {sci} — {score:.3f}')
    elif response.status_code == 401:
        print('❌ Invalid API key.')
    else:
        print(f'❌ Error: {response.text[:200]}')
except Exception as e:
    print(f'❌ Connection error: {e}')
