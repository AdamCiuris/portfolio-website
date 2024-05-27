{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { self, nixpkgs, ... }@inputs: # @inputs let's us access the inputs anywhere in the file
    let 
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [ 
          python312
          ] ++ (with pkgs.python312Packages; [
            ipython
            django
            pandas
            numpy
          ]);
          shellHook = ''
            echo "my first shell hook"
          '';
      };
    };
}
