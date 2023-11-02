Snakemake Tutorial
==================

In this tutorial, we show how to integrate Nix and Snakemake together to produce a fully reproducible research article.


Step 1: Download the template
-----------------------------

The starting point of the tutorial is available through a Nix template.

.. code-block:: bash

   nix flake new -t github:nix4science/utils#tuto tuto

The template should now be in the ``tuto`` folder.

Step 2: Explore the repo
------------------------

You can explore what is in the folder:

* ``flake.nix`` and ``flake.lock`` to manage the software environments

* ``expe`` folder for the experiment scripts

* ``analysis`` folder for the scripts working on the data produced by the experiments

* ``paper`` folder for the sources of the LaTeX file that will be our paper

* and finally, the ``workflow`` folder to manage the files related to Snakemake


By running:

.. code-block:: bash

   nix flake show

you will see that there are several shell environments for the different stages of our workflow:

* ``pyshell``: a Python shell for the experiments

* ``rshell``: a R shell for the data analysis

* ``texshell``: a shell with LaTeX for generating the paper

* ``default``: a shell with only Snakemake




