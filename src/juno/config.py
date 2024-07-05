from pydantic import Field
import polars as pl

from datetime import timedelta, datetime

from beforerr.project import datadir
from space_analysis.meta import MagDataset, PlasmaDataset
from discontinuitypy.datasets import IDsDataset
from discontinuitypy.config import IDsConfig as IDsConfigBase
from discontinuitypy.config import SpeasyIDsConfig as SpeasyIDsConfigBase

from .juno import get_mag_paths
from math import ceil


def _split_list(lst, n):
    step = ceil(len(lst) / n)
    for i in range(0, len(lst), step):
        yield lst[i : i + step]


def split_list(lst, n):
    return list(_split_list(lst, n))


tau: timedelta = timedelta(seconds=60)
timerange: list[datetime] = Field(["2011-08-25", "2016-06-30"], validate_default=True)


class IDsConfig(IDsConfigBase):
    tau: timedelta = timedelta(seconds=60)
    # ts: timedelta = timedelta(seconds=1)
    timerange: list[datetime] = timerange

    split: int = 16
    test: bool = False

    def model_post_init(self, __context):
        if self.test:
            self.timerange = [datetime(2012, 1, 1), datetime(2012, 1, 2)]
        super().model_post_init(__context)


class SpeasyIDsConfig(IDsConfig, SpeasyIDsConfigBase):
    pass


def create_juno_config(name="JNO"):
    plasma_df_path = datadir() / "03_primary/JNO_STATE_ts_3600s.parquet"
    plasma_data = pl.scan_parquet(plasma_df_path).sort("time")
    plasma_meta = PlasmaDataset(
        density_col="plasma_density", velocity_cols=["v_x", "v_y", "v_z"]
    )

    return IDsConfig(
        name=name,
        plasma_data=plasma_data,
        plasma_meta=plasma_meta,
    )


class JunoConfig(IDsConfig):
    _sparse_num = 10

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


# class WindConfig(WindMeta, SpeasyIDsConfig):
#     provider: str = "archive/local"
#     mag_meta: MagDataset = wind_mag_h4_rtn_meta
#     plasma_meta: PlasmaDataset = wind_plasma_k0_swe_meta
#     split: int = 32


class StereoConfig(IDsConfig):
    ts: timedelta = timedelta(seconds=1)

    mag_meta: MagDataset = MagDataset(
        dataset="STA_L1_MAG_RTN",
        parameters=["BFIELD"],
    )

    plasma_meta: PlasmaDataset = PlasmaDataset(
        dataset="STA_L2_PLA_1DMAX_1MIN",
        parameters=[
            "proton_number_density",
            # "V_GSM",
            "proton_temperature",
        ],  # TODO: is GSM close to RTN coordinates???
    )


class THEMISConfig(IDsConfig):
    mag_meta: MagDataset = MagDataset(
        dataset="THB_L2_FGM",
        parameters=["thb_fgl_gse"],
    )

    plasma_meta: PlasmaDataset = PlasmaDataset(
        dataset="THB_L2_MOM",
        parameters=[
            "thb_peim_densityQ",
            "thb_peim_velocity_gseQ",
        ],
    )
