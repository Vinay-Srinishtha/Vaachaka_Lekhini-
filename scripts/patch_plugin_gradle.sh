#!/usr/bin/env bash
# Re-applies Gradle DSL fixes to Flutter plugin build.gradle files in ~/.pub-cache.
# Run this after `flutter pub get` if the problems-report.html shows deprecated
# "propName value" setter warnings (scheduled for removal in Gradle 10).
set -e

PUB=~/.pub-cache/hosted/pub.dev

patch_file() {
  local f="$1"; shift
  [ -f "$f" ] || { echo "  (skip — not found) $f"; return; }
  for expr in "$@"; do
    sed -i '' "$expr" "$f"
  done
  echo "  patched: $f"
}

echo "=== Patching audioplayers_android ==="
patch_file "$PUB/audioplayers_android-5.2.1/android/build.gradle" \
  "s/^group 'xyz.luan.audioplayers'/group = 'xyz.luan.audioplayers'/" \
  "s/^version '1.0-SNAPSHOT'/version = '1.0-SNAPSHOT'/" \
  "s/^\( *\)compileSdk 35\$/\1compileSdk = 35/" \
  "s/^\( *\)namespace 'xyz.luan.audioplayers'/\1namespace = 'xyz.luan.audioplayers'/"

echo "=== Patching flutter_local_notifications ==="
patch_file "$PUB/flutter_local_notifications-21.0.0/android/build.gradle" \
  "s/^group 'com.dexterous.flutterlocalnotifications'/group = 'com.dexterous.flutterlocalnotifications'/" \
  "s/^version '1.0-SNAPSHOT'/version = '1.0-SNAPSHOT'/" \
  "s/^\( *\)namespace 'com.dexterous.flutterlocalnotifications'/\1namespace = 'com.dexterous.flutterlocalnotifications'/" \
  "s/^\( *\)compileSdk 36\$/\1compileSdk = 36/" \
  "s/^\( *\)coreLibraryDesugaringEnabled true/\1coreLibraryDesugaringEnabled = true/" \
  "s/^\( *\)multiDexEnabled true/\1multiDexEnabled = true/"

echo "=== Patching sqflite_android ==="
patch_file "$PUB/sqflite_android-2.4.3/android/build.gradle" \
  "s/^group 'com.tekartik.sqflite'/group = 'com.tekartik.sqflite'/" \
  "s/^version '1.0-SNAPSHOT'/version = '1.0-SNAPSHOT'/" \
  "s/^\( *\)namespace 'com.tekartik.sqflite'/\1namespace = 'com.tekartik.sqflite'/"

echo "=== Patching connectivity_plus ==="
patch_file "$PUB/connectivity_plus-7.1.1/android/build.gradle" \
  "s/^group 'dev.fluttercommunity.plus.connectivity'/group = 'dev.fluttercommunity.plus.connectivity'/" \
  "s/^version '1.0-SNAPSHOT'/version = '1.0-SNAPSHOT'/" \
  "s/^\( *\)namespace 'dev.fluttercommunity.plus.connectivity'/\1namespace = 'dev.fluttercommunity.plus.connectivity'/" \
  "s/^\( *\)minSdk 21\$/\1minSdk = 21/"

echo "=== Patching printing ==="
patch_file "$PUB/printing-5.14.3/android/build.gradle" \
  's/^group "net.nfet.flutter.printing"/group = "net.nfet.flutter.printing"/' \
  's/^version "1.0"/version = "1.0"/'

echo ""
echo "Done. All deprecated Groovy DSL setters replaced with = assignment syntax."
