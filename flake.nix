{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs, ... }@inputs: # @inputs let's us access the inputs anywhere in the file
    let 
      pkgList = with pkgs;[
        python312
      ] ++
      (with pkgs.python312Packages; [
        ipython
        django
        pandas
        numpy
      ]);
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = pkgList;
        shellHook = ''
          echo "You are in a ${system} shell with ${
            pkgs.lib.concatStrings  # concatenate all strings in the list so they can be coerced to a single string
              (builtins.map(x: "\n" + x) pkgList) # prepend new line to each package name 
              }."
        '';
      };
    };
}
