import polars as pl
import pandas as pd
from discontinuitypy.datasets import IDsDataset
from discontinuitypy.utils.basic import filter_tranges_df
from . import AVG_SATS

def link_coord2dim(df: pl.DataFrame, dim="time", coord: str = "radial_distance"):
    """Link the coord to a dimension across different subgroups

    Note: this idea is borrowed from the `xarray.DataArray.coords`.
    """
    base_df = df.filter(sat="JNO").select(dim, coord).rename({coord: f"ref_{coord}"})
    return df.join(base_df, on=dim, how="left")

def filter_tranges_ds(ds: IDsDataset, tranges: tuple[list, list]):
    """Filter a dataset by a list of time ranges"""
    new_ds = ds.copy()
    new_ds.candidates = filter_tranges_df(ds.candidates, tranges)
    new_ds.data = filter_tranges_df(ds.data.collect(), tranges).lazy()
    
    return new_ds

# %% ../../notebooks/utils/02_analysis_utils.ipynb 6
def filter_before_jupiter(df: pl.DataFrame):
    return df.filter(pl.col("time") < pd.Timestamp("2016-05-01"))

def n2_normalize(df: pl.DataFrame, cols, avg_sats: list = AVG_SATS):
    exprs = [pl.col(f"{col}").mean().alias(f"{col}_n2_factor") for col in cols]

    avg_df = df.filter(pl.col("sat").is_in(avg_sats)).group_by("time").agg(exprs)

    exprs = [
        (pl.col(f"{col}") / pl.col(f"{col}_n2_factor")).alias(f"{col}_n2")
        for col in cols
    ]

    return df.join(avg_df, on="time").with_columns(exprs)
