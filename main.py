import uvicorn
from pydantic import BaseModel
from typing import List, Optional

from azureml.train.automl import AutoMLConfig
from azureml.core.workspace import Workspace
from azureml.core.experiment import Experiment
from azureml.widgets import RunDetails
import azureml.automl.runtime
import azure.core
import pickle
import pandas as pd
import numpy as np

model_name = "./model.pkl"
loaded_model = pickle.load(open(model_name,"rb"))

app = FastAPI()

class InputData(BaseModel):
    Input01: float
    Input02: float
    Input03: float


class PredictionOut(BaseModel):
    Output: np.float64

@app.get("/")
def home():
    return {"health_check": "OK"}

@app.get("/score/{InputList}")
def score(input_list: str):
    InputData = [float(i) for i in input_list.split(",")]
    X = pd.DataFrame([InputData], columns =['Input01', 'Input02', 'Input03'])
    prediction = loaded_model.predict(X)
    return {"Prediction": prediction[0]}

@app.post("/predict", response_model=PredictionOut)
def predict(payload: InputData):
    X = pd.DataFrame(data={
        "Input01": [payload.Input01],        
        "Input02": [payload.Input02],
        "Input03": [payload.Input03]
      })

    prediction = loaded_model.predict(X)
    return {"Output": prediction[0]}
