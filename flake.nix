{
  description = "Degoog packaged for Nix";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    degoog = {
      type = "github";
      owner = "degoog-org";
      repo = "degoog";
      ref = "1.0.0";
      flake = false;
    };
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    ...
  } @ inputs:
    {
      nixosModules.default = import ./modules/nixos.nix {flake = self;};

      overlays.degoog = final: _prev: {
        degoog = self.packages."${final.system}".default;
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = let
        bun2nix = inputs.bun2nix.packages.${system}.default;
        package = pkgs.callPackage ./pkgs/degoog.nix {inherit bun2nix inputs;};
      in {
        degoog = package;
        default = package;
      };
    });
}
