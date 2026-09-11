import QtQuick
import Quickshell
import Quickshell.Io
import "toml.js" as Toml

QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
  readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || (home + "/.local/share")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")
  readonly property string configPath: configHome + "/omacash/config.toml"
  readonly property string eventsPath: dataHome + "/omacash/events.json"
  readonly property string statePath: stateHome + "/omacash/state.json"

  property var events: []
  property var config: ({})
  property var uiState: ({})
  property bool eventsReady: false
  property bool configReady: false
  property bool stateReady: false
  readonly property bool ready: eventsReady && configReady && stateReady
  property string error: ""

  function parseEvents(raw) {
    try {
      var data = JSON.parse(String(raw || "[]"));
      var list = Array.isArray(data) ? data : (data && Array.isArray(data.events) ? data.events : []);
      var out = [];
      for (var i = 0; i < list.length; i++) {
        var e = list[i] || {};
        out.push({
          id: e.id || ("e" + i),
          name: String(e.name || ""),
          startDate: String(e.startDate || ""),
          endDate: e.endDate ? String(e.endDate) : "",
          frequency: String(e.frequency || "monthly"),
          value: Number(e.value) || 0,
          currency: String(e.currency || "USD"),
          category: String(e.category || "")
        });
      }
      return out;
    } catch (err) {
      root.error = "Could not parse events.json";
      return root.events && root.events.length ? root.events : [];
    }
  }

  function parseState(raw) {
    try {
      var data = JSON.parse(String(raw || "{}"));
      if (!data || typeof data !== "object") data = {};
      return {
        page: data.page || "dashboard",
        range: data.range || "6m",
        sortKey: data.sortKey || "",
        sortDir: data.sortDir || "",
        customStart: data.customStart || "",
        customEnd: data.customEnd || ""
      };
    } catch (err) {
      return { page: "dashboard", range: "6m", sortKey: "", sortDir: "", customStart: "", customEnd: "" };
    }
  }

  function defaultConfig() {
    return {
      currency: "USD",
      period: "1y",
      initial_balance: 0
    };
  }

  function parseConfig(raw) {
    var parsed = Toml.parse(raw);
    var cfg = defaultConfig();
    if (typeof parsed.currency === "string" && parsed.currency.length) cfg.currency = parsed.currency;
    if (typeof parsed.period === "string" && parsed.period.length) cfg.period = parsed.period;
    if (typeof parsed.initial_balance === "number") cfg.initial_balance = parsed.initial_balance;
    if (typeof parsed.monthly_spend_cap === "number") cfg.monthly_spend_cap = parsed.monthly_spend_cap;
    cfg.keys = {};
    for (var k in parsed) {
      if (k.indexOf("keys.") === 0) cfg.keys[k.slice(5)] = parsed[k];
    }
    return cfg;
  }

  function writeAtomic(path, text, proc) {
    var slash = path.lastIndexOf("/");
    var dir = slash >= 0 ? path.slice(0, slash) : ".";
    proc.command = ["sh", "-c",
      "mkdir -p -- \"$1\" && printf '%s' \"$3\" > \"$2\" && mv -f -- \"$2\" \"$4\"",
      "omacash-write", dir, path + ".tmp", text, path];
    proc.running = true;
  }

  function saveEvents(list) {
    events = list;
    var payload = JSON.stringify({ version: 1, events: list }, null, 2) + "\n";
    writeAtomic(eventsPath, payload, eventsWriter);
  }

  function saveConfig(cfg) {
    config = cfg;
    var values = {
      currency: cfg.currency || "USD",
      period: cfg.period || "1y",
      initial_balance: Number(cfg.initial_balance) || 0
    };
    if (cfg.monthly_spend_cap !== undefined && cfg.monthly_spend_cap !== null && cfg.monthly_spend_cap !== "")
      values.monthly_spend_cap = Number(cfg.monthly_spend_cap);
    if (cfg.keys) {
      for (var k in cfg.keys) values["keys." + k] = cfg.keys[k];
    }
    writeAtomic(configPath, Toml.serialize(values), configWriter);
  }

  function saveState(next) {
    uiState = next;
    writeAtomic(statePath, JSON.stringify(next, null, 2) + "\n", stateWriter);
  }

  function wipeAll() {
    events = [];
    config = defaultConfig();
    uiState = { page: "dashboard", range: "6m", sortKey: "", sortDir: "", customStart: "", customEnd: "" };
    saveEvents([]);
    saveConfig(config);
    saveState(uiState);
  }

  property FileView eventsFile: FileView {
    path: root.eventsPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: { root.events = root.parseEvents(text()); root.eventsReady = true; root.error = ""; }
    onLoadFailed: { root.events = []; root.eventsReady = true; }
  }

  property FileView configFile: FileView {
    path: root.configPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: { root.config = root.parseConfig(text()); root.configReady = true; }
    onLoadFailed: { root.config = root.defaultConfig(); root.configReady = true; }
  }

  property FileView stateFile: FileView {
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: { root.uiState = root.parseState(text()); root.stateReady = true; }
    onLoadFailed: { root.uiState = root.parseState(""); root.stateReady = true; }
  }

  property Process eventsWriter: Process {
    command: ["true"]
    onExited: function (code) { if (code !== 0) root.error = "Could not write events.json"; }
  }
  property Process configWriter: Process {
    command: ["true"]
    onExited: function (code) { if (code !== 0) root.error = "Could not write config.toml"; }
  }
  property Process stateWriter: Process {
    command: ["true"]
    onExited: function (code) { if (code !== 0) root.error = "Could not write state.json"; }
  }
}
