.pragma library
// Date input normalization. Port of macedot/cashflow src/dateInput.js.

var ISO_RE = /^\d{4}-\d{2}-\d{2}$/;
var LOOSE_ISO_RE = /^\d{4}-\d{1,2}-\d{1,2}$/;
var SLASH_RE = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/;
var DOTTED_RE = /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/;

function pad2(n) {
  return (n < 10 ? "0" : "") + n;
}

function isRealDate(year, month, day) {
  var d = new Date(Date.UTC(year, month - 1, day));
  return d.getUTCFullYear() === year && d.getUTCMonth() === month - 1 && d.getUTCDate() === day;
}

function toISO(year, month, day) {
  return year + "-" + pad2(month) + "-" + pad2(day);
}

function normalizeIso(value) {
  if (!ISO_RE.test(value) && !LOOSE_ISO_RE.test(value)) {
    return null;
  }
  var parts = value.split("-").map(Number);
  return isRealDate(parts[0], parts[1], parts[2]) ? toISO(parts[0], parts[1], parts[2]) : null;
}

function normalizeSlash(match) {
  var a = Number(match[1]);
  var b = Number(match[2]);
  var y = Number(match[3]);
  if (a > 12 && b <= 12) {
    return isRealDate(y, b, a) ? toISO(y, b, a) : null;
  }
  if (b > 12 && a <= 12) {
    return isRealDate(y, a, b) ? toISO(y, a, b) : null;
  }
  return null;
}

function normalizeDotted(match) {
  var d = Number(match[1]);
  var m = Number(match[2]);
  var y = Number(match[3]);
  return isRealDate(y, m, d) ? toISO(y, m, d) : null;
}

function normalizeDateInput(input) {
  if (input instanceof Date) {
    return isNaN(input.getTime())
      ? null
      : toISO(input.getUTCFullYear(), input.getUTCMonth() + 1, input.getUTCDate());
  }
  if (typeof input !== "string") {
    return null;
  }
  var value = input.trim();
  if (value === "") {
    return null;
  }
  var iso = normalizeIso(value);
  if (iso !== null) {
    return iso;
  }
  var slash = SLASH_RE.exec(value);
  if (slash) {
    return normalizeSlash(slash);
  }
  var dotted = DOTTED_RE.exec(value);
  if (dotted) {
    return normalizeDotted(dotted);
  }
  return null;
}
