preview:
   quarto preview --no-render

publish:
   quarto publish gh-pages --no-render --no-prompt

setup-agu:
   quarto add quarto-journals/agu --no-prompt

publish-poster:
  Rscript -e 'pagedown::chrome_print("notebooks/manuscripts/.AGU23_poster.rmd")'

examples:
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_stereo.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_artemis.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_wind.yml'
   ipython notebooks/20_omni_overview.ipynb 'notebooks/omni.yml'

download:
   wget --user-agent="Mozilla/5.0" https://agupubs.onlinelibrary.wiley.com/cms/asset/8e244339-32cf-4703-9101-c1d9b4a3fa7c/jgra57047-fig-0002-m.jpg -O images/jgra57047-fig-0002-m.jpg
   wget https://raw.githubusercontent.com/Beforerr/finesst_solar_wind_discontinuities/main/figures/orbits/juno_orbit_white.pdf -O figures/juno_orbit_white.pdf
   wget https://raw.githubusercontent.com/Beforerr/finesst_solar_wind_discontinuities/main/figures/orbits/juno_orbit_white.png -O figures/juno_orbit_white.png

clean:
   rm index.{log,bbl,blg,aux}
   find . -name '.DS_Store' -type f -delete

update: update-overleaf update-repo publish

update-repo:
   git add .; git commit -am "update"; git push

update-overleaf: sync-overleaf
   cd overleaf; git add .; git commit -am "update"; git push

sync-overleaf:
   touch files/bibexport.bib
   quarto render index.qmd --to agu-pdf -M latex-clean:false
   $HOME/Library/TinyTeX/texmf-dist/scripts/bibexport/bibexport.sh -o files/bibexport.bib --nosave index.aux
   rsync _manuscript/_tex/ overleaf/ -r