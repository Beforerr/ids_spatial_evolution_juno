from pydantic import Field
from pydantic import BaseModel, ConfigDict
import polars as pl

from datetime import timedelta, datetime
from pathlib import Path

from beforerr.project import datadir
from space_analysis.meta import PlasmaDataset
from discontinuitypy.datasets import IDsDataset
from discontinuitypy.config import SpeasyIDsConfig
from discontinuitypy.mission import WindConfigBase, ThemisConfigBase, StereoConfigBase

from .juno import get_mag_paths
from math import ceil


def _split_list(lst, n):
    step = ceil(len(lst) / n)
    for i in range(0, len(lst), step):
        yield lst[i : i + step]


def split_list(lst, n):
    return list(_split_list(lst, n))


DEFAULT_TAU = timedelta(seconds=60)
DEFAULT_TS = timedelta(seconds=1)
DEFAULT_TIMERANGE = Field(["2011-08-25", "2016-06-30"], validate_default=True)
DEFAULT_TEST_TIMERANGE = Field(["2012-01-01", "2012-01-02"], validate_default=True)
JNO_PLASMA_DF_PATH = datadir() / "03_primary/JNO_STATE_ts_3600s.parquet"


class Config(BaseModel):
    model_config = ConfigDict(arbitrary_types_allowed=True, extra="allow")

    tau: timedelta = DEFAULT_TAU
    ts: timedelta = DEFAULT_TS
    timerange: list[datetime] = DEFAULT_TIMERANGE

    data_dir: Path = datadir() / "05_reporting"

    split: int = 16
    test: bool = False


class JunoConfig(Config, IDsDataset):
    _sparse_num = 10
    name: str = "JNO"
    plasma_data: pl.DataFrame = pl.scan_parquet(JNO_PLASMA_DF_PATH).sort("time")
    plasma_meta: PlasmaDataset = PlasmaDataset(
        density_col="plasma_density", velocity_cols=["v_x", "v_y", "v_z"]
    )

    def model_post_init(self, __context):
        self.data = self.mag_df

    @property
    def mag_df(self):
        """Magnetic field data in a single dataframe"""
        return pl.scan_ipc(self.mag_paths).sort("time").unique("time")

    @property
    def mag_dfs(self):
        s_paths = split_list(self.mag_paths, self.split)
        return [pl.scan_ipc(paths).sort("time").unique("time") for paths in s_paths]

    @property
    def mag_paths(self):
        freq = 1 / self.ts.total_seconds()
        return get_mag_paths(self.timerange, freq)

    def _get_and_process_data(self, **kwargs):
        for mag_df in self.mag_dfs:
            yield (
                IDsDataset(
                    mag_data=mag_df,
                    plasma_data=self.plasma_data,
                    plasma_meta=self.plasma_meta,
                    tau=self.tau,
                    ts=self.ts,
                    method=self.method,
                )
                .find_events(
                    return_best_fit=False, sparse_num=self._sparse_num, **kwargs
                )
                .update_candidates_with_plasma_data()
                .events
            )


class WindConfig(Config, WindConfigBase, SpeasyIDsConfig):
    provider: str = "archive/local"
    # mag_meta: MagDataset = wind_mag_h4_rtn_meta
    # plasma_meta: PlasmaDataset = wind_plasma_k0_swe_meta


class StereoConfig(Config, StereoConfigBase, SpeasyIDsConfig):
    pass


class THEMISConfig(ThemisConfigBase, SpeasyIDsConfig):
    pass
