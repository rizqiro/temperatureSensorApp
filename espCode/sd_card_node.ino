/*
  Convection draft sensor node — standalone SD card logger
  Type K thermocouple (via MAX6675) + SD card, no Wi-Fi router or server needed.

  What it does:
  - Reads a Type K thermocouple through a MAX6675 board, tracks the
    temperature swing per WINDOW_MS, and appends a row to a CSV log file
    on the SD card
  - Broadcasts its own Wi-Fi access point (AP_SSID / AP_PASS below) so a
    phone can connect DIRECTLY to this node — no internet needed
  - Runs a small web server so the companion Flutter app can:
      GET  /status     -> current reading + free SD space (JSON)
      GET  /list        -> list of log files on the SD card (JSON)
      GET  /download?file=/log.csv -> streams the CSV file
      POST /settime     -> phone sends {"epoch": <unix seconds>} to timestamp
                            future readings with real dates/times
      POST /clear       -> erases the log file (call this after you've
                            confirmed the data was saved on the phone)

  Requires the "MAX6675" Arduino library (Library Manager -> search
  "MAX6675" -> install the one exposing MAX6675(clk, cs, so) with a
  readCelsius() method — this interface is the de facto standard shared
  by the common MAX6675 libraries).

  Flash this same file to every node — just change NODE_ID, AP_SSID and
  (optionally) AP_PASS for each one so they don't collide and so you can
  tell them apart in the phone's Wi-Fi list.
*/

#include <WiFi.h>
#include <WebServer.h>
#include <SPI.h>
#include <SD.h>
#include "max6675.h"

// ---------------- CONFIG: EDIT PER NODE ----------------
const char* NODE_ID = "window_1";               // window_1, door_1, reference_1...
const char* AP_SSID = "DraftSensor-Window1";     // shown in the phone's Wi-Fi list
const char* AP_PASS = "draft1234";               // must be 8+ characters
// ---------------------------------------------------------

// --- Type K thermocouple via MAX6675 (separate pins from the SD card's SPI bus) ---
const int THERMO_CLK_PIN = 25;
const int THERMO_CS_PIN  = 26;
const int THERMO_DO_PIN  = 27;   // SO / MISO on the MAX6675 board
MAX6675 thermocouple(THERMO_CLK_PIN, THERMO_CS_PIN, THERMO_DO_PIN);

// --- SD card (VSPI default pins on most ESP32 dev boards) ---
const int SD_CS_PIN = 5;   // MOSI=23, MISO=19, SCK=18 are the ESP32 defaults

// --- Detection / logging settings ---
const float DELTA_THRESHOLD = 1.0;    // deg C swing that counts as a "draft event"
const unsigned long WINDOW_MS = 5000;  // evaluate + log every 5s
const unsigned long SAMPLE_INTERVAL_MS = 300;  // MAX6675 needs ~220ms between conversions

const char* LOG_FILE = "/log.csv";

WebServer server(80);

// windowMin/windowMax track the temperature range seen since the last
// log line was written; they get reset to the latest reading each time
// a row is logged (see loop() below).
float windowMin = 1000, windowMax = -1000;
float lastTemp = NAN;
unsigned long lastSample = 0;
unsigned long lastLog = 0;
long timeOffsetSec = 0;        // set via /settime once the phone connects
unsigned long bootMillis = 0;

// Reads the thermocouple, falling back to the last good value if this
// particular read failed (MAX6675 occasionally returns NaN).
float readTemperatureC() {
  float t = thermocouple.readCelsius();
  if (isnan(t)) return lastTemp;  // guard against a bad read; keep last good value
  return t;
}

// Real-world unix time for the current moment, derived from the phone's
// /settime call plus however long the board has been running since.
// Before /settime is ever called this is just seconds-since-boot.
unsigned long currentEpoch() {
  return timeOffsetSec + (millis() - bootMillis) / 1000;
}

// Creates the CSV file with a header row if it doesn't already exist,
// so appends later always land in a valid CSV.
void ensureLogHeader() {
  if (!SD.exists(LOG_FILE)) {
    File f = SD.open(LOG_FILE, FILE_WRITE);
    if (f) {
      f.println("epoch,node_id,temperature_c,swing_c,event");
      f.close();
    }
  }
}

// Appends one CSV row for the current window: epoch,node_id,temp,swing,event.
void logReading(float temp, float delta, bool event) {
  File f = SD.open(LOG_FILE, FILE_APPEND);
  if (!f) {
    Serial.println("Failed to open log file for append");
    return;
  }
  f.printf("%lu,%s,%.2f,%.2f,%d\n", currentEpoch(), NODE_ID, temp, delta, event ? 1 : 0);
  f.close();
}

// ---------------- Web server handlers ----------------

// GET /status - current reading + SD free space, as JSON. Also serves
// as the app's "is this node reachable?" ping.
void handleStatus() {
  String json = "{";
  json += "\"node_id\":\"" + String(NODE_ID) + "\",";
  json += "\"temperature\":" + String(lastTemp, 2) + ",";
  json += "\"uptime_s\":" + String((millis() - bootMillis) / 1000) + ",";
  uint64_t freeBytes = SD.totalBytes() - SD.usedBytes();
  json += "\"sd_free_kb\":" + String((unsigned long)(freeBytes / 1024));
  json += "}";
  server.send(200, "application/json", json);
}

// GET /list - names of log files on the SD card, as a JSON array.
// Only ever contains LOG_FILE today, but the app treats it as a list
// so a future version could add rotated/archived log files.
void handleList() {
  String json = "[\"" + String(LOG_FILE) + "\"]";
  server.send(200, "application/json", json);
}

// GET /download?file=<path> - streams a log file's raw CSV bytes.
void handleDownload() {
  if (!server.hasArg("file")) {
    server.send(400, "text/plain", "missing file argument");
    return;
  }
  String path = server.arg("file");
  if (!SD.exists(path)) {
    server.send(404, "text/plain", "file not found");
    return;
  }
  File f = SD.open(path, FILE_READ);
  server.streamFile(f, "text/csv");
  f.close();
}

// POST /settime - body is {"epoch": <unix seconds>} from the phone.
// The board has no real-time clock, so this is how it learns the actual
// date/time; parsing is a deliberately minimal split on the first ':'
// rather than a full JSON parser, since the body shape is fixed.
void handleSetTime() {
  if (!server.hasArg("plain")) {
    server.send(400, "text/plain", "missing body");
    return;
  }
  String body = server.arg("plain");
  int colon = body.indexOf(':');
  if (colon == -1) {
    server.send(400, "text/plain", "expected {\"epoch\": 1234567890}");
    return;
  }
  long epoch = body.substring(colon + 1).toInt();
  timeOffsetSec = epoch;
  bootMillis = millis();  // resets the reference point currentEpoch() counts up from
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

// POST /clear - erases the log file and immediately recreates it with a
// fresh header, ready for new rows.
void handleClear() {
  SD.remove(LOG_FILE);
  ensureLogHeader();
  server.send(200, "application/json", "{\"status\":\"cleared\"}");
}

// Runs once at boot: brings up the SD card, starts the Wi-Fi access
// point, and registers the HTTP route handlers.
void setup() {
  Serial.begin(115200);
  bootMillis = millis();

  if (!SD.begin(SD_CS_PIN)) {
    Serial.println("SD card init failed! Check wiring/card.");
  } else {
    ensureLogHeader();
    Serial.println("SD card ready.");
  }

  // Broadcasts its own network rather than joining an existing router,
  // so the phone can talk to it with zero internet/router setup.
  WiFi.softAP(AP_SSID, AP_PASS);
  Serial.print("Access point started. IP: ");
  Serial.println(WiFi.softAPIP());   // normally 192.168.4.1

  server.on("/status", handleStatus);
  server.on("/list", handleList);
  server.on("/download", handleDownload);
  server.on("/settime", HTTP_POST, handleSetTime);
  server.on("/clear", HTTP_POST, handleClear);
  server.begin();
}

// Runs continuously: services incoming HTTP requests, samples the
// thermocouple on SAMPLE_INTERVAL_MS, and every WINDOW_MS collapses the
// samples taken so far into a single logged CSV row.
void loop() {
  server.handleClient();
  unsigned long now = millis();

  // Sample the thermocouple periodically (MAX6675 needs time between
  // conversions) and track the min/max seen within the current window.
  if (now - lastSample >= SAMPLE_INTERVAL_MS) {
    lastSample = now;
    float t = readTemperatureC();
    lastTemp = t;
    if (t < windowMin) windowMin = t;
    if (t > windowMax) windowMax = t;
  }

  // Once per window, log the latest temperature and how much it swung
  // during the window; a swing past DELTA_THRESHOLD is flagged as a
  // "draft event". Then reset the window bounds for the next interval.
  if (now - lastLog >= WINDOW_MS && !isnan(lastTemp)) {
    lastLog = now;
    float delta = windowMax - windowMin;
    bool event = delta >= DELTA_THRESHOLD;
    logReading(lastTemp, delta, event);
    Serial.printf("Logged: %s temp=%.2fC swing=%.2fC event=%s\n",
                  NODE_ID, lastTemp, delta, event ? "YES" : "no");
    windowMin = lastTemp;
    windowMax = lastTemp;
  }
}
