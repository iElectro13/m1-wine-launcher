# m1-wine-launcher

Bottle manager for running Windows games (Steam) on Apple Silicon Macs through Wine + Rosetta 2, with per-bottle configuration.

## Approach

- Wine is not built here. Prebuilt x86_64 Wine from [Gcenx/macOS_Wine_builds](https://github.com/Gcenx/macOS_Wine_builds) runs under Rosetta 2.
- A Swift core package manages bottles (Wine prefixes): Windows version, graphics backend, environment variables, DLL overrides.
- A SwiftUI app sits on top of the core.
- Recipes install software into a bottle (Steam first); a YAML format is planned.

## Run on a Mac

Requires macOS 14+ on Apple Silicon and Rosetta 2 (`softwareupdate --install-rosetta --agree-to-license`).

1. Download the build from the latest green `ci` run: `gh run download <run-id> -n WineLauncher-macOS-arm64`, then unzip it.
2. The app is ad-hoc signed, so macOS quarantines it. Clear that once: `xattr -cr WineLauncher.app`, then open it.
3. On first launch the app downloads Wine (about 190 MB) and installs it under `~/Library/Application Support/WineLauncher`.
4. Create a bottle, open its **Programs** tab and click **Install Steam**.

The app is built and checked only by CI so far; expect rough edges.

## Roadmap

- [x] Core: `Bottle`, `BottleStore`, `RuntimeInstaller`, `WineCommandBuilder`, `BottleManager`, `Doctor`
- [x] Graphics backend: DXVK
- [x] Recipes engine and Steam recipe (Swift values, not YAML yet)
- [x] SwiftUI app: runtime setup, bottles, settings, programs, logs, diagnostics
- [ ] Verify the app on real hardware and fix what breaks
- [ ] DXMT backend (D3DMetal is Apple-licensed and is not redistributed here)
- [ ] Declarative YAML recipes
- [ ] Signed and notarized releases

## Licensing

Wine and the bundled projects are LGPL/GPL. No proprietary CrossOver code or assets are used.
