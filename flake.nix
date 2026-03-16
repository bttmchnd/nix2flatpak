{
  description = "nix2flatpak — convert Nix packages into Flatpak images using proper runtimes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Patch OSTree to use multithreaded LZMA for static delta compression.
        # Upstream uses single-threaded lzma_easy_encoder at level 8 (since 2014).
        # lzma_stream_encoder_mt is deterministic (fixed block boundaries), so
        # this does not break Nix reproducibility.
        ostree-fast = pkgs.ostree.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace src/libostree/ostree-lzma-compressor.c \
              --replace-fail \
                'res = lzma_easy_encoder (&self->lstream, 8, LZMA_CHECK_CRC64);' \
                '{ lzma_mt mt_opts = { .flags = 0, .threads = lzma_cputhreads(), .block_size = 4 * 1024 * 1024, .timeout = 0, .preset = 8, .check = LZMA_CHECK_CRC64 }; if (mt_opts.threads == 0) mt_opts.threads = 1; res = lzma_stream_encoder_mt(&self->lstream, &mt_opts); }'
          '';
        });

        nix2flatpak-scripts = pkgs.rustPlatform.buildRustPackage {
          pname = "nix2flatpak-scripts";
          version = "0.1.0";
          src = pkgs.lib.fileset.toSource {
            root = ./.;
            fileset = pkgs.lib.fileset.unions [
              ./Cargo.toml
              ./Cargo.lock
              ./src
            ];
          };
          cargoLock.lockFile = ./Cargo.lock;
        };

        # Rebuild flatpak against patched ostree so build-bundle uses MT LZMA
        flatpak-fast = pkgs.flatpak.override { ostree = ostree-fast; };

        mkFlatpak = pkgs.callPackage ./lib/mkFlatpak.nix {
          inherit nix2flatpak-scripts;
          inherit (pkgs) patchelf file;
          ostree = ostree-fast;
          flatpak = flatpak-fast;
          runtimesDir = ./runtimes;
        };

      in {
        lib = {
          inherit mkFlatpak;
        };

        packages = {
          inherit nix2flatpak-scripts;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.cargo
            pkgs.rustc
            pkgs.patchelf
            pkgs.ostree
            pkgs.flatpak
            pkgs.file
          ];
        };
      }
    ) // {
      # Non-system-specific outputs
      overlays = {
        # Placeholder — populated once runtime indexes are generated
        # org_kde_Platform_6_8 = import ./lib/overlays.nix { ... };
      };
    };
}
