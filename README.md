# m1-wine-launcher

Bottle manager for running Windows games (Steam) on Apple Silicon Macs through Wine + Rosetta 2, with per-bottle configuration.

## Approach

- Wine is not built here. Prebuilt x86_64 Wine from [Gcenx/macOS_Wine_builds](https://github.com/Gcenx/macOS_Wine_builds) runs under Rosetta 2.
- A Swift core package manages bottles (Wine prefixes): Windows version, graphics backend, environment variables, DLL overrides.
- A SwiftUI app sits on top of the core.
- Declarative YAML recipes install software into a bottle (Steam first).

## Roadmap

1. Core: `Bottle`, `WineRunner`, `BottleStore`, `RuntimeInstaller`
2. Graphics backends: DXVK + MoltenVK, DXMT (D3DMetal is Apple-licensed and is not redistributed here)
3. Recipes engine and Steam recipe
4. SwiftUI app

## Licensing

Wine and the bundled projects are LGPL/GPL. No proprietary CrossOver code or assets are used.
