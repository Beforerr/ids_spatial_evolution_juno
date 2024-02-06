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