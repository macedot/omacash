.pragma library
// Local CSV parse/serialize for recurring events. No network, no PapaParse.

var CSV_FREQUENCIES = {
  daily: true,
  weekly: true,
  monthly: true,
  quarterly: true,
  "semi-annual": true,
  annual: true
};

var CURRENCIES = { USD: true, EUR: true, GBP: true, BRL: true };

function splitCsvLine(line) {
  var cells = [];
  var cur = "";
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    var ch = line.charAt(i);
    if (inQuotes) {
      if (ch === '"') {
        if (line.charAt(i + 1) === '"') {
          cur += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cur += ch;
      }
    } else if (ch === '"') {
      inQuotes = true;
    } else if (ch === ",") {
      cells.push(cur);
      cur = "";
    } else {
      cur += ch;
    }
  }
  cells.push(cur);
  return cells;
}

function headerCells(row) {
  var header = [];
  for (var h = 0; h < row.length; h++) {
    header.push(String(row[h] || "").trim().toLowerCase());
  }
  return header;
}

function detectKind(header) {
  if (header.indexOf("name") >= 0 && header.indexOf("startdate") >= 0 && header.indexOf("frequency") >= 0 && header.indexOf("value") >= 0)
    return "events";
  if (header.indexOf("date") >= 0 && header.indexOf("cashflow") >= 0 && header.indexOf("balance") >= 0)
    return "results";
  return "";
}

function parseCsv(text) {
  var raw = String(text || "").replace(/^\uFEFF/, "");
  var lines = raw.split(/\r?\n/);
  var rows = [];
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() === "") continue;
    rows.push(splitCsvLine(lines[i]));
  }
  if (rows.length === 0) {
    return { kind: "", events: [], errors: ["CSV is empty"], imported: 0 };
  }
  var header = headerCells(rows[0]);
  var kind = detectKind(header);
  if (kind === "results") return parseResultsRows(rows, header);
  if (kind === "events") return parseEventsRows(rows, header);
  return {
    kind: "",
    events: [],
    errors: ["CSV needs an events header (name,startDate,frequency,value) or a results header (Date,Cashflow,Balance,Items)"],
    imported: 0
  };
}

function parseEventsRows(rows, header) {
  function col(name) {
    return header.indexOf(name);
  }
  var nameI = col("name");
  var startI = col("startdate");
  var endI = col("enddate");
  var freqI = col("frequency");
  var valueI = col("value");
  var currI = col("currency");
  var catI = col("category");
  var events = [];
  var errors = [];
  for (var r = 1; r < rows.length; r++) {
    var row = rows[r];
    var name = String(row[nameI] || "").trim();
    var startDate = String(row[startI] || "").trim();
    var endDate = endI >= 0 ? String(row[endI] || "").trim() : "";
    var frequency = String(row[freqI] || "").trim().toLowerCase();
    var value = Number(String(row[valueI] || "").trim());
    var currency = currI >= 0 ? String(row[currI] || "").trim().toUpperCase() : "USD";
    var category = catI >= 0 ? String(row[catI] || "").trim() : "";
    if (!name) {
      errors.push("Row " + (r + 1) + ": missing name");
      continue;
    }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(startDate)) {
      errors.push("Row " + (r + 1) + ": startDate must be YYYY-MM-DD");
      continue;
    }
    if (endDate !== "" && !/^\d{4}-\d{2}-\d{2}$/.test(endDate)) {
      errors.push("Row " + (r + 1) + ": endDate must be YYYY-MM-DD");
      continue;
    }
    if (!CSV_FREQUENCIES[frequency]) {
      errors.push("Row " + (r + 1) + ': unknown frequency "' + frequency + '"');
      continue;
    }
    if (!isFinite(value)) {
      errors.push("Row " + (r + 1) + ": value is not a number");
      continue;
    }
    if (currency && !CURRENCIES[currency]) currency = "USD";
    if (!currency) currency = "USD";
    events.push({
      name: name,
      startDate: startDate,
      endDate: endDate,
      frequency: frequency,
      value: value,
      currency: currency,
      category: category
    });
  }
  return { kind: "events", events: events, errors: errors, imported: events.length };
}

function parseResultsRows(rows, header) {
  function col(name) {
    return header.indexOf(name);
  }
  var dateI = col("date");
  var cashI = col("cashflow");
  var itemsI = col("items");
  var events = [];
  var errors = [];
  for (var r = 1; r < rows.length; r++) {
    var row = rows[r];
    var date = String(row[dateI] || "").trim();
    var cashflow = Number(String(row[cashI] || "").trim());
    var items = itemsI >= 0 ? String(row[itemsI] || "").trim() : "";
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      errors.push("Row " + (r + 1) + ": Date must be YYYY-MM-DD");
      continue;
    }
    if (!isFinite(cashflow)) {
      errors.push("Row " + (r + 1) + ": Cashflow is not a number");
      continue;
    }
    if (cashflow === 0) continue;
    events.push({
      name: items || "Cashflow",
      startDate: date,
      endDate: date,
      frequency: "monthly",
      value: cashflow,
      currency: "USD",
      category: ""
    });
  }
  return { kind: "results", events: events, errors: errors, imported: events.length };
}

function isoFromResultDate(d) {
  if (typeof d === "string") return d;
  if (d instanceof Date) {
    var m = d.getUTCMonth() + 1;
    var day = d.getUTCDate();
    return d.getUTCFullYear() + "-" + (m < 10 ? "0" : "") + m + "-" + (day < 10 ? "0" : "") + day;
  }
  return "";
}

function filterResults(rows) {
  var list = rows || [];
  var out = [];
  for (var i = 0; i < list.length; i++) {
    if (list[i].cashflow !== 0 || i === 0 || i === list.length - 1) out.push(list[i]);
  }
  return out;
}

function serializeResultsCsv(rows) {
  var filtered = filterResults(rows);
  var lines = ["Date,Cashflow,Balance,Items"];
  for (var i = 0; i < filtered.length; i++) {
    var r = filtered[i];
    var items = Array.isArray(r.items) ? r.items.join("; ") : String(r.items || "");
    lines.push([
      csvEscape(isoFromResultDate(r.date)),
      (Number(r.cashflow) || 0).toFixed(2),
      (Number(r.balance) || 0).toFixed(2),
      csvEscape(items)
    ].join(","));
  }
  return lines.join("\n") + "\n";
}

function csvEscape(value) {
  var s = String(value === undefined || value === null ? "" : value);
  if (/[",\n\r]/.test(s)) {
    return '"' + s.replace(/"/g, '""') + '"';
  }
  return s;
}

function serializeCsv(events) {
  var rows = [["name", "startDate", "endDate", "frequency", "value", "currency", "category"]];
  var list = events || [];
  for (var i = 0; i < list.length; i++) {
    var e = list[i];
    rows.push([
      e.name || "",
      e.startDate || "",
      e.endDate || "",
      e.frequency || "",
      (Number(e.value) || 0).toFixed(2),
      e.currency || "USD",
      e.category || ""
    ]);
  }
  var lines = [];
  for (var r = 0; r < rows.length; r++) {
    var cells = [];
    for (var c = 0; c < rows[r].length; c++) cells.push(csvEscape(rows[r][c]));
    lines.push(cells.join(","));
  }
  return lines.join("\n") + "\n";
}
