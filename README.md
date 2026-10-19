# m1-wine-launcher

Run Windows games (Steam) on Apple Silicon Macs through Wine + Rosetta 2, with per-bottle configuration.

## Status

Stage 1: build Wine from the LGPL CrossOver sources published by CodeWeavers, in CI.

## Pipeline

`.github/workflows/build-wine.yml` (manual dispatch) builds x86_64 Wine on `macos-15-intel` and uploads
`wine-crossover-<version>-x86_64-macos.tar.xz` as an artifact. Run it from the Actions tab or:

```sh
gh workflow run build-wine.yml -f crossover_version=26.3.0
```

## Test on an M1 Mac

```sh
softwareupdate --install-rosetta --agree-to-license
mkdir wine && tar -xf wine-crossover-*.tar.xz -C wine
xattr -dr com.apple.quarantine wine
WINEPREFIX=$HOME/bottle1 wine/bin/wine winecfg
```

## Roadmap

1. Wine build (this stage)
2. Graphics backends: DXVK + MoltenVK, DXMT (D3DMetal is Apple-licensed and is not redistributed here)
3. SwiftUI bottle manager: prefixes, Windows version, DLL overrides, env vars, winetricks, backend selection
4. Steam bootstrap per bottle

## Licensing

Wine and the bundled projects are LGPL/GPL. CodeWeavers' proprietary CrossOver components are not used or reverse engineered.
