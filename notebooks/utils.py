def get_and_process_data(
    mag_dataset, mag_parameters, plasma_dataset, plasma_parameters, timerange, tau, ts,
    provider = 'archive/local'
):
    # define variables
    mag_vars = Variables(
        provider = provider,
        dataset=mag_dataset,
        parameters=mag_parameters,
        timerange=timerange,
    ).retrieve_data()

    plasma_vars = Variables(
        provider = provider,
        dataset=plasma_dataset,
        parameters=plasma_parameters,
        timerange=timerange,
    ).retrieve_data()

    # get column names
    bcols = mag_vars.data[0].columns
    density_col = plasma_vars.data[0].columns[0]
    vec_cols = plasma_vars.data[1].columns
    temperature_col = plasma_vars.data[2].columns[0]

    # get data
    mag_data = mag_vars.to_polars()
    plasma_data = (
        plasma_vars.to_polars()
        .with_columns(plasma_speed=pl_norm(vec_cols))
        .rename({density_col: "plasma_density"})
    )
    # process temperature data
    if plasma_vars.data[2].unit == "km/s":
        plasma_data = plasma_data.pipe(df_thermal_spd2temp, temperature_col)
    else:
        plasma_data = plasma_data.rename({temperature_col: "plasma_temperature"})

    return IDsDataset(
        mag_data=mag_data.pipe(resample, every=ts),
        plasma_data=plasma_data,
        tau=tau,
        ts=ts,
        bcols=bcols,
        vec_cols=vec_cols,
        density_col="plasma_density",
        speed_col="plasma_speed",
        temperature_col="plasma_temperature",
    ).find_events(return_best_fit=False).update_candidates_with_plasma_data()