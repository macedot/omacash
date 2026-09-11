.pragma library
// Events table sorting. Port of macedot/cashflow src/eventSort.js.

var FREQUENCY_RANK = {
  daily: 0,
  weekly: 1,
  monthly: 2,
  quarterly: 3,
  "semi-annual": 4,
  annual: 5
};

var OPEN_ENDED = "9999-12-31";

function periodValue(event) {
  var start = typeof event.startDate === "string" ? event.startDate : "";
  var end = typeof event.endDate === "string" && event.endDate !== "" ? event.endDate : OPEN_ENDED;
  return start + "~" + end;
}

function compareStrings(a, b) {
  if (a < b) return -1;
  if (a > b) return 1;
  return 0;
}

function frequencyRank(event) {
  var rank = FREQUENCY_RANK[event.frequency];
  return rank === undefined ? 1e9 : rank;
}

function compareByKey(a, b, key) {
  if (key === "frequency") {
    return frequencyRank(a) - frequencyRank(b);
  }
  if (key === "value") {
    return (Number(a.value) || 0) - (Number(b.value) || 0);
  }
  return compareStrings(periodValue(a), periodValue(b));
}

function signGroup(event) {
  var value = Number(event.value) || 0;
  if (value > 0) return 0;
  return value < 0 ? 2 : 1;
}

function sortEvents(events, key, direction) {
  var factor = direction === "desc" ? -1 : 1;
  var decorated = [];
  for (var i = 0; i < events.length; i++) {
    decorated.push({ event: events[i], index: i });
  }
  decorated.sort(function (a, b) {
    if (key === "value" && direction === "positive-first") {
      var groupDiff = signGroup(a.event) - signGroup(b.event);
      if (groupDiff !== 0) return groupDiff;
      var av = Math.abs(Number(a.event.value) || 0);
      var bv = Math.abs(Number(b.event.value) || 0);
      return signGroup(a.event) === 2 ? bv - av : av - bv;
    }
    var primary = compareByKey(a.event, b.event, key);
    if (primary !== 0) return factor * primary;
    var period = compareStrings(periodValue(a.event), periodValue(b.event));
    return period !== 0 ? period : a.index - b.index;
  });
  var out = [];
  for (var j = 0; j < decorated.length; j++) {
    out.push(decorated[j].event);
  }
  return out;
}

function nextEventSort(current, key) {
  if (!current || current.key !== key) {
    return { key: key, direction: "asc" };
  }
  if (current.direction === "asc") {
    return { key: key, direction: "desc" };
  }
  if (key === "value" && current.direction === "desc") {
    return { key: key, direction: "positive-first" };
  }
  return null;
}
