.pragma library
// Cashflow simulation. Port of macedot/cashflow src/cashflow.js.
// Pure functions, UTC date math, no I/O. QML and Node tests both load this.

var FREQUENCIES = {
  DAILY: "daily",
  WEEKLY: "weekly",
  MONTHLY: "monthly",
  QUARTERLY: "quarterly",
  SEMI_ANNUAL: "semi-annual",
  ANNUAL: "annual"
};

var VALID_FREQUENCIES = {
  daily: true,
  weekly: true,
  monthly: true,
  quarterly: true,
  "semi-annual": true,
  annual: true
};

var SIMPLE_PERIOD_DAYS = {
  daily: 1,
  weekly: 7
};

var MONTH_PERIODS = {
  monthly: 1,
  quarterly: 3,
  "semi-annual": 6
};

function isValidDate(d) {
  return d instanceof Date && !isNaN(d.getTime());
}

function parseDate(dateStr) {
  if (dateStr instanceof Date) {
    return new Date(dateStr);
  }
  if (typeof dateStr === "string" && /^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
    var parts = dateStr.split("-").map(Number);
    return new Date(Date.UTC(parts[0], parts[1] - 1, parts[2]));
  }
  return new Date(dateStr);
}

function isLeapYear(year) {
  return new Date(Date.UTC(year, 1, 29)).getUTCMonth() === 1;
}

function getNextMonthYear(currentMonth, currentYear, monthsToAdd) {
  var nextMonth = currentMonth + monthsToAdd;
  var nextYear = nextMonth > 11 ? currentYear + 1 : currentYear;
  return { year: nextYear, month: nextMonth % 12 };
}

function addMonthsClamped(year, month, monthsToAdd, anchorDay) {
  var next = getNextMonthYear(month, year, monthsToAdd);
  var daysInNextMonth = new Date(Date.UTC(next.year, next.month + 1, 0)).getUTCDate();
  var nextDay = Math.min(anchorDay, daysInNextMonth);
  return new Date(Date.UTC(next.year, next.month, nextDay));
}

function addAnnualClamped(year, month, anchorDay) {
  var nextYear = year + 1;
  var nextDay = anchorDay === 29 && !isLeapYear(nextYear) ? 28 : anchorDay;
  return new Date(Date.UTC(nextYear, month, nextDay));
}

function addPeriod(date, frequency, anchorDay) {
  if (!VALID_FREQUENCIES[frequency]) {
    throw new Error(
      'Invalid frequency: "' + frequency + '". Must be one of: daily, weekly, monthly, quarterly, semi-annual, annual'
    );
  }
  var simpleDays = SIMPLE_PERIOD_DAYS[frequency];
  if (simpleDays !== undefined) {
    var d = new Date(date);
    d.setUTCDate(d.getUTCDate() + simpleDays);
    return d;
  }
  var year = date.getUTCFullYear();
  var month = date.getUTCMonth();
  var anchoredDay = typeof anchorDay === "number" ? anchorDay : date.getUTCDate();
  var monthStep = MONTH_PERIODS[frequency];
  if (monthStep !== undefined) {
    return addMonthsClamped(year, month, monthStep, anchoredDay);
  }
  if (frequency === FREQUENCIES.ANNUAL) {
    return addAnnualClamped(year, month, anchoredDay);
  }
  throw new Error("Unhandled frequency: " + frequency);
}

function getEventEnd(endDate, eventName) {
  var label = eventName || "unnamed event";
  if (endDate === null || endDate === undefined || endDate === "") {
    return null;
  }
  if (endDate instanceof Date) {
    if (!isValidDate(endDate)) {
      throw new Error('Invalid endDate for event "' + label + '": Date object is not a valid date.');
    }
    return new Date(endDate);
  }
  if (typeof endDate === "string") {
    var trimmed = endDate.trim();
    if (trimmed === "") {
      return null;
    }
    var parsed = parseDate(trimmed);
    if (!isValidDate(parsed)) {
      throw new Error(
        'Invalid endDate "' + endDate + '" for event "' + label + '": could not be parsed. Use YYYY-MM-DD format.'
      );
    }
    return parsed;
  }
  throw new Error(
    'Invalid endDate for event "' + label + '": expected Date or YYYY-MM-DD string, got ' + typeof endDate + "."
  );
}

function getEffectiveEnd(eventEnd, simulationEnd) {
  if (eventEnd !== null && eventEnd < simulationEnd) {
    return eventEnd;
  }
  return simulationEnd;
}

function findFirstOccurrence(startDate, targetStart, frequency, anchorDay) {
  var currentDate = parseDate(startDate);
  while (currentDate < targetStart) {
    currentDate = addPeriod(currentDate, frequency, anchorDay);
  }
  return currentDate;
}

function generateEventCashflows(event, simStart, simEnd) {
  var startDate = parseDate(event.startDate);
  if (!isValidDate(startDate)) {
    throw new Error(
      'Invalid startDate "' + event.startDate + '" for event "' + (event.name || "unnamed event") + '": could not be parsed. Use YYYY-MM-DD format.'
    );
  }
  var eventEnd = getEventEnd(event.endDate, event.name);
  var anchorDay = startDate.getUTCDate();
  if (eventEnd !== null && eventEnd < simStart) {
    return [];
  }
  var effectiveEnd = getEffectiveEnd(eventEnd, simEnd);
  var firstOccurrence = findFirstOccurrence(startDate, simStart, event.frequency, anchorDay);
  if (firstOccurrence > effectiveEnd) {
    return [];
  }
  var result = [];
  var currentDate = new Date(firstOccurrence);
  while (currentDate <= effectiveEnd) {
    result.push({
      date: new Date(currentDate),
      value: event.value,
      name: event.name,
      category: event.category || ""
    });
    currentDate = addPeriod(currentDate, event.frequency, anchorDay);
  }
  return result;
}

function runSimulation(events, initialBalance, simStart, simEnd) {
  var start = parseDate(simStart);
  var end = parseDate(simEnd);
  var cashflowByDate = {};
  var list = events || [];
  for (var i = 0; i < list.length; i++) {
    var eventCashflows = generateEventCashflows(list[i], start, end);
    for (var j = 0; j < eventCashflows.length; j++) {
      var cf = eventCashflows[j];
      var dateKey = cf.date.getUTCFullYear() + "-" + cf.date.getUTCMonth() + "-" + cf.date.getUTCDate();
      if (!cashflowByDate[dateKey]) {
        cashflowByDate[dateKey] = { date: cf.date, cashflow: 0, items: [] };
      }
      cashflowByDate[dateKey].cashflow += cf.value;
      cashflowByDate[dateKey].items.push(cf.name);
    }
  }
  var results = [];
  var balance = initialBalance;
  var current = new Date(Date.UTC(start.getUTCFullYear(), start.getUTCMonth(), start.getUTCDate()));
  var endDay = new Date(Date.UTC(end.getUTCFullYear(), end.getUTCMonth(), end.getUTCDate()));
  while (current <= endDay) {
    var key = current.getUTCFullYear() + "-" + current.getUTCMonth() + "-" + current.getUTCDate();
    var entry = cashflowByDate[key];
    if (entry) {
      balance += entry.cashflow;
      results.push({
        date: new Date(current),
        cashflow: entry.cashflow,
        balance: balance,
        items: entry.items.slice()
      });
    } else {
      results.push({
        date: new Date(current),
        cashflow: 0,
        balance: balance,
        items: []
      });
    }
    current.setUTCDate(current.getUTCDate() + 1);
  }
  return results;
}
