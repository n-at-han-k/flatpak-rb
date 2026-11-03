{
  description = "flatpak — Ruby bindings";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    mine.url = "github:n-at-han-k/flake.nix";
    mine.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, mine, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = mine.lib.${system};

        gemspecFiles = pkgs.runCommand "flatpak-gemspec" { } ''
          mkdir -p $out/lib/flatpak
          cp ${./flatpak.gemspec}         $out/flatpak.gemspec
          cp ${./lib/flatpak/version.rb}  $out/lib/flatpak/version.rb
        '';

        gems = pkgs.bundlerEnv {
          name = "flatpak-gems";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = import ./gemset.nix;
          extraConfigPaths = [ "${gemspecFiles}/." ];
        };

        # The namespaces the loader needs at require time: Flatpak itself, and
        # whatever Flatpak-1.0.typelib declares as a dependency, which the loader
        # resolves transitively. Nearly every GNOME typelib needs Gio-2.0.
        #
        # `makeSearchPath` would take each package's *first* output, which
        # carries no typelibs in either case here -- `pkgs.flatpak`'s first
        # output is `man` and glib's is `bin`. Hence the explicit `.out`. That
        # trap cost real time twice, and it is why this is a `map` and not a
        # plain list of packages.
        typelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0"
          (map (drv: drv.out or drv) [ pkgs.flatpak pkgs.glib ]);
      in
      {
        devShells.default = lib.mkRubyShell {
          buildInputs = with pkgs; [
            gems
            gems.wrappedRuby

            flatpak

            skywalking-eyes
          ];

          shellHook = /* bash */ ''
            export GI_TYPELIB_PATH="${typelibPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"

            export BUNDLE_GEMFILE="$PWD/Gemfile"
            export BUNDLE_FROZEN=false

            export LANG="''${LANG:-C.UTF-8}"
            export LC_ALL="''${LC_ALL:-$LANG}"

            export RUBYLIB="$PWD/lib''${RUBYLIB:+:$RUBYLIB}"
          '';
        };
      }
    );
}
