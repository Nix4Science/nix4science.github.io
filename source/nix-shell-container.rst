Nix Shell Container
===================

We focus here on the shells produced by the ``mkShell`` function.

The shell environments produced are not isolated from the environment of your machine.

Consider the following ``flake.nix``:

.. code-block:: bash

    {
      inputs.nixpkgs.url = "github:nixos/nixpkgs/23.05";
      outputs = { self, nixpkgs }:
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs { inherit system; };
        in {
          devShells.${system}.default = pkgs.mkShell {
            packages = [ pkgs.gcc ];
          };
        };
    }


When entering the shell (``nix develop``), the environment will contain the disired ``gcc`` on top of your current environment.

One way to isolate the shell would be to create a Docker container, build it, load it, and run it.

But this is cumbersome.

A better way would be to isolate the shell without any extra dependency.

The `Nix4Science flake <https://github.com/nix4science/utils>`_ provides a way to do so by using the Linux `user namespace` feature.

First, let's import the flake as ``n4s``.
This flake provides a replacement for the ``mkShell`` fonction: ``n4s.lib.${system}.mkShell``.
By default it behaves like ``mkShell``, but we can activate the containerization of the shell by setting the ``containerize`` parameter:


.. code-block:: bash

    {
      inputs.nixpkgs.url = "github:nixos/nixpkgs/23.05";
      inputs.n4s.url = "github:nix4science/utils";
      outputs = { self, nixpkgs, n4s }:
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs { inherit system; };
        in {
          devShells.${system}.default = n4s.lib.${system}.mkShell {
            containerize = true;
            packages = [ pkgs.gcc ];
          };
        };
    }


Now, calling ``nix develop`` will start the shell in a containerized environment! 

However, this method cannot accept to run command inside the container like ``nix develop --command gcc --version``.
This is because of the way Nix manages the ``--command`` flag.

Our workaround is the following:

.. code-block:: bash

    {
      inputs.nixpkgs.url = "github:nixos/nixpkgs/23.05";
      inputs.n4s.url = "github:nix4science/utils";
      outputs = { self, nixpkgs, n4s }:
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs { inherit system; };
        in {
          packages.${system}.default = n4s.lib.${system}.mkShellContainer {
            packages = [ pkgs.gcc ];
          };
        };
    }


Now, instead of running ``nix develop`` you have to run ``nix run``.
To pass a command, simply append the command after ``--``:


.. code-block:: bash

   nix run . -- gcc --version
