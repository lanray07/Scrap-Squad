"""Compile the original game rules; write only inside android/.

The Android copy of BattleEngine is mutex-confined instead of MainActor-confined.
Only that declaration changes. All simulation expressions remain byte-identical.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ANDROID = Path(__file__).resolve().parents[1]
ROOT = ANDROID.parent


def run(command):
    print(' '.join(map(str, command)), flush=True)
    subprocess.run(list(map(str, command)), check=True)


def sources(original=False):
    files = sorted((ROOT / 'Sources/ScrapCore').glob('*.swift'))
    if original:
        return files
    stage = ANDROID / 'native/build/generated'
    stage.mkdir(parents=True, exist_ok=True)
    battle = ROOT / 'Sources/ScrapCore/Battle.swift'
    text = battle.read_text(encoding='utf-8')
    marker = '@MainActor public final class BattleEngine'
    assert text.count(marker) == 1, 'Review actor adaptation after upstream changes'
    destination = stage / 'Battle.swift'
    destination.write_text(text.replace(marker, 'public final class BattleEngine'), encoding='utf-8')
    hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
    (stage / 'source-hashes.json').write_text(json.dumps(hashes, indent=2))
    return [destination if p == battle else p for p in files]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--abi', choices=['arm64-v8a', 'x86_64'], default='arm64-v8a')
    parser.add_argument('--oracle', action='store_true')
    parser.add_argument('--jni-only', action='store_true', help='Relink only the UTF-8 JNI adapter after a bridge-only edit')
    args = parser.parse_args()
    build = ANDROID / 'native/build'
    build.mkdir(parents=True, exist_ok=True)
    swiftc = os.environ.get('SWIFTC') or shutil.which('swiftc')
    support = [ANDROID / 'native/BundleSupport.swift', ANDROID / 'native/Session.swift']
    if args.oracle:
        output = build / ('oracle.exe' if os.name == 'nt' else 'oracle')
        run([swiftc, '-swift-version', '5', '-D', 'ORIGINAL_CORE', '-parse-as-library', *sources(True), *support, ANDROID / 'native/Oracle.swift', '-o', output])
        return
    sdk = Path(os.environ.get('SWIFT_ANDROID_SDK', str(Path.home() / 'AppData/Local/Programs/Swift/Platforms/6.3.1/Android.platform/Developer/SDKs/Android.sdk')))
    ndk = Path(os.environ.get('ANDROID_NDK_HOME', str(Path.home() / 'AppData/Local/Android/Sdk/ndk/28.2.13676358')))
    host = 'windows-x86_64' if os.name == 'nt' else 'linux-x86_64'
    tools = ndk / 'toolchains/llvm/prebuilt' / host / 'bin'
    sysroot = tools.parent / 'sysroot'
    arch = 'aarch64' if args.abi == 'arm64-v8a' else 'x86_64'
    triple = arch + '-linux-android'
    destination = ANDROID / 'app/src/main/jniLibs' / args.abi
    destination.mkdir(parents=True, exist_ok=True)
    output = destination / 'libscrapcore.so'
    resource = sdk / 'usr/lib/swift'
    if not (resource / 'android' / arch / 'swiftrt.o').exists():
        search = sdk if sdk.exists() else Path.home()
        # The host Swift toolchain also has x86_64/swiftrt.o. Select only an
        # Android runtime; otherwise Linux builds silently choose host modules.
        runtime = next(p for p in search.rglob('swiftrt.o')
                       if p.parent.name == arch and p.parent.parent.name == 'android'
                       and 'swift_static' not in str(p))
        resource = runtime.parent.parent.parent
        sdk = resource.parent.parent.parent
    libraries = resource / 'android' / arch
    if not (libraries / 'libswiftCore.so').exists():
        libraries = resource / 'android'
    object_file = build / (arch + '.o')
    if not args.jni_only:
        run([swiftc, '-swift-version', '5', '-O', '-whole-module-optimization', '-parse-as-library', '-emit-object', '-module-name', 'ScrapAndroid', '-target', arch + '-unknown-linux-android28',
         '-sdk', sysroot, '-resource-dir', resource, '-tools-directory', tools, '-I', sdk / 'usr/include',
         '-Xcc', '--sysroot=' + str(sysroot), '-Xcc', '-isystem', '-Xcc', next((tools.parent / 'lib/clang').glob('*/include')),
         *sources(), *support, '-o', object_file])
    compiler = tools / ('clang++.exe' if os.name == 'nt' else 'clang++')
    autolink = build / (arch + '.autolink')
    extractor = Path(swiftc).with_name('swift-autolink-extract.exe' if os.name == 'nt' else 'swift-autolink-extract')
    if not args.jni_only:
        run([extractor, object_file, '-o', autolink])
        run([compiler, '--target=' + triple + '28', '--sysroot=' + str(sysroot), '-shared', object_file,
         resource / 'android' / arch / 'swiftrt.o', '-L' + str(libraries),
         '@' + str(autolink), '-Wl,-z,max-page-size=16384', '-Wl,-soname,libscrapcore.so', '-o', output])
    run([compiler, '--target=' + triple + '28', '--sysroot=' + str(sysroot), '-shared', '-fPIC', '-std=c++17',
         '-Wl,-z,max-page-size=16384', ANDROID / 'native/jni.cpp', '-L' + str(destination), '-lscrapcore', '-o', destination / 'libscrapjni.so'])
    for library in libraries.glob('*.so'):
        shutil.copy2(library, destination / library.name)
    shutil.copy2(sysroot / 'usr/lib' / triple / 'libc++_shared.so', destination / 'libc++_shared.so')
    print('Native libraries prepared:', destination)


if __name__ == '__main__':
    main()
