import { describe, it, expect } from "vitest";
import { loadEngine } from "./loadEngine.mjs";

const {
  parseCsv,
  serializeCsv,
  serializeResultsCsv,
  filterResults,
  runSimulation,
  monthTotals,
  generateEventCashflows,
} = loadEngine();

describe("csv", () => {
  it("round-trips events including category", () => {
    const events = [
      {
        name: "Salary",
        startDate: "2026-01-01",
        endDate: "2026-12-31",
        frequency: "monthly",
        value: 5000,
        currency: "USD",
        category: "Income",
      },
      {
        name: "Rent",
        startDate: "2026-01-01",
        endDate: "",
        frequency: "monthly",
        value: -1500,
        currency: "USD",
        category: "Housing",
      },
    ];
    const text = serializeCsv(events);
    const parsed = parseCsv(text);
    expect(parsed.errors).toEqual([]);
    expect(parsed.imported).toBe(2);
    expect(parsed.events).toEqual(events);
  });

  it("defaults missing currency and category", () => {
    const parsed = parseCsv("name,startDate,endDate,frequency,value\nGym,2026-01-03,,weekly,-50\n");
    expect(parsed.errors).toEqual([]);
    expect(parsed.events[0].currency).toBe("USD");
    expect(parsed.events[0].category).toBe("");
    expect(parsed.events[0].value).toBe(-50);
  });

  it("quotes names that contain commas", () => {
    const text = serializeCsv([
      {
        name: "Salary, Acme",
        startDate: "2026-01-01",
        endDate: "",
        frequency: "monthly",
        value: 1,
        currency: "USD",
        category: "",
      },
    ]);
    const parsed = parseCsv(text);
    expect(parsed.events[0].name).toBe("Salary, Acme");
  });

  it("reports a missing header", () => {
    const parsed = parseCsv("foo,bar\n1,2\n");
    expect(parsed.imported).toBe(0);
    expect(parsed.errors[0]).toMatch(/events header|results header/);
  });
});

describe("results csv", () => {
  const fixture = `Date,Cashflow,Balance,Items
2026-09-11,0.00,0.00,
2026-09-13,-50.00,-50.00,Grossery
2026-10-10,1850.00,1650.00,Salary; Rent; Bills
`;

  it("imports non-zero rows as one-shot events and skips the zero pad", () => {
    const parsed = parseCsv(fixture);
    expect(parsed.kind).toBe("results");
    expect(parsed.errors).toEqual([]);
    expect(parsed.imported).toBe(2);
    expect(parsed.events[0]).toMatchObject({
      name: "Grossery",
      startDate: "2026-09-13",
      endDate: "2026-09-13",
      frequency: "monthly",
      value: -50,
    });
    expect(parsed.events[1]).toMatchObject({
      name: "Salary; Rent; Bills",
      startDate: "2026-10-10",
      value: 1850,
    });
  });

  it("serializes SPA columns and semicolon-separated items", () => {
    const results = [
      { date: new Date(Date.UTC(2026, 8, 11)), cashflow: 0, balance: 0, items: [] },
      { date: new Date(Date.UTC(2026, 8, 13)), cashflow: -50, balance: -50, items: ["Grossery"] },
      { date: new Date(Date.UTC(2026, 9, 10)), cashflow: 1850, balance: 1650, items: ["Salary", "Rent", "Bills"] },
    ];
    const text = serializeResultsCsv(results);
    expect(text.split("\n")[0]).toBe("Date,Cashflow,Balance,Items");
    expect(text).toContain("2026-09-13,-50.00,-50.00,Grossery");
    expect(text).toContain("2026-10-10,1850.00,1650.00,Salary; Rent; Bills");
    expect(text).toContain("2026-09-11,0.00,0.00,");
  });

  it("keeps first and last days even when cashflow is 0", () => {
    const rows = [
      { date: "2026-01-01", cashflow: 0, balance: 0, items: [] },
      { date: "2026-01-02", cashflow: 0, balance: 0, items: [] },
      { date: "2026-01-03", cashflow: 10, balance: 10, items: ["Pay"] },
      { date: "2026-01-04", cashflow: 0, balance: 10, items: [] },
    ];
    const filtered = filterResults(rows);
    expect(filtered.map(r => r.date)).toEqual(["2026-01-01", "2026-01-03", "2026-01-04"]);
  });

  it("results export of a salary/rent year matches runSimulation balances", () => {
    const events = [
      { name: "Salary", startDate: "2026-01-01", endDate: "2026-12-31", frequency: "monthly", value: 5000 },
      { name: "Rent", startDate: "2026-01-01", endDate: "2026-12-31", frequency: "monthly", value: -1500 },
    ];
    const results = runSimulation(events, 0, "2026-01-01", "2026-12-31");
    const text = serializeResultsCsv(results);
    const jan = results.find(d => d.date.getUTCMonth() === 0 && d.date.getUTCDate() === 1);
    expect(jan.balance).toBe(3500);
    expect(text).toContain("2026-01-01,3500.00,3500.00,Salary; Rent");
    expect(text).toContain("2026-12-31,0.00,42000.00,");
  });
});

describe("dashboard aggregates", () => {
  it("monthly bars are sums of daily cashflows", () => {
    const events = [
      { name: "Salary", startDate: "2026-01-01", endDate: "2026-12-31", frequency: "monthly", value: 5000 },
      { name: "Rent", startDate: "2026-01-01", endDate: "2026-12-31", frequency: "monthly", value: -1500 },
      { name: "Groceries", startDate: "2026-01-01", endDate: "2026-12-31", frequency: "monthly", value: -400 },
    ];
    const results = runSimulation(events, 0, "2026-01-01", "2026-12-31");
    const jan = monthTotals(results, 2026, 0, events, generateEventCashflows);
    expect(jan.income).toBe(5000);
    expect(jan.expense).toBe(1900);
    expect(jan.net).toBe(3100);
    const today = results.find(d => d.date.getUTCMonth() === 0 && d.date.getUTCDate() === 1);
    expect(today.balance).toBe(3100);
  });
});
