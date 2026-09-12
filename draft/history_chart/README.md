# ui/history_chart

Historischer Home-Assistant-Chart für `esphome-modular-lvgl-buttons`.

Das Modul verwendet ausschließlich `!include` + `vars` als öffentliche
Konfiguration. Es legt keine Benutzer-Substitutions an.

## Voraussetzungen

- ESPHome 2026.7+
- Home Assistant mit Recorder
- ESPHome Native API
- In Home Assistant muss für das ESPHome-Gerät erlaubt sein, Home-Assistant-Actions aufzurufen.
- Die verwendeten Sensoren müssen Recorder-Statistiken besitzen.

Home Assistant speichert für Sensoren mit geeigneter `state_class` Kurzzeitstatistiken
in 5-Minuten-Intervallen und langfristige Aggregate stündlich. Genau diese Daten
werden über `recorder.get_statistics` abgefragt.

## Dateien

```text
ui/history_chart/
├── chart.yaml
├── history_chart.h
├── history_chart.cpp
└── README.md
```

## Verwendung

Minimal:

```yaml
temp_history: !include
  file: esphome-modular-lvgl-buttons/ui/history_chart/chart.yaml
  vars:
    uid: temp_history
    temperature_entity: "sensor.cyd1_temperatur_2"
```

Mit bis zu drei Sensoren:

```yaml
climate_history: !include
  file: esphome-modular-lvgl-buttons/ui/history_chart/chart.yaml
  vars:
    uid: climate_history
    title: "Klima"
    temperature_entity: "sensor.cyd1_temperatur_2"
    humidity_entity: "sensor.cyd1_feuchtigkeit_2"
    pressure_entity: "sensor.cyd1_luftdruck_2"
    row: 0
    column: 0
    row_span: 4
    column_span: 4
```

`humidity_entity` und `pressure_entity` sind optional.

## Variablen

| Variable | Pflicht | Beschreibung |
|---|---:|---|
| `uid` | ja | Eindeutiger Präfix |
| `temperature_entity` | ja | Erster HA-Sensor |
| `humidity_entity` | nein | Zweiter HA-Sensor |
| `pressure_entity` | nein | Dritter HA-Sensor |
| `title` | nein | Überschrift, Default `Historie` |
| `row` | nein | Grid-Zeile, Default `0` |
| `column` | nein | Grid-Spalte, Default `0` |
| `row_span` | nein | Zeilen-Spanne, Default `4` |
| `column_span` | nein | Spalten-Spanne, Default `4` |
| `page_id` | nein | LVGL-Seite, Default `main_page` |

## Zeitbereiche

Die Buttons fragen direkt Home Assistant ab:

- `1h` → 5-Minuten-Statistiken
- `6h` → 5-Minuten-Statistiken
- `24h` → 5-Minuten-Statistiken
- `7d` → Stundenstatistiken
- `30d` → Stundenstatistiken

Die Werte werden auf 48 Punkte reduziert, damit die LVGL-Line-Widgets
auch auf kleineren ESP32-Displays überschaubar bleiben.

## Mehrere Sensoren

Jede Kurve wird auf ihre eigene Min/Max-Spanne normiert. Das ist absichtlich so:
Temperatur, relative Feuchte und Luftdruck haben unterschiedliche Einheiten und
Größenordnungen.

Unterhalb des Charts wird für jede vorhandene Kurve deren Wertebereich angezeigt.

## Warum `recorder.get_statistics`?

Das Modul verwendet nicht die normale Entity-History-REST-API und benötigt
keinen Long-Lived-Access-Token im ESPHome-Gerät. ESPHome ruft über die Native API
die Home-Assistant-Action `recorder.get_statistics` auf und verarbeitet deren
Response direkt.

## Home-Assistant-Berechtigung

Auf der ESPHome-Geräteseite in Home Assistant muss die Option zum Erlauben von
Home-Assistant-Actions aktiviert werden.

## Hinweis zu `state_class`

Nur Sensoren, für die Home Assistant Recorder-Statistiken erzeugt, können hier
angezeigt werden. Bei Messwertsensoren ist typischerweise `state_class: measurement`
erforderlich.

## Architektur

`chart.yaml` enthält die komplette UI und die HA-Actions.

`history_chart.h/.cpp` ist ein kleiner C++-Datenhalter für die Antwortdaten.
Das eigentliche Rendering nutzt die native ESPHome-LVGL-`line`-Widgets. Dadurch
bleibt das Modul kompatibel mit LVGL 9 und benötigt kein separates Charting-Framework.

## Test

Im Zielprojekt:

```bash
esphome config your-panel.yaml
```

Danach:

```bash
esphome run your-panel.yaml
```

Wenn keine Daten erscheinen, zuerst in Home Assistant Developer Tools → Actions
prüfen, ob `recorder.get_statistics` für den betreffenden Sensor Werte liefert.


## Verhalten bei fehlenden Statistikdaten

Home Assistant nimmt Sensoren ohne Statistikdaten nicht in die Antwort auf.
Das Modul ordnet die Antwort deshalb über die Entity-ID zu. Wenn z.B. die
Feuchte keine Statistik besitzt, bleibt die Temperatur orange und die
Luftdruckkurve grün; die Kurven werden nicht einfach um eine Position verschoben.
