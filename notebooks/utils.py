from pydantic import constr, BaseModel, root_validator
from datetime import datetime, date


class TplotConfig(BaseModel):
    tvar: str
    trans: list[str] = None


class PanelConfig(BaseModel):

    timerange: list[datetime | date] = None
    
    id: str = None
    name: str = None
    units: str = None
    
    satellite: constr(to_lower=True)
    instrument: constr(to_lower=True)
    datatype: str = None
    probe: str = None
    
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
    
