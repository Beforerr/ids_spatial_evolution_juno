preview:
   quarto preview

publish:
   quarto publish gh-pages --no-render --no-prompt

examples:
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_psp.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_stereo.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_artemis.yml'

export:
   quarto pandoc comps/_03_osdmp.qmd -o overleaf/comps/_03_osdmp.tex
   quarto pandoc comps/_09_budget.qmd -o overleaf/comps/_09_budget.tex