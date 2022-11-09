print("Container works!")

from azureml.train.automl import AutoMLConfig
from azureml.core.workspace import Workspace
from azureml.core.experiment import Experiment
from azureml.widgets import RunDetails
import azureml.automl.runtime
import azure.core
import pickle
import pandas as pd


model_name = "./model.pkl"
loaded_model = pickle.load(open(model_name,"rb"))


X = pd.DataFrame(data={
        "Input01": [0.0],
        "Input02": [0.0],
        "Input03": [0.0]
      })

res = loaded_model.predict(X)
print(res)
print("Model works!")
