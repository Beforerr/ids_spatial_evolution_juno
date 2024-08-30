import 'files/quarto.just'
import 'files/overleaf.just'

default:
   just --list

update: update-overleaf clean update-repo publish

ensure-env:
   pixi install
   julia --project -e 'using Pkg; Pkg.develop(["Discontinuity", "Beforerr"]); Pkg.instantiate()'
   quarto add quarto-journals/agu --no-prompt

env-update-julia:
   rsync ~/projects/share/src/Discontinuity.jl notebooks/utils/

examples:
   ipython ids_example.py 'notebooks/config_examples/examples_stereo.yml'
   ipython ids_example.py 'notebooks/config_examples/examples_artemis.yml'
   ipython ids_example.py 'notebooks/config_examples/examples_wind.yml'
   # ipython notebooks/20_omni_overview.ipynb 'notebooks/omni.yml'

download:
   wget --user-agent="Mozilla/5.0" https://agupubs.onlinelibrary.wiley.com/cms/asset/8e244339-32cf-4703-9101-c1d9b4a3fa7c/jgra57047-fig-0002-m.jpg -O images/jgra57047-fig-0002-m.jpg
   wget https://raw.githubusercontent.com/Beforerr/finesst_solar_wind_discontinuities/main/figures/orbits/juno_orbit_white.pdf -O figures/juno_orbit_white.pdf
   wget https://raw.githubusercontent.com/Beforerr/finesst_solar_wind_discontinuities/main/figures/orbits/juno_orbit_white.png -O figures/juno_orbit_white.png

clean:
   find . -name '.DS_Store' -type f -delete

update-repo:
   git add .; git commit -am "update"; git push

publish-poster:
  Rscript -e 'pagedown::chrome_print("notebooks/manuscripts/.AGU23_poster.rmd")'

download-data:
   #!/usr/bin/env bash
   mkdir -p ~/data/spdf && cd ~/data/spdf
   echo {2011..2016} | xargs -n 1 -P 6 -I {} wget -nc -r -np -nH -R "index.html*" "https://spdf.gsfc.nasa.gov/pub/data/themis/thb/l2/fgm/{}/"
   echo {2011..2016} | xargs -n 1 -P 6 -I {} wget -nc -r -np -nH -R "index.html*" "https://spdf.gsfc.nasa.gov/pub/data/themis/thb/l2/mom/{}/"