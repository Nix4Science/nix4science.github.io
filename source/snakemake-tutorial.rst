Snakemake Tutorial
==================

In this tutorial, we look at how to integrate Nix and Snakemake together to produce a fully reproducible research article.

Requirements
------------

* Nix installed with Nix Flakes activated

* Basic knowledge of Python, Nix, and LaTeX



Step 1: Download the template
-----------------------------

The starting point of the tutorial is available through a Nix template.

.. code-block:: bash

   nix flake new -t github:nix4science/n4s#tuto tuto

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


In the ``expe`` folder there is a single ``run.py`` script, which represents the experiments part of a paper.
This simple scripts generates a csv file containing the trajectory of a object thrown with an inital speed and an initial angle:

.. code-block:: none


   $ nix develop .#pyshell --command python3 expe/run.py --help
   usage: run.py [-h] --output OUTPUT --v0 V0 --alpha ALPHA

   Very complex simulation

   options:
     -h, --help            show this help message and exit
     --output OUTPUT, -o OUTPUT
                           output file
     --v0 V0               initial speed
     --alpha ALPHA         angle in *degree*

Let's now take a look at the ``Snakefile``.
The main tool of a ``Snakefile`` is the ``rule``.

.. code-block:: none

    ALPHAs = [10, 20, 30, 40, 45, 50, 60, 70, 80]
    V0s = [0.5, 1]

    FIGS_SCRIPTS = {
        "alpha": "analysis/alpha.R",
        "v0": "analysis/v0.R"
    }

    FIGS = list(map(lambda f: f"paper/figs/{f}.pdf", FIGS_SCRIPTS.keys()))

    rule all:
        input:
            "paper/main.pdf"

    rule paper:
        input:
            main="paper/main.tex",
            figs=FIGS
        output:
            "paper/main.pdf"
        shell:
            "nix develop .#texshell --command rubber -d --into paper/ {input.main}"

    rule run_experiments:
        input:
            script="expe/run.py",
        output:
            "data/result_v0_{v0}_alpha_{alpha}.csv"
        shell:
            "nix develop .#pyshell --command python3 {input.script} --output {output} --v0 {wildcards.v0} --alpha {wildcards.alpha}"

    rule plot_results:
        input:
            script=lambda wildcards: FIGS_SCRIPTS[wildcards.name],
            files=expand(["data/result_v0_{v0}_alpha_{alpha}.csv"], v0=V0s, alpha=ALPHAs)
        output:
            "paper/figs/{name}.pdf"
        shell:
            "nix develop .#rshell --command Rscript {input.script} {input.files} {output}"


The default ``rule`` is called ``all``.
In our example, there is a single input: the pdf of the paper.
If all the inputs of the rule do not exist, Snakemake will go through all the rules and check the ``output`` fields to see how it can generate the missing files.
Here, the rule ``paper`` generates the missing file of the rule ``all``.
Snakemake will then check that the ``input`` of the ``paper`` rule are available to execute the rule, otherwise Snakemake will go through all the rules to check how to generate the missing files, etc.

Let us focus on the ``run_experiments`` rule:

.. code-block:: none

    rule run_experiments:
        input:
            script="expe/run.py",
        output:
            "data/result_v0_{v0}_alpha_{alpha}.csv"
        shell:
            "nix develop .#pyshell --command python3 {input.script} --output {output} --v0 {wildcards.v0} --alpha {wildcards.alpha}"


In this rule, there is only a single input: the experiment script, and it generate a single output: the csv file.
You can see that there are a lot of curly braces (``{}``) there.
These curly braces can be seen as the Python ``f string``.
Ok, but in the ``output`` field there are ``v0`` and ``alpha``: where are they defined?
That's the beauty: nowhere.
A rule can be seen as a function that produces the output.
The ``v0`` and ``alpha`` variables are called ``wildcards``, and the values of those variables can be accessed with ``wildcards.v0`` and ``wildcards.alpha`` (see field ``shell`` of the rule).
So when Snakemake will need to generate the file ``data/result_v0_1_alpha_45.csv``, the filename will match the rule ``run_experiments``, and the values of the wildcards will be extracted.
Snakemake will finally run the ``shell`` command with the values of the wildcards: ``nix develop .#pyshell --command python3 expe/run.py --output data/result_v0_1_alpha_45.csv --v0 1 --alpha 45``.

One important function provided by Snakemake is the ``expand`` function (used in the rule ``plot_results``).
This function generates the cartesian product of all the parameters.
In our case, we use it to run simulations with all the pairs of parameters ``(v0, alpha)`` desired.

.. warning:: TODO: dag


Step 3: Run Snakemake
---------------------

It is now time to run Snakemake.
Snakemake is available in the default Nix shell:

.. code-block:: shell-session

   nix develop

We need to give to Snakemake the number of cores that it can use in parallel (``-c`` option).

.. code-block:: shell-session

   snakemake -c 4

After it completed, you should have a folder ``data`` with all the produced csv, the pdf of the paper in the ``paper`` folder, with the generated figures under ``paper/figs``.

You can try to change some parameters in the ``Snakefile``, or in the text of the paper, and rerun ``snakemake``, it will detect the changes and rerun only the necessaty rules.


Step 4: Add a new dimension
---------------------------

Now it is your turn!

Your mission for this step is to add another dimension to the experiments.
For now, we are simulating the trajectory of an object **on earth**.
But we would like to simulate trajectories on mars and on the moon.

This means that the gravitational force should be changed in the simulator depending on the planet.

.. admonition:: Your turn

   Modify the ``expe/run.py`` so it is possible to choose the planet via the command line, and change the gravitaional force accordingly.


**Pop quizz**: Do you think Snakemake will regenerate all the previously generated files even though we only modified the CLI?


Now that the experiment script can take into account different planet, let's tell Snakemake how to use it.

.. admonition:: Your turn

   Modify the ``Snakefile`` to generate the simulation results for the different planets (earth, moon, mars).


Step 5: Add a new figure
------------------------

With this new data, we can generate more interesting plots!
The script ``analysis/multi_planets.R`` generates a plot of the different of trajectories for the same initial conditions on different planets.

.. admonition:: Your turn

   Modify the ``Snakefile`` to generate the new plot from the ``analysis/multi_planets.R`` script.

Now that the plot has been generated, we can add it to the paper!

.. admonition:: Your turn

   Add this new plot to the latex paper.


You can new run ``snakemake``, and it should produce the paper with the new figure!


Step 6: Add a new rule
----------------------

For now you modified existing rules, it is time to create a rule of your own!

You might have notice, but all the ``R`` scripts actually read all the csv everytime, which takes time.
What would be better is to generate a single csv with all the data and then give this single csv to the different analysis scripts.

The script ``analysis/merge_csv.R`` takes all the csv files and the name of the resulting new csv file which contains the merged data.

.. admonition:: Your turn

   Create a new rule in the ``Snakefile`` to generate this new merged csv.


.. tip::

    You can put the name of the new csv in the ``input`` field of the ``all`` rule to debug.

Now that we have a single csv file to give to the plotting scripts, we can update the ``Snakefile`` to use it.

.. admonition:: Your turn

   Modify the ``plot_results`` rule to use the new csv file.

Step 7: Don't forget Nix!
-------------------------

There is a reproducibility problem in our ``Snakefile``...

What happens if we decided to update the ``flake.nix``?
For example, using a new version of ``nixpkgs``?

As there is no mention of ``flake.nix`` and ``flake.lock`` in the ``Snakefile``, any changes in the environment will not be detected and might leave some incoherency in the produced data (*e.g.,* part of the data generated with one software environment, and another part with a different one).

.. admonition:: Your turn

   Update the ``Snakefile`` to take into account the Nix files (``flake.nix`` and ``flake.lock``).

Step 8: Reducing the verbosity of Nix
-------------------------------------

As Snakemake does not support Nix (yet), we have to prefix the ``shell`` rules with ``nix develop .#shell --command``, which is quite verbose.

At Nix4Science, we propose a modified version of Snakemake to ease the usage of Nix in Snakemake.

To use it we'll need to ask the ``flake.nix`` to use the modified one instead of the official one.

.. admonition:: Your turn

   Add a new ``input`` called ``n4s`` to the ``flake.nix`` at the address ``github:nix4science/n4s``.

.. tip::

    Don't forget to pass it in the parameters of the ``output`` function.

.. admonition:: Your turn

   Replace the classical ``snakemake`` with the n4s one (``n4s.packages.${system}.snakemake``)

This modified version of Snakemake introduces a new field in the definition of a ``rule``: the ``nix_flake``.

For example, for the ``paper`` rule, we can use this new field as follows:

.. code-block:: none

    rule paper:
        input:
            main="paper/main.tex",
            figs=FIGS
        output:
            "paper/main.pdf"
        nix_flake: ".#texshell"
        shell:
            "rubber -d --into paper/ {input.main}"

Under the hood, the modified Snakemake will call ``nix develop`` with the flake given in ``nix_flake``: nothing really fancy.


.. admonition:: Your turn

   Update the ``Snakefile`` to use the ``nix_flake`` field and remove the direct call to ``nix develop``.


.. warning:: TODO: a word on the wrapper


Conclusion
----------

In this tutorial, we learned how to use Snakemake, and how to integrate the use of Nix to have a fully reproducible generation of a scientific paper.

We only scratched the surface of that Snakemake can do, and I invite you to explore their documentation!

