.pragma library
// Dashboard aggregations over runSimulation results. Local only.

function pad2(n) {
  return (n < 10 ? "0" : "") + n;
}

function isoFromDate(d) {
  return d.getUTCFullYear() + "-" + pad2(d.getUTCMonth() + 1) + "-" + pad2(d.getUTCDate());
}

function utcYmd(y, m, day) {
  return new Date(Date.UTC(y, m, day));
}

function todayUtc() {
  var n = new Date();
  return utcYmd(n.getFullYear(), n.getMonth(), n.getDate());
}

function addUtcMonths(d, months) {
  var y = d.getUTCFullYear();
  var m = d.getUTCMonth() + months;
  var day = d.getUTCDate();
  var next = new Date(Date.UTC(y, m, 1));
  var dim = new Date(Date.UTC(next.getUTCFullYear(), next.getUTCMonth() + 1, 0)).getUTCDate();
  return utcYmd(next.getUTCFullYear(), next.getUTCMonth(), Math.min(day, dim));
}

function startOfUtcMonth(d) {
  return utcYmd(d.getUTCFullYear(), d.getUTCMonth(), 1);
}

function endOfUtcMonth(d) {
  return utcYmd(d.getUTCFullYear(), d.getUTCMonth() + 1, 0);
}

function monthLabel(d) {
  var names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  return names[d.getUTCMonth()];
}

function findDay(results, iso) {
  for (var i = 0; i < results.length; i++) {
    if (isoFromDate(results[i].date) === iso) return results[i];
  }
  return null;
}

function sliceRange(results, startIso, endIso) {
  var out = [];
  for (var i = 0; i < results.length; i++) {
    var iso = isoFromDate(results[i].date);
    if (iso >= startIso && iso <= endIso) out.push(results[i]);
  }
  return out;
}

function monthTotals(results, year, month, events, generate) {
  var startDate = utcYmd(year, month, 1);
  var endDate = endOfUtcMonth(startDate);
  var start = isoFromDate(startDate);
  var end = isoFromDate(endDate);
  var days = sliceRange(results, start, end);
  var income = 0;
  var expense = 0;
  var gen = generateFn(generate);
  if (events && gen) {
    for (var e = 0; e < events.length; e++) {
      var occ = gen(events[e], startDate, endDate);
      for (var o = 0; o < occ.length; o++) {
        if (occ[o].value > 0) income += occ[o].value;
        else if (occ[o].value < 0) expense += -occ[o].value;
      }
    }
  } else {
    for (var i = 0; i < days.length; i++) {
      if (days[i].cashflow > 0) income += days[i].cashflow;
      else if (days[i].cashflow < 0) expense += -days[i].cashflow;
    }
  }
  return {
    income: income,
    expense: expense,
    net: income - expense,
    startIso: start,
    endIso: end,
    days: days
  };
}

function savingsRate(income, expense) {
  if (!income) return null;
  return (income - expense) / income;
}

function monthlySeries(results, endDate, count, events, generate) {
  var series = [];
  var cursor = startOfUtcMonth(endDate);
  var months = [];
  for (var i = count - 1; i >= 0; i--) {
    months.push(addUtcMonths(cursor, -i));
  }
  for (var m = 0; m < months.length; m++) {
    var d = months[m];
    var tot = monthTotals(results, d.getUTCFullYear(), d.getUTCMonth(), events, generate);
    series.push({
      label: monthLabel(d),
      year: d.getUTCFullYear(),
      month: d.getUTCMonth(),
      income: tot.income,
      expense: tot.expense,
      net: tot.net
    });
  }
  return series;
}

function sparkline(results, endIso, days) {
  var points = [];
  var end = parseIso(endIso);
  var start = utcYmd(end.getUTCFullYear(), end.getUTCMonth(), end.getUTCDate() - (days - 1));
  var startIso = isoFromDate(start);
  var slice = sliceRange(results, startIso, endIso);
  for (var i = 0; i < slice.length; i++) {
    points.push(slice[i].balance);
  }
  return points;
}

function parseIso(iso) {
  var p = String(iso).split("-").map(Number);
  return utcYmd(p[0], p[1] - 1, p[2]);
}

function categorySpend(events, results, year, month, generate) {
  var start = utcYmd(year, month, 1);
  var end = endOfUtcMonth(start);
  var spent = {};
  var budget = {};
  var list = events || [];
  for (var i = 0; i < list.length; i++) {
    var ev = list[i];
    var cat = ev.category || (ev.value < 0 ? "Other" : "Income");
    if (ev.value < 0) {
      var monthly = 0;
      if (ev.frequency === "daily") monthly = -ev.value * 30;
      else if (ev.frequency === "weekly") monthly = -ev.value * (30 / 7);
      else if (ev.frequency === "monthly") monthly = -ev.value;
      else if (ev.frequency === "quarterly") monthly = -ev.value / 3;
      else if (ev.frequency === "semi-annual") monthly = -ev.value / 6;
      else if (ev.frequency === "annual") monthly = -ev.value / 12;
      budget[cat] = (budget[cat] || 0) + monthly;
    }
  }
  // Actual spent this month from generated occurrences
  for (var e = 0; e < list.length; e++) {
    var event = list[e];
    if (!(event.value < 0)) continue;
    var catName = event.category || "Other";
    var hits = generateHits(event, start, end, generate);
    spent[catName] = (spent[catName] || 0) + hits;
  }
  var names = [];
  for (var k in budget) names.push(k);
  for (var s in spent) {
    if (names.indexOf(s) < 0) names.push(s);
  }
  names.sort();
  var rows = [];
  for (var n = 0; n < names.length; n++) {
    var name = names[n];
    rows.push({
      name: name,
      spent: spent[name] || 0,
      budget: budget[name] || 0
    });
  }
  return rows;
}

function generateFn(generate) {
  if (typeof generate === "function") return generate;
  if (typeof generateEventCashflows === "function") return generateEventCashflows;
  return null;
}

function generateHits(event, start, end, generate) {
  var gen = generateFn(generate);
  if (!gen) return 0;
  var occ = gen(event, start, end);
  var sum = 0;
  for (var i = 0; i < occ.length; i++) {
    if (occ[i].value < 0) sum += -occ[i].value;
  }
  return sum;
}

function upcomingBills(events, fromDate, count, generate) {
  var gen = generateFn(generate);
  if (!gen) return [];
  var until = addUtcMonths(fromDate, 6);
  var occ = [];
  var list = events || [];
  for (var i = 0; i < list.length; i++) {
    if (!(list[i].value < 0)) continue;
    var hits = gen(list[i], fromDate, until);
    for (var j = 0; j < hits.length; j++) {
      if (hits[j].date > fromDate) {
        occ.push({
          date: hits[j].date,
          iso: isoFromDate(hits[j].date),
          name: hits[j].name,
          value: hits[j].value,
          category: list[i].category || ""
        });
      }
    }
  }
  occ.sort(function (a, b) {
    return a.iso < b.iso ? -1 : a.iso > b.iso ? 1 : 0;
  });
  return occ.slice(0, count || 5);
}

function recentActivity(events, fromDate, count, generate) {
  var gen = generateFn(generate);
  if (!gen) return [];
  var start = utcYmd(fromDate.getUTCFullYear(), fromDate.getUTCMonth(), fromDate.getUTCDate() - 45);
  var occ = [];
  var list = events || [];
  for (var i = 0; i < list.length; i++) {
    var hits = gen(list[i], start, fromDate);
    for (var j = 0; j < hits.length; j++) {
      occ.push({
        date: hits[j].date,
        iso: isoFromDate(hits[j].date),
        name: hits[j].name,
        value: hits[j].value,
        category: list[i].category || ""
      });
    }
  }
  occ.sort(function (a, b) {
    return a.iso < b.iso ? 1 : a.iso > b.iso ? -1 : 0;
  });
  return occ.slice(0, count || 5);
}
