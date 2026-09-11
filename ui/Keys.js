.pragma library

var DEFAULTS = {
  dashboard: "g,d",
  events: "g,e",
  settings: "g,s",
  privacy: "g,p",
  new_event: "n",
  delete_event: "x Delete",
  range_3m: "3",
  range_6m: "6",
  range_1y: "y",
  cycle_currency: "c",
  export_csv: "e",
  export_results: "r",
  import_csv: "i",
  help: "?",
  close: "Esc"
};

function resolve(overrides) {
  var bindings = {};
  var src = overrides && typeof overrides === "object" ? overrides : {};
  for (var id in DEFAULTS) {
    var raw = src[id] !== undefined ? String(src[id]) : DEFAULTS[id];
    bindings[id] = raw.split(/\s+/).filter(function (s) { return s.length > 0; });
  }
  return bindings;
}

function pretty(sequence) {
  return String(sequence || "")
    .replace(/^g,/, "g ")
    .replace("Delete", "Del");
}

var SHEET = [
  { id: "dashboard", label: "Dashboard" },
  { id: "events", label: "Events" },
  { id: "settings", label: "Settings" },
  { id: "privacy", label: "Data & Privacy" },
  { id: "new_event", label: "New event" },
  { id: "delete_event", label: "Delete event" },
  { id: "range_3m", label: "Cashflow 3 months" },
  { id: "range_6m", label: "Cashflow 6 months" },
  { id: "range_1y", label: "Cashflow 1 year" },
  { id: "cycle_currency", label: "Cycle currency" },
  { id: "export_csv", label: "Export events CSV" },
  { id: "export_results", label: "Export results CSV" },
  { id: "import_csv", label: "Import from Downloads" },
  { id: "help", label: "Keys sheet" },
  { id: "close", label: "Close" }
];
