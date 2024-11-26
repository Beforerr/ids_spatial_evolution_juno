from pydantic import BaseModel, ConfigDict
import polars as pl

from datetime import timedelta, datetime
from pathlib import Path

from beforerr.project import datadir
from space_analysis.core import MagVariable
from space_analysis.meta import PlasmaDataset
from discontinuitypy.config import SpeasyIDsConfig, IDsConfig
from discontinuitypy.mission import WindConfigBase, ThemisConfigBase, StereoConfigBase

from .juno import get_mag_data
from . import DEFAULT_TIMERANGE, DEFAULT_TEST_TIMERANGE
from math import ceil


def _split_list(lst, n):
    step = ceil(len(lst) / n)
    for i in range(0, len(lst), step):
        yield lst[i : i + step]


def split_list(lst, n):
    return list(_split_list(lst, n))


DEFAULT_TAU = timedelta(seconds=60)
DEFAULT_TS = timedelta(seconds=1)
JNO_PLASMA_DF_PATH = datadir() / "03_primary/JNO_STATE_ts_3600s.parquet"


class Config(BaseModel):
    model_config = ConfigDict(arbitrary_types_allowed=True, extra="allow")

    tau: timedelta = DEFAULT_TAU
    timerange: list[datetime] = DEFAULT_TIMERANGE

    split: int = 16
    test: bool = False

    file_path: Path = datadir() / "05_reporting"

    def model_post_init(self, __context):
        super().model_post_init(__context)
        self.detect_kwargs = {"tau": self.tau}
        if self.test:
            self.timerange = DEFAULT_TEST_TIMERANGE
            self.split = 1


# %%
def juno_plasma_data(source=JNO_PLASMA_DF_PATH):
    v_cols = ["v_x", "v_y", "v_z"]
    B_background_cols = ["B_background_" + c for c in "xyz"]
    B_model_cols = ["model_b_" + c for c in "rtn"]
    return (
        pl.scan_parquet(source)
        .with_columns(V=pl.concat_list(*v_cols).list.to_array(3))
        .drop(v_cols + B_background_cols + B_model_cols + ["plasma_speed"])
        .sort("time")
    )


class JunoConfig(Config, IDsConfig):
    name: str = "JNO"
    ts: timedelta = DEFAULT_TS
    plasma_data: pl.DataFrame = juno_plasma_data()
    plasma_meta: PlasmaDataset = PlasmaDataset(
        density_col="plasma_density",
        velocity_cols="V",
        temperature_col="plasma_temperature",
    )

    def get_data(self):
        self.data = self.mag_df

    @property
    def mag_df(self):
        """Magnetic field data in a single dataframe"""
        freq = 1 / self.ts.total_seconds()
        return get_mag_data(self.timerange, freq)


wi_mfi_h4_brtn = MagVariable(
    dataset="WI_H4-RTN_MFI",
    parameter=["BRTN"],
    links=["https://cdaweb.gsfc.nasa.gov/misc/NotesW.html#WI_H4-RTN_MFI"],
)

wi_k0_swe_ds = PlasmaDataset(
    dataset="WI_K0_SWE", parameters=["Np", "V_GSE", "THERMAL_SPD"]
)


class WindConfig(Config, WindConfigBase, SpeasyIDsConfig):
    provider: str = "archive/local"
    mag_meta: MagVariable = wi_mfi_h4_brtn
    plasma_meta: PlasmaDataset = wi_k0_swe_ds


class StereoConfig(Config, StereoConfigBase, SpeasyIDsConfig):
    pass


class THEMISConfig(ThemisConfigBase, SpeasyIDsConfig):
    pass


# %%
