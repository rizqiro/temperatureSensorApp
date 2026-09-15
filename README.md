# Draft Sensor App

Connects to each ESP32 draft-sensor node's own Wi-Fi hotspot, downloads its
CSV log, saves it on the phone, and shares it (e.g. to WhatsApp).

## Setup

1. Install Flutter (https://docs.flutter.dev/get-started/install) if you
   haven't already.
2. Create a fresh project, then drop these files in, overwriting the
   generated ones:
   ```
   flutter create draft_sensor_app
   cd draft_sensor_app
   # copy pubspec.yaml, lib/, and this README from this bundle into place
   flutter pub get
   ```
3. **Required manifest edits** — without these, the app can talk to the
   ESP32 over plain HTTP on Android/iOS but the OS will silently block it:

   **Android** — open `android/app/src/main/AndroidManifest.xml` and add
   `android:usesCleartextTraffic="true"` to the `<application>` tag:
   ```xml
   <application
       android:label="draft_sensor_app"
       android:usesCleartextTraffic="true"
       ...>
   ```

   **iOS** — open `ios/Runner/Info.plist` and add an App Transport Security
   exception so it can reach the node's local IP over HTTP:
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsArbitraryLoads</key>
       <true/>
   </dict>
   <key>NSLocalNetworkUsageDescription</key>
   <string>Used to fetch sensor logs from ESP32 nodes on your Wi-Fi.</string>
   ```

4. Run it: `flutter run`

## Using it

1. Tap **+** and add each sensor node: give it a position name (e.g.
   "Window"), and the `AP_SSID` / `AP_PASS` you set in the ESP32 sketch for
   that node.
2. Open a node. You'll see connect instructions — switch your phone's Wi-Fi
   to that node's hotspot, then tap **Connect**.
3. Once connected, the same screen turns into a dashboard: current, max, and
   min temperature (with the time the max and min happened), a timeframe
   picker (2h/4h/8h/24h/All), and a trend chart for whichever timeframe is
   selected.
4. Tap **Export CSV** to save just the readings in the current timeframe as
   a file on your phone, then **Share to WhatsApp** to send it through your
   phone's normal share sheet.
5. Use the refresh icon in the app bar to pull fresh data without
   re-entering the connect flow, and the overflow menu's **Clear log on
   device** afterwards so the SD card doesn't fill up — only do this once
   you've confirmed your export succeeded.
6. The **history** icon on the home screen shows every CSV you've ever
   exported, from any node and any timeframe, for re-sharing later.

## Notes

- Your phone can only be connected to one node's Wi-Fi at a time — that's
  why the app is designed to visit nodes one by one rather than all at once.
- WhatsApp needs to be installed for it to show up as a share option.
- If "Fetch & save data" fails, double check your phone is actually
  connected to that node's Wi-Fi network (not your home Wi-Fi or mobile
  data) and that the node's IP matches what's in the app (default
  `192.168.4.1`).
