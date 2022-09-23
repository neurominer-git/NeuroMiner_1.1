function nk_MLInterpreter_batch(paramfile)

global NM

% Read parameter file
% ===========================
if ~exist(paramfile,'file') 
    error([paramfile 'not found. Abort job!']);
end
fid = fopen(paramfile);
params = textscan(fid, '%s');
fclose(fid);

% Parse parameters in params
% ==================================================================================================================
NMpath        		= params{1}{1};					% NM root folder
datpath             = params{1}{2};					% NM structure
analind             = str2double(params{1}{3});		% Analysis index to identify analysis for HPC
oocvind             = str2double(params{1}{4});		% multi flag in case MULTI-CLASS analysis has been conducted
saveparam           = str2double(params{1}{5});     % Save optimized parameters and models to disk for future use
loadparam           = str2double(params{1}{6});	    % Load optimized parameters and models from disk instead
reestimateflag      = str2double(params{1}{7});     % restimate interpretations based on predictions
optparammaster      = params{1}{8};                 % Master file containing paths optimized preproc parameter files
optmodelsmaster     = params{1}{9};                 % Master file containing paths optimized models files
curCPU              = str2double(params{1}{10});	% Current CPU to be used
numCPU              = str2double(params{1}{11});    % Number of CPUs in the submitted job
CV2x1               = str2double(params{1}{12});    % Range param for CV2 grid definition: Perm start CV2
CV2x2               = str2double(params{1}{13});    % Range param for CV2 grid definition: Perm end CV2
CV2y1               = str2double(params{1}{14});    % Range param for CV2 grid definition: Fold start CV2
CV2y2               = str2double(params{1}{15});	% Range param for CV2 grid definition: Fold end CV2

addpath(NMpath);
warning('off','MATLAB:FINITE:obsoleteFunction')
fprintf('\nLoading NM structure: %s',datpath)
load(datpath);
assignin('base','NM',NM);

% %%%%%%%%%%%%%%%%%%%%%%%%% INITIALIZE NeuroMiner %%%%%%%%%%%%%%%%%%%%%%%%%
action = struct('addrootpath',1, ...
                'addDRpath',1, ...
                'addMIpath',1, ...
                'addLIBSVMpath',1, ...
                'addLIBLINpath',1, ...
                'addMikeRVMpath',1, ...
                'all',1);

nk_Initialize(action)

% %%%%%%%%%%%%%%%%%%%%%%%%% SETUP PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%
if saveparam == 1
    
    loadparam = 2;
    optparammaster = []; 
    optmodelsmaster=[];

elseif saveparam == 2
    
    if ischar(optparammaster) && exist(optparammaster,'file')
        load(optparammaster,'featmat');
        optparammaster = featmat;
    else
        optparammaster = [];
    end
    if ischar(optmodelsmaster) && exist(optmodelsmaster,'file')
        load(optmodelsmaster,'featmat');
        optmodelsmaster = featmat;
    else
        optmodelsmaster = [];
    end
    
end

if oocvind
    oocvflag = true;
end

inp = struct( 'analind', analind, ...                   
              'oocvflag', oocvflag, ...                 
              'oocvind', oocvind, ...                   
              'OO', NM.OOCV{oocvind}, ...               
              'lfl', 1, ...                             
              'ovrwrt', 1, ...                          
              'saveparam', saveparam, ...               
              'ovrwrtperm', 2, ...                      
              'recompute_estimates', reestimateflag, ... 
              'saveCV1', 2, ...                         
              'loadparam', loadparam, ...               
              'batchflag', 1);                          

inp.GridAct = nk_GenGridAct_batch(NM.analysis{analind}.params.cv, curCPU, numCPU, CV2x1, CV2x2, CV2y1, CV2y2);
inp.optpreprocmat = optparammaster;
inp.optmodelmat = optmodelsmaster;

nk_MLInterpreterPrep( 99, inp, 'NM:HPC:MLINTERPRETER' );