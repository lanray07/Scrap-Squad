"""Run Android checks with one working directory and preserve failure diagnostics."""
from pathlib import Path
import subprocess
import time

android = Path(__file__).resolve().parents[1]
reports = android / 'reports'
(reports / 'screenshots').mkdir(parents=True, exist_ok=True)
try:
    subprocess.run(['./gradlew', ':app:connectedDebugAndroidTest', '--console=plain'], cwd=android, check=True)
    subprocess.run(['adb', 'pull', '/sdcard/Download/scrap-squad-battle.png', str(reports / 'screenshots')], check=True)
    subprocess.run(['adb', 'pull', '/sdcard/Download/scrap-squad-ui-upgrade-picker.png', str(reports / 'screenshots')], check=True)
    subprocess.run(['adb', 'pull', '/sdcard/Download/scrap-squad-ui-information-dialog.png', str(reports / 'screenshots')], check=True)
    for name in ('ui-fusion-reveal', 'ui-battle-result', 'ui-blueprint-categories'):
        subprocess.run(['adb', 'pull', f'/sdcard/Download/scrap-squad-{name}.png', str(reports / 'screenshots')], check=True)
    for name in ('01-city', '02-squad', '03-workshop', '04-blueprints', '05-battle-lobby', '06-shop', '07-ronin-preview', '08-journal', '09-run-card', '10-boss-battle'):
        subprocess.run(['adb', 'pull', f'/sdcard/Download/scrap-squad-{name}.png', str(reports / 'screenshots')], check=True)
    (reports / 'store-assets').mkdir(exist_ok=True)
    for name in ('icon-114', 'icon-512', 'promo'):
        subprocess.run(['adb', 'pull', f'/sdcard/Download/scrap-squad-{name}.png', str(reports / 'store-assets')], check=True)
    subprocess.run(['python3', str(android / 'tools/validate_store.py'), '--screenshots', str(reports / 'screenshots'), '--assets', str(reports / 'store-assets')], check=True)
    # The UI review APK has its own package/save namespace, avoiding debug-key
    # update conflicts with the tester's installed game. Verify co-installation.
    for variant in ('debug', 'uiReview'):
        subprocess.run(['adb', 'install', '-r', str(android / f'app/build/outputs/apk/{variant}/app-{variant}.apk')], check=True)
    for package in ('com.scrapsquad.fire', 'com.scrapsquad.fire.uireview'):
        installed = subprocess.run(['adb', 'shell', 'pm', 'path', package], capture_output=True, text=True, check=True)
        assert 'package:' in installed.stdout, f'Missing co-installed app: {package}'
    launched = subprocess.run(['adb', 'shell', 'am', 'start', '-W', '-n', 'com.scrapsquad.fire.uireview/com.scrapsquad.fire.MainActivity'], capture_output=True, text=True, check=True)
    assert 'Status: ok' in launched.stdout, launched.stdout + launched.stderr
    time.sleep(2)
    running = subprocess.run(['adb', 'shell', 'pidof', 'com.scrapsquad.fire.uireview'], capture_output=True, text=True, check=True)
    assert running.stdout.strip(), 'UI review app did not stay running'
    startup = subprocess.run(['adb', 'logcat', '-d', f'--pid={running.stdout.strip()}', '-s', 'ScrapUI:E', 'AndroidRuntime:E'], capture_output=True, text=True, check=True)
    assert 'Native menu initialization failed' not in startup.stdout and 'FATAL EXCEPTION' not in startup.stdout, startup.stdout
    print('UI review launch and coexistence with original package passed.')
finally:
    with (reports / 'android-logcat.log').open('w', encoding='utf-8') as log:
        subprocess.run(['adb', 'logcat', '-d'], stdout=log, stderr=subprocess.STDOUT)
    with (reports / 'parity-throughput.log').open('w', encoding='utf-8') as log:
        subprocess.run(['adb', 'logcat', '-d', '-s', 'ScrapParity:I'], stdout=log, stderr=subprocess.STDOUT)
    with (reports / 'render-metrics.log').open('w', encoding='utf-8') as log:
        subprocess.run(['adb', 'logcat', '-d', '-s', 'ScrapRender:I'], stdout=log, stderr=subprocess.STDOUT)
