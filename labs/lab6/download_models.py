import os
import sys
import urllib.request
import time

BASE_URL = "http://10.249.14.10:3011/lab6/"
MODELS = {
    "stories15M.bin": 60816028,
    "stories42M.bin": 167020572,
    "stories110M.bin": 438381596,
}

DIR = os.path.dirname(os.path.abspath(__file__))

def download(model_name):
    if model_name not in MODELS:
        print(f"Unknown model: {model_name}. Available: {list(MODELS.keys())}")
        return False
    dst = os.path.join(DIR, model_name)
    expected_size = MODELS[model_name]
    if os.path.exists(dst) and os.path.getsize(dst) == expected_size:
        print(f"[{model_name}] already downloaded ({expected_size} bytes).")
        return True

    url = BASE_URL + model_name
    print(f"Downloading {model_name} ({expected_size / 1024 / 1024:.1f} MB) from {url} ...")
    start = time.time()
    try:
        def reporthook(block_num, block_size, total_size):
            downloaded = block_num * block_size
            if total_size > 0:
                percent = min(100.0, downloaded * 100.0 / total_size)
                speed = downloaded / max(1e-5, time.time() - start) / 1024 / 1024
                sys.stdout.write(f"\r  [{percent:5.1f}%] {downloaded / 1024 / 1024:6.1f} / {total_size / 1024 / 1024:6.1f} MB ({speed:4.2f} MB/s)")
                sys.stdout.flush()
        urllib.request.urlretrieve(url, dst, reporthook=reporthook)
        print(f"\n  Done in {time.time() - start:.1f}s.")
        return True
    except Exception as e:
        print(f"\n  Download failed: {e}")
        if os.path.exists(dst):
            os.remove(dst)
        return False

def main():
    targets = sys.argv[1:] if len(sys.argv) > 1 else list(MODELS.keys())
    for t in targets:
        download(t)

if __name__ == "__main__":
    main()
