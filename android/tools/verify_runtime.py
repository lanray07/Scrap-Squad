"""Run Android checks with one working directory and preserve failure diagnostics."""
from pathlib import Path
import subprocess

android = Path(__file__).resolve().parents[1]
reports = android / 'reports'
(reports / 'screenshots').mkdir(parents=True, exist_ok=True)
try:
    subprocess.run(['./gradlew', ':app:connectedDebugAndroidTest', '--console=plain'], cwd=android, check=True)
    subprocess.run(['adb', 'pull', '/sdcard/Download/scrap-squad-battle.png', str(reports / 'screenshots')], check=True)
    for name in ('01-city', '02-squad', '03-workshop', '04-blueprints', '05-battle-lobby', '06-shop', '07-ronin-preview', '08-journal', '09-run-card'):
        subprocess.run(['adb', 'pull', f'/sdcard/Download/scrap-squad-{name}.png', str(reports / 'screenshots')], check=True)
    subprocess.run(['python3', str(android / 'tools/validate_store.py'), '--screenshots', str(reports / 'screenshots')], check=True)
finally:
    with (reports / 'android-logcat.log').open('w', encoding='utf-8') as log:
        subprocess.run(['adb', 'logcat', '-d'], stdout=log, stderr=subprocess.STDOUT)
    with (reports / 'parity-throughput.log').open('w', encoding='utf-8') as log:
        subprocess.run(['adb', 'logcat', '-d', '-s', 'ScrapParity:I'], stdout=log, stderr=subprocess.STDOUT)
    with (reports / 'render-metrics.log').open('w', encoding='utf-8') as log:
        subprocess.run(['adb', 'logcat', '-d', '-s', 'ScrapRender:I'], stdout=log, stderr=subprocess.STDOUT)
