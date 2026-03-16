# nix2flatpak examples

These examples illustrate how to turn nixpkgs packages into Flatpak bundles
while minimizing unnecessary Nix store dependencies. Each package is built
against a Flatpak runtime (KDE or GNOME), and the build pipeline deduplicates
libraries already provided by the runtime — shipping only the delta. Optional
heavyweight dependencies like QtWebEngine and OpenCV are disabled where possible,
matching what official Flatpak maintainers do.

## GNOME Calculator

```sh
flatpak install --user $(nix build .#gnome-calculator --no-link --print-out-paths)/*.flatpak
```

## KCalc (KDE calculator)

```sh
flatpak install --user $(nix build .#kcalc --no-link --print-out-paths)/*.flatpak
```

## NeoChat (KDE Matrix client)

```sh
flatpak install --user $(nix build .#neochat --no-link --print-out-paths)/*.flatpak
```

## Signal Desktop (Electron)

```sh
flatpak install --user $(nix build .#signal-desktop --no-link --print-out-paths)/*.flatpak
```

## Processing (Java creative coding IDE)

```sh
flatpak install --user $(nix build .#processing --no-link --print-out-paths)/*.flatpak
```

## Dolphin (emulator)

```sh
flatpak install --user $(nix build .#dolphin-emu --no-link --print-out-paths)/*.flatpak
```

## Bundle sizes

Here's a table comparing the Flatpak bundle sizes to the original application sizes and their Nix closure. The latter includes all the dependencies from the Nix store that would normally need to be distributed without relinking:

| **Application**  | **Nix Main Package** | **Nix Closure** | **Flatpak Bundle** |
| ---------------- | -------------------: | --------------: | -----------------: |
| GNOME Calculator |               12 MiB |         1.0 GiB |            1.7 MiB |
| KCalc            |              3.7 MiB |         1.6 GiB |             15 MiB |
| NeoChat          |               20 MiB |         1.8 GiB |             46 MiB |
| Signal Desktop   |              153 MiB |         1.6 GiB |            148 MiB |
| Processing       |              234 MiB |         1.6 GiB |            446 MiB |
| Dolphin          |               81 MiB |         1.3 GiB |             42 MiB |
