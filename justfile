import 'files/quarto.just'
import 'files/overleaf.just'

default:
    just --list

update: update-overleaf publish

ensure-env: install-deps clone-overleaf
    quarto add quarto-journals/agu --no-prompt
    git lfs install
    git lfs track "*.arrow"

install-deps:
    pixi install --frozen

install-julia-deps:
    #!/usr/bin/env -S julia --threads=auto --project=.
    using Pkg
    Pkg.develop([
        PackageSpec(url="https://github.com/Beforerr/Beforerr.jl"),
        PackageSpec(url="https://github.com/Beforerr/SPEDAS.jl"),
        PackageSpec(url="https://github.com/Beforerr/Discontinuity.jl"),
        PackageSpec(url="https://github.com/JuliaPlasma/PlasmaFormulary.jl"),
    ])
    Pkg.instantiate()


exec-scripts:
    python scripts/data.py
    julia --project scripts/plot.jl

render:
    quarto render presentations/grpMeeting_Zijin_2024-09.qmd --to pptx
    cp _site/presentations/grpMeeting_Zijin_2024-09.pptx presentations/_grpMeeting_Zijin_2024-09.pptx

examples:
    ipython notebooks/ids_example.py 'notebooks/config_examples/examples_stereo.yml'
    ipython notebooks/ids_example.py 'notebooks/config_examples/examples_artemis.yml'
    ipython notebooks/ids_example.py 'notebooks/config_examples/examples_wind.yml'
    # ipython notebooks/20_omni_overview.ipynb 'notebooks/omni.yml'

download:
    wget --user-agent="Mozilla/5.0" https://agupubs.onlinelibrary.wiley.com/cms/asset/8e244339-32cf-4703-9101-c1d9b4a3fa7c/jgra57047-fig-0002-m.jpg -O images/jgra57047-fig-0002-m.jpg
    wget https://raw.githubusercontent.com/Beforerr/finesst_solar_wind_discontinuities/main/figures/orbits/juno_orbit_white.pdf -O figures/juno_orbit_white.pdf
    wget https://raw.githubusercontent.com/Beforerr/finesst_solar_wind_discontinuities/main/figures/orbits/juno_orbit_white.png -O figures/juno_orbit_white.png

publish-poster:
    Rscript -e 'pagedown::chrome_print("presentations/.AGU23_poster.rmd")'

download-data:
    #!/usr/bin/env bash
    mkdir -p ~/data/spdf && cd ~/data/spdf
    echo {2011..2016} | xargs -n 1 -P 6 -I {} wget -nc -r -np -nH -R "index.html*" "https://spdf.gsfc.nasa.gov/pub/data/themis/thb/l2/fgm/{}/"
    echo {2011..2016} | xargs -n 1 -P 6 -I {} wget -nc -r -np -nH -R "index.html*" "https://spdf.gsfc.nasa.gov/pub/data/themis/thb/l2/mom/{}/"

sync-figures:
    rsync figures/wind_distribution_time.pdf overleaf/figures
    rsync figures/wind_sw_paramters.pdf overleaf/figures
    rsync figures/juno_distribution_r.pdf overleaf/figures
    