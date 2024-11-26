# %%
from rich import print
from juno.config import JunoConfig, WindConfig, StereoConfig

from speasy.core.requests_scheduling.request_dispatch import init_archive

init_archive()

# %%
for c in [JunoConfig, WindConfig, StereoConfig]:
    c().produce_or_load()

# Different time windows
taus = range(60, 10, -10)

for tau in taus:
    JunoConfig(tau=tau).produce_or_load()
# %%
# Test
w_conf = WindConfig(test=True)
w_conf.get_data()
w_conf.plasma_data
print(w_conf)
# %%
