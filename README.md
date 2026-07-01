# Degoog.nix

[Degoog](https://github.com/degoog-org/degoog) is a promising open source search engine result aggregator. This flake makes it compatible with the Nix/NixOS ecosystem so that it can easily be deployed to your personal machines.

## Installation

### With flakes

Add the following into the desired `flake.nix` file.

```nix
{
    inputs.degoog.url = "github:guusvanmeerveld/degoog.nix";
}
```

## Usage

```nix
{
    imports = [inputs.degoog.nixosModules.default];

    services.degoog = {
        enable = true;

        port = 8080;
        enableWizard = true;
        environmentFile = "/secrets/degoog/environmentFile";
    }
}
```
