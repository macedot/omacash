.pragma library

var SYMBOLS = { USD: "$", EUR: "€", GBP: "£", BRL: "R$" };
var CURRENCIES = ["USD", "EUR", "GBP", "BRL"];

function symbol(currency) {
  return SYMBOLS[currency] || "$";
}

function nextCurrency(current) {
  var i = CURRENCIES.indexOf(current);
  return CURRENCIES[(i + 1) % CURRENCIES.length];
}

function pad2(n) {
  return (n < 10 ? "0" : "") + n;
}

function iso(d) {
  return d.getUTCFullYear() + "-" + pad2(d.getUTCMonth() + 1) + "-" + pad2(d.getUTCDate());
}

function money(amount, currency) {
  var n = Number(amount);
  if (!isFinite(n)) n = 0;
  var abs = Math.abs(n);
  var whole = Math.floor(abs);
  var frac = Math.round((abs - whole) * 100);
  if (frac === 100) {
    whole += 1;
    frac = 0;
  }
  var digits = String(whole);
  var grouped = "";
  while (digits.length > 3) {
    grouped = "," + digits.slice(-3) + grouped;
    digits = digits.slice(0, -3);
  }
  grouped = digits + grouped;
  var body = grouped + "." + pad2(frac);
  var sign = n < 0 ? "-" : "";
  var cur = currency === "BRL" ? "R$ " : symbol(currency);
  if (currency === "BRL") return sign + cur + body.replace(/,/g, "X").replace(/\./g, ",").replace(/X/g, ".");
  return sign + cur + body;
}

function compact(amount, currency) {
  var n = Number(amount);
  if (!isFinite(n)) n = 0;
  var sign = n < 0 ? "-" : "";
  var abs = Math.abs(n);
  var cur = currency === "BRL" ? "R$" : symbol(currency);
  var body;
  if (abs >= 1000000) body = (abs / 1000000).toFixed(1) + "M";
  else if (abs >= 10000) body = (abs / 1000).toFixed(1) + "k";
  else if (abs >= 1000) body = (abs / 1000).toFixed(1) + "k";
  else body = abs.toFixed(abs >= 100 ? 0 : 2);
  return sign + cur + body;
}

function signedMoney(amount, currency) {
  var n = Number(amount) || 0;
  var prefix = n > 0 ? "+" : "";
  return prefix + money(n, currency);
}

function percent(value) {
  if (value === null || value === undefined || !isFinite(value)) return "—";
  return Math.round(value * 100) + "%";
}

function prettyDate(isoDate) {
  if (!isoDate) return "";
  var p = String(isoDate).split("-").map(Number);
  var names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  return names[p[1] - 1] + " " + p[2];
}

function categoryGlyph(name) {
  var n = String(name || "").toLowerCase();
  if (n.indexOf("groc") >= 0) return "󰔓";
  if (n.indexOf("din") >= 0 || n.indexOf("food") >= 0 || n.indexOf("restaurant") >= 0) return "󰩰";
  if (n.indexOf("util") >= 0 || n.indexOf("power") >= 0 || n.indexOf("electric") >= 0) return "󰠠";
  if (n.indexOf("mort") >= 0 || n.indexOf("rent") >= 0 || n.indexOf("hous") >= 0) return "󰋜";
  if (n.indexOf("sav") >= 0) return "󰠦";
  if (n.indexOf("sub") >= 0 || n.indexOf("stream") >= 0) return "󰕧";
  if (n.indexOf("income") >= 0 || n.indexOf("salary") >= 0) return "󰁍";
  if (n.indexOf("trans") >= 0 || n.indexOf("car") >= 0 || n.indexOf("fuel") >= 0 || n.indexOf("gas") >= 0) return "󰈆";
  if (n.indexOf("insur") >= 0) return "󰒃";
  if (n.indexOf("net") >= 0 || n.indexOf("internet") >= 0 || n.indexOf("wifi") >= 0) return "󰖩";
  return "󰀄";
}

function navGlyph(id) {
  var icons = {
    dashboard: "󰕮",
    events: "󰃭",
    accounts: "󰀎",
    transactions: "󰊯",
    budget: "󰃬",
    bills: "󰠗",
    reports: "󰈙",
    settings: "󰒓",
    privacy: "󰌾"
  };
  return icons[id] || "󰀄";
}

function monthName(index) {
  return ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][index] || "";
}

function clockLabel(d) {
  var names = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
  var months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
  var h = d.getHours();
  var m = pad2(d.getMinutes());
  var am = h >= 12 ? "PM" : "AM";
  var hr = h % 12;
  if (hr === 0) hr = 12;
  return names[d.getDay()] + "  " + months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear() + "\n" + hr + ":" + m + " " + am;
}
