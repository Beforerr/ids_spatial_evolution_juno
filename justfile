update: update-overleaf clean update-repo render publish

env-install:
   micromamba env create --file environment.yml

env-update:
   micromamba install --file environment.yml

preview:
   quarto preview --no-render

render-manuscripts:
   quarto render --profile man --to html

render: render-manuscripts
   quarto render --profile web
   cp -r _manuscript _site/

publish:
   quarto publish gh-pages --no-render --no-prompt

setup-agu:
   quarto add quarto-journals/agu --no-prompt

examples:
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_stereo.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_artemis.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_wind.yml'
   # ipython notebooks/20_omni_overview.ipynb 'notebooks/omni.yml'

download:
   wget --user-agent="Mozilla/5.0" https://agupubs.onlinelibrary.wiley.com/cms/asset/8e244339-32cf-4703-9101-c1d9b4a3fa7c/jgra57047-fig-0002-m.jpg -O images/jgra57047-fig-0002-m.jpg
   wget https://raw.githubusercontent.com/Beforerr/finesst_solar_wind_discontinuities/main/figures/orbits/juno_orbit_white.pdf -O figures/juno_orbit_white.pdf
   wget https://raw.githubusercontent.com/Beforerr/finesst_solar_wind_discontinuities/main/figures/orbits/juno_orbit_white.png -O figures/juno_orbit_white.png

clean:
   rm article.{log,bbl,blg,aux} trackchanges.sty agujournal2019.cls
   find . -name '.DS_Store' -type f -delete

update-repo:
   git add .; git commit -am "update"; git push

update-overleaf: sync-overleaf
   cd overleaf; git add .; git commit -am "update"; git push

sync-overleaf:
   touch files/bibexport.bib
   quarto render --profile man --to agu-pdf
   $HOME/Library/TinyTeX/texmf-dist/scripts/bibexport/bibexport.sh -o files/bibexport.bib --nosave article.aux
   rsync _manuscript/_tex/ overleaf/ -r


publish-poster:
  Rscript -e 'pagedown::chrome_print("notebooks/manuscripts/.AGU23_poster.rmd")'

download-data:
   #!/usr/bin/env bash
   mkdir -p ~/data/spdf && cd ~/data/spdf
   echo {2011..2016} | xargs -n 1 -P 6 -I {} wget -nc -r -np -nH -R "index.html*" "https://spdf.gsfc.nasa.gov/pub/data/themis/thb/l2/fgm/{}/"
   echo {2011..2016} | xargs -n 1 -P 6 -I {} wget -nc -r -np -nH -R "index.html*" "https://spdf.gsfc.nasa.gov/pub/data/themis/thb/l2/mom/{}/"