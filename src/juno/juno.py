from space_analysis.missions.juno.fgm import download_data
from discontinuitypy.utils.basic import resample
from pipe import select
from fastcore.utils import mkdir
import os
import polars as pl
from intake.source.utils import reverse_formats
from datetime import datetime
from beforerr.project import datadir
from datetime import timedelta


def preprocess(
    fp,
    every=timedelta(seconds=0.125),
    dir_path=datadir() / "02_intermediate/JNO_MAG_8hz",
    update=False,
):
    fname = fp.split("/")[-1]

    output_path = f"{dir_path}/{fname}"

    if not os.path.exists(output_path) or update:
        mkdir(dir_path, parents=True, exist_ok=True)
        df = pl.scan_ipc(fp).sort("time").pipe(resample, every=every)
        df.collect().write_ipc(output_path)
    return output_path


def get_mag_paths(
    timerange: list[datetime],
    freq: float,
):
    if freq == 1:
        files = download_data()
        url_pattern = "fgm_jno_l3_{date:%Y%j}se_r1s_v01.arrow"
    if freq == 8:
        files = list(download_data(datatype="FULL") | select(preprocess))
        url_pattern = "fgm_jno_l3_{date:%Y%j}se_v01.arrow"

    dates = reverse_formats(url_pattern, [file.split("/")[-1] for file in files]).get(
        "date"
    )

    start = timerange[0].replace(tzinfo=None)
    end = timerange[1].replace(tzinfo=None)
    # filter by timerange
    return [file for file, date in zip(files, dates) if date >= start and date <= end]


def get_mag_data(
    timerange: list[datetime],
    freq: float,
):
    paths = get_mag_paths(timerange, freq)
    return pl.scan_ipc(paths).sort("time").unique("time")