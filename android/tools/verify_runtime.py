"""Run Android checks with one working directory and preserve failure diagnostics."""
from pathlib import Path
import subprocess

android = Path(__file__).resolve().parents[1]
reports = android / 'reports'
(reports / 'screenshots').mkdir(parents=True, exist_ok=True)
try:
    subprocess.run(['./gradlew', ':app:connectedDebugAndroidTest', '--console=plain'], cwd=android, check=True)
    subprocess.run(['adb', 'pull', '/data/local/tmp/scrap-squad-battle.png', str(reports / 'screenshots')], check=True)
finally:
    with (reports / 'android-logcat.log').open('w', encoding='utf-8') as log:
        subprocess.run(['adb', 'logcat', '-d'], stdout=log, stderr=subprocess.STDOUT)
    with (reports / 'parity-throughput.log').open('w', encoding='utf-8') as log:
        subprocess.run(['adb', 'logcat', '-d', '-s', 'ScrapParity:I'], stdout=log, stderr=subprocess.STDOUT)
