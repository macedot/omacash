import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

export function loadEngine() {
  const files = [
    "ui/cashflow.js",
    "ui/dateInput.js",
    "ui/eventSort.js",
    "ui/csv.js",
    "ui/toml.js",
    "ui/stats.js",
  ];
  const context = {
    console,
    Date,
    Math,
    Number,
    String,
    Array,
    Object,
    RegExp,
    JSON,
    Error,
    isNaN,
    isFinite,
    parseInt,
    parseFloat,
    undefined,
  };
  vm.createContext(context);
  for (const rel of files) {
    const src = fs
      .readFileSync(path.join(root, rel), "utf8")
      .replace(/^\s*\.pragma library\s*\n/, "");
    vm.runInContext(src, context, { filename: rel });
  }
  return context;
}
