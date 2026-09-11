import QtQuick
import Quickshell
import Quickshell.Io
import "cashflow.js" as Cashflow
import "stats.js" as Stats
import "eventSort.js" as EventSort
import "dateInput.js" as DateInput
import "csv.js" as Csv
import "Format.js" as Format
import "Keys.js" as KeyMap

QtObject {
  id: session

  property Store store: Store {}
  readonly property bool ready: store.ready
  property var events: []
  property var results: []
  property string currency: "USD"
  property string period: "1y"
  property real initialBalance: 0
  property var monthlySpendCap: null
  property string page: "dashboard"
  property string range: "6m"
  property var sort: null
  property string status: ""
  property string persistError: ""
  property bool confirmWipe: false
  property string csvNotice: ""

  readonly property var today: Stats.todayUtc()
  readonly property string todayIso: Stats.isoFromDate(today)
  readonly property var todayEntry: Stats.findDay(results, todayIso)
  readonly property real todayBalance: todayEntry ? todayEntry.balance : initialBalance
  readonly property real todayNet: todayEntry ? todayEntry.cashflow : 0

  readonly property int thisYear: today.getUTCFullYear()
  readonly property int thisMonth: today.getUTCMonth()
  readonly property var monthStats: Stats.monthTotals(results, thisYear, thisMonth, events, Cashflow.generateEventCashflows)
  readonly property real monthIncome: monthStats.income
  readonly property real monthSpend: monthStats.expense
  readonly property real monthNet: monthStats.net
  readonly property var savings: Stats.savingsRate(monthIncome, monthSpend)
  readonly property var lastMonthStats: Stats.monthTotals(results, addMonths(today, -1).getUTCFullYear(), addMonths(today, -1).getUTCMonth(), events, Cashflow.generateEventCashflows)
  readonly property real monthDelta: todayBalance - monthStartBalance
  readonly property real monthStartBalance: {
    var entry = Stats.findDay(results, monthStats.startIso);
    if (!entry) return initialBalance;
    return entry.balance - entry.cashflow;
  }
  readonly property real lastMonthSavings: {
    var r = Stats.savingsRate(lastMonthStats.income, lastMonthStats.expense);
    return r === null ? 0 : r;
  }
  readonly property real savingsDelta: (savings === null ? 0 : savings) - lastMonthSavings

  readonly property int rangeMonths: range === "3m" ? 3 : range === "1y" ? 12 : 6
  readonly property var monthly: Stats.monthlySeries(results, today, rangeMonths, events, Cashflow.generateEventCashflows)
  readonly property var spark: Stats.sparkline(results, todayIso, 30)
  readonly property var savingsBars: {
    var series = Stats.monthlySeries(results, today, 6, events, Cashflow.generateEventCashflows);
    var bars = [];
    for (var i = 0; i < series.length; i++)
      bars.push(Stats.savingsRate(series[i].income, series[i].expense) || 0);
    return bars;
  }
  readonly property var categories: Stats.categorySpend(events, results, thisYear, thisMonth, Cashflow.generateEventCashflows)
  readonly property var upcoming: Stats.upcomingBills(events, today, 5, Cashflow.generateEventCashflows)
  readonly property var recent: Stats.recentActivity(events, today, 5, Cashflow.generateEventCashflows)
  readonly property var sortedEvents: {
    if (!sort || !sort.key) return events;
    return EventSort.sortEvents(events, sort.key, sort.direction);
  }
  readonly property var bindings: KeyMap.resolve(store.config.keys)
  readonly property string version: "0.1.0"
  readonly property string downloadsDir: Quickshell.env("XDG_DOWNLOAD_DIR") || (Quickshell.env("HOME") + "/Downloads")
  readonly property string eventsCsvPath: downloadsDir + "/cashflow-events.csv"
  readonly property string resultsCsvPath: downloadsDir + "/cashflow-results.csv"
  property string pendingImport: ""
  property string importFallback: ""

  function addMonths(d, n) {
    return Stats.addUtcMonths(d, n);
  }

  function periodRange() {
    var end = today;
    var start;
    if (period === "1m") start = Stats.addUtcMonths(end, -1);
    else if (period === "3m") start = Stats.addUtcMonths(end, -3);
    else if (period === "6m") start = Stats.addUtcMonths(end, -6);
    else start = Stats.addUtcMonths(end, -12);
    if (period === "custom" && store.uiState.customStart && store.uiState.customEnd) {
      return { start: store.uiState.customStart, end: store.uiState.customEnd };
    }
    return { start: Stats.isoFromDate(start), end: Stats.isoFromDate(end) };
  }

  readonly property var detailRange: periodRange()
  readonly property var detailResults: Stats.sliceRange(results, detailRange.start, detailRange.end)

  function eventDateBounds() {
    var start = Stats.isoFromDate(Stats.addUtcMonths(today, -18));
    var end = Stats.isoFromDate(Stats.addUtcMonths(today, 12));
    for (var i = 0; i < events.length; i++) {
      var s = events[i].startDate || "";
      var e = events[i].endDate || "";
      if (s && s < start) start = s;
      if (e && e > end) end = e;
      if (s && !e && s > end) end = s;
    }
    return { start: start, end: end };
  }

  function resimulate() {
    persistError = store.error;
    var bounds = eventDateBounds();
    try {
      results = Cashflow.runSimulation(events, initialBalance, bounds.start, bounds.end);
      status = "";
    } catch (err) {
      status = String(err);
    }
  }

  function applyStore() {
    events = store.events.slice();
    currency = store.config.currency || "USD";
    period = store.config.period || "1y";
    initialBalance = Number(store.config.initial_balance) || 0;
    monthlySpendCap = store.config.monthly_spend_cap === undefined ? null : store.config.monthly_spend_cap;
    page = store.uiState.page || "dashboard";
    range = store.uiState.range || "6m";
    if (store.uiState.sortKey)
      sort = { key: store.uiState.sortKey, direction: store.uiState.sortDir || "asc" };
    else
      sort = null;
    resimulate();
  }

  function persistState() {
    store.saveState({
      page: page,
      range: range,
      sortKey: sort ? sort.key : "",
      sortDir: sort ? sort.direction : "",
      customStart: store.uiState.customStart || "",
      customEnd: store.uiState.customEnd || ""
    });
  }

  function persistConfig() {
    var cfg = {
      currency: currency,
      period: period,
      initial_balance: initialBalance,
      keys: store.config.keys || {}
    };
    if (monthlySpendCap !== null && monthlySpendCap !== undefined && monthlySpendCap !== "")
      cfg.monthly_spend_cap = Number(monthlySpendCap);
    store.saveConfig(cfg);
  }

  function setPage(next) {
    if (next === "accounts" || next === "transactions" || next === "budget" || next === "bills" || next === "reports")
      return;
    page = next;
    persistState();
  }

  function setRange(next) {
    range = next;
    persistState();
  }

  function setCurrency(next) {
    currency = next;
    persistConfig();
  }

  function cycleCurrency() {
    setCurrency(Format.nextCurrency(currency));
  }

  function setPeriod(next) {
    period = next;
    persistConfig();
  }

  function setInitialBalance(value) {
    initialBalance = Number(value) || 0;
    persistConfig();
    resimulate();
  }

  function setSpendCap(value) {
    if (value === "" || value === null || value === undefined) monthlySpendCap = null;
    else monthlySpendCap = Number(value);
    persistConfig();
  }

  function newId() {
    return "e" + Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36);
  }

  function upsertEvent(draft, existingId) {
    var start = DateInput.normalizeDateInput(draft.startDate);
    var end = draft.endDate ? DateInput.normalizeDateInput(draft.endDate) : "";
    if (!start) {
      status = "Start date must be YYYY-MM-DD";
      return false;
    }
    if (draft.endDate && !end && String(draft.endDate).trim() !== "") {
      status = "End date must be YYYY-MM-DD";
      return false;
    }
    var event = {
      id: existingId || newId(),
      name: String(draft.name || "").trim(),
      startDate: start,
      endDate: end || "",
      frequency: draft.frequency || "monthly",
      value: Number(draft.value) || 0,
      currency: draft.currency || currency,
      category: String(draft.category || "").trim()
    };
    if (!event.name) {
      status = "Name is required";
      return false;
    }
    var next = events.slice();
    if (existingId) {
      for (var i = 0; i < next.length; i++) {
        if (next[i].id === existingId) { next[i] = event; break; }
      }
    } else {
      next.push(event);
    }
    events = next;
    store.saveEvents(next);
    resimulate();
    status = "";
    return true;
  }

  function removeEvent(id) {
    var next = [];
    for (var i = 0; i < events.length; i++) {
      if (events[i].id !== id) next.push(events[i]);
    }
    events = next;
    store.saveEvents(next);
    resimulate();
  }

  function cycleSort(key) {
    sort = EventSort.nextEventSort(sort, key);
    persistState();
  }

  function exportCsv() {
    return Csv.serializeCsv(events);
  }

  function exportResultsCsv() {
    return Csv.serializeResultsCsv(detailResults);
  }

  function importCsv(text) {
    var parsed = Csv.parseCsv(text);
    if (!parsed.imported) {
      csvNotice = parsed.errors.length ? parsed.errors[0] : "No events imported";
      return parsed;
    }
    var next = events.slice();
    for (var i = 0; i < parsed.events.length; i++) {
      var e = parsed.events[i];
      e.id = newId();
      next.push(e);
    }
    events = next;
    store.saveEvents(next);
    resimulate();
    var kind = parsed.kind === "results" ? "result row" : "event";
    csvNotice = "Imported " + parsed.imported + " " + kind + (parsed.imported === 1 ? "" : "s");
    if (parsed.errors.length) csvNotice += " (" + parsed.errors.length + " skipped)";
    return parsed;
  }

  function importFromPath(path) {
    importFallback = "";
    pendingImport = path;
    Qt.callLater(function () { importFile.reload(); });
  }

  function importFromDownloads() {
    importFallback = resultsCsvPath;
    pendingImport = eventsCsvPath;
    Qt.callLater(function () { importFile.reload(); });
  }

  function exportEventsToDownloads() {
    store.writeAtomic(eventsCsvPath, exportCsv(), csvWriter);
    csvNotice = "Exported events to " + eventsCsvPath;
  }

  function exportResultsToDownloads() {
    store.writeAtomic(resultsCsvPath, exportResultsCsv(), csvWriter);
    csvNotice = "Exported results to " + resultsCsvPath;
  }

  property FileView importFile: FileView {
    path: session.pendingImport
    printErrors: false
    onLoaded: {
      if (!session.pendingImport) return;
      session.importFallback = "";
      session.importCsv(text());
      session.pendingImport = "";
    }
    onLoadFailed: {
      if (!session.pendingImport) return;
      if (session.importFallback) {
        var next = session.importFallback;
        session.importFallback = "";
        session.pendingImport = next;
        reload();
        return;
      }
      session.csvNotice = "No CSV in Downloads (cashflow-events.csv or cashflow-results.csv)";
      session.pendingImport = "";
    }
  }

  property Process csvWriter: Process {
    command: ["true"]
    onExited: function (code) {
      if (code !== 0) session.csvNotice = "Could not write CSV";
    }
  }

  function wipe() {
    store.wipeAll();
    applyStore();
    confirmWipe = false;
    csvNotice = "All local data wiped";
  }

  property Connections storeEvents: Connections {
    target: session.store
    function onReadyChanged() { if (session.store.ready) session.applyStore(); }
    function onEventsChanged() { if (session.store.ready) session.applyStore(); }
    function onConfigChanged() { if (session.store.ready) session.applyStore(); }
    function onErrorChanged() { session.persistError = session.store.error; }
  }

  Component.onCompleted: if (store.ready) applyStore()
}
