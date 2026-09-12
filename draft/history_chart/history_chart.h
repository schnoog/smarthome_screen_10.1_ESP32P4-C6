#pragma once

#include <ArduinoJson.h>
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <string>

namespace esphome::modular_history_chart {

class HistoryChartData {
 public:
  static constexpr size_t MAX_SERIES = 3;
  static constexpr size_t MAX_SOURCE_POINTS = 1024;
  static constexpr size_t CHART_POINTS = 48;

  HistoryChartData() { this->clear(); }

  void begin(const char *range, const char *entity0, const char *entity1 = nullptr,
             const char *entity2 = nullptr) {
    this->clear();
    this->range_ = range != nullptr ? range : "";
    this->entities_[0] = entity0 != nullptr ? entity0 : "";
    this->entities_[1] = entity1 != nullptr ? entity1 : "";
    this->entities_[2] = entity2 != nullptr ? entity2 : "";
  }

  void clear() {
    this->range_.clear();
    for (auto &s : this->series_) {
      s.count = 0;
      s.valid = false;
      s.min = NAN;
      s.max = NAN;
      s.source_count = 0;
    }
  }

  // Parse the complete response of recorder.get_statistics.
  // ESPHome exposes the action response as response["response"].
  void load_response(JsonObjectConst response) {
    JsonObjectConst root = response["response"].as<JsonObjectConst>();
    if (root.isNull())
      return;

    JsonObjectConst statistics = root["statistics"].as<JsonObjectConst>();
    if (statistics.isNull())
      return;

    // Home Assistant omits statistic IDs that have no data. Map by the
    // requested entity ID rather than by object position.
    for (JsonPairConst kv : statistics) {
      std::string entity = kv.key().c_str();
      size_t series_index = MAX_SERIES;
      for (size_t i = 0; i < MAX_SERIES; i++) {
        if (!this->entities_[i].empty() && this->entities_[i] == entity) {
          series_index = i;
          break;
        }
      }
      if (series_index >= MAX_SERIES)
        continue;

      auto arr = kv.value().as<JsonArrayConst>();
      if (arr.isNull())
        continue;

      this->load_series_(series_index, arr);
    }
  }

  // Normalized Y coordinate in pixels for an LVGL line widget.
  int y(size_t series, size_t point, int height) const {
    if (series >= MAX_SERIES || point >= CHART_POINTS || height <= 0)
      return height / 2;

    const auto &s = this->series_[series];
    if (!s.valid || s.count == 0)
      return height / 2;

    float value = s.values[this->sample_index_(s.source_count, point)];
    if (!std::isfinite(value))
      return height / 2;

    float span = s.max - s.min;
    if (!std::isfinite(span) || span < 0.000001f)
      return height / 2;

    float normalized = (value - s.min) / span;
    normalized = std::clamp(normalized, 0.0f, 1.0f);

    // LVGL's Y axis grows downward.
    return static_cast<int>((1.0f - normalized) * static_cast<float>(height - 1));
  }

  std::string range_text(size_t series) const {
    if (series >= MAX_SERIES || !this->series_[series].valid)
      return "";

    const auto &s = this->series_[series];
    char buf[40];
    std::snprintf(buf, sizeof(buf), "%.1f … %.1f", s.min, s.max);
    return std::string(buf);
  }

 private:
  struct Series {
    std::array<float, MAX_SOURCE_POINTS> values{};
    size_t source_count{0};
    size_t count{0};
    float min{NAN};
    float max{NAN};
    bool valid{false};
  };

  void load_series_(size_t index, JsonArrayConst arr) {
    if (index >= MAX_SERIES)
      return;

    auto &s = this->series_[index];
    s.source_count = 0;
    s.count = 0;
    s.min = NAN;
    s.max = NAN;
    s.valid = false;

    for (JsonObjectConst item : arr) {
      if (s.source_count >= MAX_SOURCE_POINTS)
        break;

      if (item["mean"].isNull())
        continue;

      float value = item["mean"].as<float>();
      if (!std::isfinite(value))
        continue;

      s.values[s.source_count++] = value;
      if (!std::isfinite(s.min) || value < s.min)
        s.min = value;
      if (!std::isfinite(s.max) || value > s.max)
        s.max = value;
    }

    s.count = s.source_count;
    s.valid = s.source_count > 0;
  }

  static size_t sample_index_(size_t count, size_t point) {
    if (count == 0)
      return 0;
    if (count == 1 || CHART_POINTS == 1)
      return 0;

    size_t idx = (point * (count - 1)) / (CHART_POINTS - 1);
    if (idx >= count)
      idx = count - 1;
    return idx;
  }

  std::array<Series, MAX_SERIES> series_{};
  std::array<std::string, MAX_SERIES> entities_{};
  std::string range_;
};

}  // namespace esphome::modular_history_chart
