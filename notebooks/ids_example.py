# Examples of discontinuities (publication plot)

# %%
import sys
import yaml

from space_analysis.ds.tplot import Config, export, process_panel

from importlib.util import find_spec
import matplotlib.pyplot as plt

if find_spec("scienceplots"):
    import scienceplots as scienceplots
    plt.style.use(["science", "nature", "notebook"])

plt.rc("savefig", dpi=300)
plt.rc('figure.subplot', wspace = 0, hspace = 0)

# %%
file_path = sys.argv[1]

# %%
config = yaml.load(open(file_path), Loader=yaml.FullLoader)
config = Config(**config)
tvars2plot = []

# %%
for p_config in config.panels:
    tvar2plot = process_panel(p_config)
    tvars2plot.append(tvar2plot)

# %%
export(tvars2plot, config)


