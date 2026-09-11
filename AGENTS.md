# AGENTS.md

Omacash — Omarchy plugin. Local-first cashflow forecast. No network.

## Commands

```
npm test
bash scripts/check.sh
bash scripts/plugin-link.sh
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" ui/*.qml
```

## Rules

- Keep simulation in `ui/*.js` as `.pragma library` ES5 (same folder as QML so imports have no `..`). Port behavior from macedot/cashflow; do not wrap the SPA.
- Zero network in `ui/`. `scripts/check.sh` greps for it.
- Theme from `qs.Commons` Color/Style. Do not hardcode the mockup palette.
- Do not write Hyprland or `shell.json`.
- Events are user data (`events.json`), not config.
- Sidebar stubs for Accounts/Transactions/Budget/Bills/Reports stay disabled.
