'''
Author: Clara Vetter 
Last changed: 02.09.2022

This script is called by nk_GetTestPerf_RNDFOR.m and computes the test 
performance of a random forest regression model on the test sample. 

Input from MATLAB: 
    - model_name = path to file containing the model's information from 
    training
    - test_feat = the test set (test X)

Output: 
    - the predictions are stored in a MATLAB file RFpredict_output.mat in 
    the analysis' folder (which will be loaded in by Matlab to proceed) 
'''

from sklearn.ensemble import RandomForestRegressor
import pickle
from scipy.io import savemat
#import os

rf = pickle.load(open(model_name, 'rb'))
#os.remove(model_name)
predictions = rf.predict(test_feat)
#probabilities = rf.predict_proba(test_feat)

#res_dict = {'predictions': predictions, 'probabilities': probabilities}
res_dict = {'predictions': predictions}
results_file = f'{rootdir}/RFpredict_output.mat'

savemat(results_file, res_dict)
