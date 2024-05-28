{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs, ... }@inputs: # @inputs let's us access the inputs anywhere in the file
    let 
      system = "x86_64-linux";
      myPkgs = nixpkgs.legacyPackages.${system}; 
      pkgList = with myPkgs;[
        python312
      ] ++
      (with myPkgs.python312Packages; [
        ipython
        django
        pandas
        numpy
      ]);
    in
    {
      devShells.x86_64-linux.default = myPkgs.mkShell {
        buildInputs = pkgList;
        shellHook = ''
          echo "You are in a ${system} shell with ${
            myPkgs.lib.concatStrings  # concatenate all strings in the list so they can be coerced to a single string
              (builtins.map(x: "\n flake: " + x) pkgList) # prepend new line to each package name 
              }."
        '';
      };
    };
}
