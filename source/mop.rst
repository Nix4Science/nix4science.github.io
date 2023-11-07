A posteriori Nix shell
======================

.. warning::

   Very fresh paint!

So you have a non-Nix software environment that you would like to reproduce in Nix?

You can try to use third party tools such as `Devbox <https://www.jetpack.io/devbox/>`_, but generating a proper Nix Flake also seems like a decent idea.

The `Nix4Science flake <https://github.com/nix4science/n4s>`_ provides a way to generate a ``flake.nix`` from a YAML description of the desired software environments.


Imagine that you need to nixify two seperate shells.
One for your C++ code built with CMake, and the other one for some analysis in python.

You can then describe the desired environment in a YAML file such as the one below:

.. code-block:: yaml

    - shell: analysis
      packages:
        - name: python310
          version: "3.10.8"
          with_packages:
          - name: numpy
            version: "1.24.2"
          - name: matplotlib
            version: "3.7.1"
    - shell: dev
      packages:
        - name: gcc
          version: "12.3.0"
        - name: cmake
          version: "3.24.3"



* ``shell`` sets the name of the shell

* ``packages`` is a list of pairs (``name``, ``version``)

* for some packages (``python``, ``R``, ...), you can use the ``with_packages`` fields to add some packages (``numpy`` and ``matplotlib`` in the example above)

Then run ``mop``:

.. code-block:: bash

    nix run n4s#mop -- envs.yaml

``mop`` will generate a ``flake.nix`` file that **tries** to match as best as it can the desired environments.

Notes and Warnings
------------------

* ``mop`` calls `Nixhub <https://nixhub.io>`_ under the hood to retrieve the correct ``nixpkgs`` commits

* you do want to call a nix formatter on the generated ``flake.nix``!!

* for now, the ``with_packages`` supports fully ``python``, and partially ``R``

* it might require you to edit the ``flake.nix`` to fill up some ``sha256`` or ``hash``



