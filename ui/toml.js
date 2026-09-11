.pragma library
// Scalar TOML subset: sections, quoted strings, numbers, true/false.

function parse(raw) {
  var result = {};
  var section = "";
  var lines = String(raw || "").split("\n");
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    var heading = line.match(/^\s*\[([^\]]+)\]\s*(?:#.*)?$/);
    if (heading) {
      section = heading[1];
      continue;
    }
    var kv = line.match(/^\s*([\w-]+)\s*=\s*(?:"([^"\\]*)"|'([^']*)'|(-?\d+(?:\.\d+)?)|(true|false))\s*(?:#.*)?$/);
    if (!kv) continue;
    var value = kv[2] !== undefined ? kv[2]
      : kv[3] !== undefined ? kv[3]
      : kv[4] !== undefined ? Number(kv[4])
      : kv[5] === "true";
    result[(section ? section + "." : "") + kv[1]] = value;
  }
  return result;
}

function escapeToml(value) {
  if (typeof value === "number" && isFinite(value)) return String(value);
  if (typeof value === "boolean") return value ? "true" : "false";
  return '"' + String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
}

function serialize(values) {
  var flat = [];
  var sections = {};
  var keys = [];
  for (var k in values) keys.push(k);
  keys.sort();
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i];
    var val = values[key];
    if (val === undefined || val === null) continue;
    var dot = key.indexOf(".");
    if (dot < 0) {
      flat.push(key + " = " + escapeToml(val));
    } else {
      var sec = key.slice(0, dot);
      var rest = key.slice(dot + 1);
      if (!sections[sec]) sections[sec] = [];
      sections[sec].push(rest + " = " + escapeToml(val));
    }
  }
  var out = flat.slice();
  var secNames = [];
  for (var s in sections) secNames.push(s);
  secNames.sort();
  for (var n = 0; n < secNames.length; n++) {
    if (out.length) out.push("");
    out.push("[" + secNames[n] + "]");
    out = out.concat(sections[secNames[n]]);
  }
  return out.join("\n") + (out.length ? "\n" : "");
}
