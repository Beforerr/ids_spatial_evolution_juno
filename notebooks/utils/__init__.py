import polars as pl
from beforerr.polars import pl_norm

data_dir = "../data"

PARAMETERS = ['j0_k', 'j0_k_norm',  'L_k', 'L_k_norm']    

def keep_good_fit(df: pl.DataFrame, rsquared = 0.95):
    return df.filter(pl.col('fit.stat.rsquared') > rsquared)

def load_events(
    name: str,
    ts: float,
    tau: float,
    method="derivative",
    format="arrow",
    parameters=PARAMETERS,
) -> pl.DataFrame:

    data_dir = "../data"

    match format:
        case "arrow":
            load_func = pl.scan_ipc
        case "parquet":
            load_func = pl.scan_parquet

    if method == "derivative":
        filepath = f"{data_dir}/05_reporting/events.{name}.derivative.ts_{ts:.2f}s_tau_{tau}s.{format}"
    elif method == "fit":
        filepath = (
            f"{data_dir}/05_reporting/events.{name}.ts_{ts:.2f}s_tau_{tau}s.{format}"
        )

    df = load_func(filepath)
    return (
        df.drop_nulls()
        .with_columns(
            pl.col(parameters).abs(),
            sat=pl.lit(name),
            ts=pl.lit(f"{ts}s"),
            method=pl.lit(method),
            ts_method=pl.lit(f"{ts}s {method}"),
            label=pl.lit(f"{name} {ts}s {method}"),
            index_d_diff=pl_norm("dB_x", "dB_y", "dB_z") / pl.col("b_mag"),
        )
        .collect()
    )
