# function that simulates data with the same structure as input data
import pandas as pd
import numpy as np
from sdv.tabular import GaussianCopula
from sdv.constraints import OneHotEncoding, FixedCombinations
from tqdm import tqdm

data = pd.read_csv(data_file)
data['label'] = labels

# if n_obs is an array with more than 1 element, each element specifies the amount of observations to simulate within each group (i.e. same label)
if type(n_obs) is not int:
    # check first whether len(n_obs) matches the number of unique labels
    if len(n_obs) != len(np.unique(labels)):
        raise ValueError('Number of observations to simulate does not match number of groups')

    # preallocate space for simulated dataset
    sim_sample = pd.DataFrame(columns = data.columns)
    for i in tqdm(range(len(np.unique(labels)))):
        
        # split dataset
        group_df = data[data['label'] == np.unique(labels)[i]]
        if cv1lco > 0:
            group_df.columns.value[cv1lco-1] = 'CV1LCO'
           
        if cv2lco > 0:
            group_df.columns.values[cv2lco-1]:'CV2LCO'

        constraints = []
        if cv1lco > 0 and cv2lco > 0:
            fixed_cvlco_constraint = FixedConstrained(column_names = ['CV1LCO', 'CV2LCO'])
            constraints.append(fixed_cvlco_constraint)
        if type(sitesCols) is not int:
            auxSitesColsNames = [f'Y{idx}' for idx in sitesCols]
            sitesColsPy = [x-1 for x in sitesCols]
            print(sitesColsPy)
            #group_df.columns.values[sitesColsPy] = auxSitesColsNames
            #print(list(group_df))
            sites_constraint = OneHotEncoding(column_names = auxSitesColsNames)
            constraints.append(sites_constraint)
        

        model = GaussianCopula(constraints = constraints)
        #print(list(group_df))
        model.fit(group_df)
#         if len(cv1lco)>0: # in the case of leave-one group ot CV (either CV1 or CV2)
#             conditions = pd.DataFrame({
#                 'CV1LCO' : lco})
#             sim_group = model.sample_remaining_columns(conditions)
#         else
        sim_group = model.sample(n_obs[i])
        sim_sample = sim_sample.append(sim_group)
else:
    # model = GaussianCopula(primary_key = ID)
    model = GaussianCopula()
    # model = CopulaGAN()
    model.fit(data)
    print('Busy sampling the data! This might take a while...')
    sim_sample = model.sample(n_obs)

out_path = f'{rootdir}/simData.csv'
sim_sample.to_csv(out_path,index=False)
