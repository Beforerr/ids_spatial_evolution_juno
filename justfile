preview:
   quarto preview --no-render

publish:
   quarto publish gh-pages --no-render --no-prompt

publish-agu:
   quarto add quarto-journals/agu --no-prompt

prepare:
   wget --user-agent="Mozilla/5.0" https://agupubs.onlinelibrary.wiley.com/cms/asset/8e244339-32cf-4703-9101-c1d9b4a3fa7c/jgra57047-fig-0002-m.jpg -O images/jgra57047-fig-0002-m.jpg

examples:
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_psp.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_stereo.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_artemis.yml'

clean:
   find . -name '.DS_Store' -type f -delete

process-bib:
   quarto render index.qmd --to latex -M cite-method:natbib -M bibliography:files/bibliography/references.bib