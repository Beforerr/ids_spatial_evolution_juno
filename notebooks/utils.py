from pydantic import constr, BaseModel, root_validator
from datetime import datetime, date
from pytplot import tplot, get_data

from xarray import DataArray

class TplotConfig(BaseModel):
    tvar: str = None
    trans: list[str] = None
    
class ProcessConfig(BaseModel):
    tvar: str = None
    trans: list[str] = list()


class PanelConfig(BaseModel):

    timerange: list[datetime | date] = None
    
    id: str = None
    name: str = None
    units: str = None
    
    satellite: constr(to_lower=True)
    instrument: constr(to_lower=True)
    datatype: str = None
    probe: str = None
    
    process: ProcessConfig = None
    tplot: TplotConfig = None


class OutputConfig(BaseModel):
    path : str = None
    filename: str = None
    
    formats: list[str] = list()
    display: bool = False


class Config(BaseModel):
    panels: list[PanelConfig]
    timerange: list[datetime | date] = None
    output: OutputConfig = None
    backend: str = None
    
    @root_validator(pre=True)
    def set_default_timerange(cls, values):
        timerange = values.get('timerange', None)
        panels = values.get('panels', [])
        
        if timerange:
            for panel in panels:
                if not panel.get('timerange'):
                    panel['timerange'] = timerange
        return values

class GraphicalConfig(BaseModel):
    ylabel: str = None
    


def export(config: OutputConfig, tvars2plot):
    path = config.path
    if config.display:
        tplot(tvars2plot)
    if "png" in config.formats:
        tplot(tvars2plot, save_png=path, display=False)
    if "pdf" in config.formats:
        tplot(tvars2plot, save_pdf=path, display=False)
    if "svg" in config.formats:
        tplot(tvars2plot, save_svg=path, display=False)
    if "csv" in config.formats:
        da: DataArray = get_data(tvars2plot, xarray=True)
        da.to_pandas().to_csv(path + ".csv")