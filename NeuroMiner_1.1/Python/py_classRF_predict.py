from sklearn.ensemble import RandomForestClassifier
import pickle
from scipy.io import savemat
#import os

rf = pickle.load(open(model_name, 'rb'))
#os.remove(model_name)
predictions = rf.predict(test_feat)
probabilities = rf.predict_proba(test_feat)

res_dict = {'predictions': predictions, 'probabilities': probabilities}

results_file = f'{rootdir}/RFpredict_output.mat'

savemat(results_file, res_dict)
