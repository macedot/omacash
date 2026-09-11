# Omacash design

How a change should behave. [README.md](README.md) is install and use.

The expanded window follows `docs/ui-reference.jpeg` for layout. Colors, font, and spacing come from the live Omarchy theme (`qs.Commons` Color and Style). Do not hardcode the mockup's navy/cyan.

## Privacy

Local only. No network, no cloud, no tracking, no update ping, no FX API, no CDN, no WebEngine. CSV import/export is local files under `~/Downloads`. Data lives in:

- `~/.config/omacash/config.toml` — deliberate settings
- `~/.local/share/omacash/events.json` — recurring events
- `~/.local/state/omacash/state.json` — UI restore

Never write Hyprland, `shell.json`, or other apps' files. Uninstall does not delete user data.

## Product

A cashflow forecast that lives in the bar. The pill is compact cash-on-hand. The popover is the next 30 days and upcoming bills. The window is the dashboard from the mockup.

v1 is a forecast, not a bank. "Recent activity" and "upcoming bills" are occurrences of recurring events. Accounts, a transaction ledger, envelope budgets, and reports are sidebar stubs labeled Later.

Empty state: no demo events. Cards read zero; `n` adds the first event.

Name is **Omacash**. Default currency is USD.

## Simulation

Port of `macedot/cashflow` `runSimulation` in `ui/cashflow.js`: UTC dates, month-end clamping, signed values, one row per calendar day. Dashboard monthly bars split income and expense from occurrences, not from netted daily totals. JS lives next to QML so imports never use `..`.

## CSV

Two kinds, auto-detected by header:

- **Events** (`cashflow-events.csv`): recurring definitions. Report of the model, not a bank feed.
- **Results** (`cashflow-results.csv`): daily cashflow, running balance, and item names for the Settings period. Matches the SPA export (`Date,Cashflow,Balance,Items`, items joined with `; `, first and last day kept even when cashflow is 0).

Importing results creates one-shot events. It does not reconstruct recurrences. The results file is a report, not a second ledger.

## Keyboard

Everything the pointer reaches is a key. Chord `g` then `d/e/s/p` switches pages. `i` / `e` / `r` import and export CSV. `?` is the keys sheet. Esc closes the overlay, then the window.
