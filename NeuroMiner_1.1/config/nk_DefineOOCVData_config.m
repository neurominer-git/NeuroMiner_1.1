% =========================================================================
% FORMAT NM = nk_DefineOOCVData_config(NM, O, parentstr)
% =========================================================================
% This function coordinates the input of independent test data into NM
%
% Inputs:
% -------
% NM        : The NM workspace
% O         : The OOCV workspace (containt
% parentstr : Name of the calling function
%
% Outputs:
% --------
% NM (see above)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (c) Nikolaos Koutsouleris 08/2020

function NM = nk_DefineOOCVData_config(NM, O, parentstr)
    
if (~exist('O','var') || isempty(O)) || isnumeric(O)
    [NM, Y, inp.oocvind, inp.fldnam, inp.dattype] = nk_SelectOOCVdata(NM, O, 1);
else
    inp.fldnam      = O.fldnam;
    inp.oocvind     = O.ind;
    Y           = NM.(inp.fldnam){inp.oocvind};
    Y.desc      = O.desc;
    Y.date      = O.date;
    Y.label_known = false;
    switch O.fldnam
        case 'OOCV'
            inp.dattype     = 'independent test data';
        case 'C'
            inp.dattype     = 'calibration data';
    end
end
if isempty(inp.oocvind), return; end
NM.(inp.fldnam){inp.oocvind}.desc = Y.desc;
NM.(inp.fldnam){inp.oocvind}.date = Y.date;
if ~isfield(NM.(inp.fldnam){inp.oocvind},'n_subjects_all'), NM.(inp.fldnam){inp.oocvind}.n_subjects_all = Inf; end
if ~isfield(NM.(inp.fldnam){inp.oocvind},'labels_known') && isfield(Y,'labels_known') || (NM.(inp.fldnam){inp.oocvind}.labels_known ~=  Y.labels_known)
    NM.(inp.fldnam){inp.oocvind}.labels_known = Y.labels_known; 
end
inp.currmodal = 1;
inp.nummodal = numel(NM.Y);
inp.na_str = '?';
inp.covflag = false;
inp.desc = Y.desc;
if isfield(NM,'covars'), inp.covflag = true; end
act = 1; while act, [act, NM, inp] = DefineOOCVData(inp, NM, Y, parentstr); end
% _________________________________________________________________________
function [act, NM, inp ] = DefineOOCVData(inp, NM, Y, parentstr)

nk_PrintLogo
navistr = sprintf('%s\t>>> %s',parentstr, 'OOCV data input'); fprintf('\nYou are here: %s >>>',navistr); 

fprintf('\n\n\t============================')
fprintf('\n\t    AVAILABLE MODALITIES  ') 
fprintf('\n\t============================')
fprintf('\n')
for i=1:inp.nummodal
    availstr = 'available';
    if isfield(NM.(inp.fldnam){inp.oocvind},'Y') && ischar(NM.(inp.fldnam){inp.oocvind}.Y)
        availstr = 'linked';
    elseif ~isfield(NM.(inp.fldnam){inp.oocvind},'Y')  || i > numel(NM.(inp.fldnam){inp.oocvind}.Y) || isempty(NM.(inp.fldnam){inp.oocvind}.Y{i})
        availstr = 'not loaded';
    end
    str = sprintf('Modality %g [ %s ]: ', i, NM.datadescriptor{i}.desc);
    fprintf('\n'); 
    if i==inp.currmodal
        fprintf('==> %s ', str); 
    else
        fprintf('\t%s', str); 
    end
    if strcmp(availstr,'available')
        fprintf('%s ', availstr);
    elseif strcmp(availstr,'linked')
        fprintf('%s [ %s ] ', availstr, NM.(inp.fldnam){inp.oocvind}.Y);
    else
        fprintf( '%s ', availstr);
    end   
end
fprintf('\n')
if inp.nummodal > 1
    mnuact = [ sprintf('Select modality [ currently: modality %g ]',inp.currmodal) ...
           sprintf('|Add/Modify OOCV data in modality %g', inp.currmodal) ... 
           sprintf('|Delete OOCV data in modality %g', inp.currmodal) ]; 

    mnusel = 1:3;
else
    mnuact = 'Add/Modify OOCV data|Delete OOCV data' ; 
    mnusel = 2:3;
end

if isfield(NM.(inp.fldnam){inp.oocvind},'Y') && ~isempty(NM.(inp.fldnam){inp.oocvind}.Y)
    if ~ischar(NM.(inp.fldnam){inp.oocvind}.Y)
        mnuact = [mnuact '|Export OOCV data container to file and create link in NM structure|Replace OOCV data container with link to file'];
        mnusel = [mnusel  4 5];
    else
        mnuact = [mnuact '|Update OOCV data link '];
        mnusel = [mnusel  5];
        if exist(NM.(inp.fldnam){inp.oocvind}.Y,'file')
            mnuact = [mnuact '|Re-import OOCV data from file into NM structure'];
            mnusel = [mnusel  6];
        end
    end
else
    mnuact = [mnuact '|Fill OOCV data container with link to file'];
    mnusel = [mnusel 5];
end

if inp.covflag && isfield(NM.(inp.fldnam){inp.oocvind},'Y') && NM.(inp.fldnam){inp.oocvind}.n_subjects_all>0
    if isfield(NM.(inp.fldnam){inp.oocvind},'covars')
        mnuact = [ mnuact '|Modify covariate data' ];    
    else
        mnuact = [ mnuact '|Add covariate data' ];   
    end
    mnusel = [mnusel 7];
end

act = nk_input(sprintf('Select action for OOCV container %s',inp.desc),0,'mq',mnuact,mnusel);

switch act
    
    case 1 % Define active modality
        inp.currmodal = nk_input('Select active modality',0,'i',inp.currmodal);
        if inp.currmodal > inp.nummodal, inp.currmodal = inp.nummodal; end
    case 2 % Read-in data
        NM = InputOOCVModality(inp, NM, Y, navistr);
    case 3 % Clear data from modality
        NM = ClearOOCVModality(inp, NM);
        if ~isfield(NM.(inp.fldnam){inp.oocvind},'Y'), act = 0; end
    case 4
        NM = LinkOOCV2Disk(inp, NM, 'export&link');
    case 5
        NM = LinkOOCV2Disk(inp, NM, 'replacelink');
    case 6
        NM = ReimportOOCVfromDisk(inp, NM);
    case 7
        % Don't forget the covariates if they are present in the discovery data
        NM.(inp.fldnam){inp.oocvind}.covars = nk_DefineCovars_config(NM.(inp.fldnam){inp.oocvind}.n_subjects_all, NM.covars); 
end

% _________________________________________________________________________
function NM = ReimportOOCVfromDisk(inp, NM)

fprintf('\nRe-importing linked OOCV container into NM: %s',NM.(inp.fldnam){inp.oocvind}.Y);
load(NM.(inp.fldnam){inp.oocvind}.Y);
NM.(inp.fldnam){inp.oocvind} = OOCV;

% _________________________________________________________________________
function NM = LinkOOCV2Disk(inp, NM, act)
global OCTAVE
OOCV = NM.(inp.fldnam){inp.oocvind};
switch act
    case 'export&link'
        [filename, pathname] = uiputfile({'.mat'},'Save OOCV container to disk');
        if isempty(filename), return, end
        pth = fullfile(pathname, filename);
        try
            save(pth, 'OOCV');
        catch
            if OCTAVE
                save(pth, 'OOCV');
            else
                save(pth, 'OOCV', '-v7.3');
            end
        end
    case 'replacelink'
        [filename, pathname] = uigetfile({'.mat'},'Link OOCV container to OOCV file on disk');
        pth = fullfile(pathname, filename);
        load(pth)
        NM.(inp.fldnam){inp.oocvind} = OOCV;
        NM.(inp.fldnam){inp.oocvind}.Y = pth;
end
NM.(inp.fldnam){inp.oocvind}.Y = pth;

% _________________________________________________________________________
function NM  = InputOOCVModality(inp, NM, Y, parentstr)

nk_PrintLogo
fprintf('\n\n'); mestr = sprintf('Input %s for Modality %g', inp.dattype, inp.currmodal);  
navistr = sprintf('%s >>> %s',parentstr, mestr); fprintf('\nYou are here: %s >>>',navistr); 

% Retrieve input settings from the discovery data
IO = NM.datadescriptor{inp.currmodal}.input_settings;
if isfield(IO,'selCases'), IO = rmfield(IO,'selCases'); end

% Remove setting for non-labeled subjects
IO.nangroup=false;
IO.nan_subjects=0;
if isfield(IO,'Pnan')
    IO = rmfield(IO,'Pnan');
    IO = rmfield(IO,'Vnan');
end

% Activate independent test data input
IO.oocvflag = true;
IO.labels_known = Y.labels_known;
IO.badcoords = NM.badcoords{inp.currmodal}; 
IO.brainmask = NM.brainmask{inp.currmodal}; 
IO.Ydims = size(NM.Y{inp.currmodal},2);

if IO.labels_known
    IO.n_subjects = IO.n_subjects/0;
    IO.n_subjects_all = Inf;
else
    IO.n_subjects = Inf;
    IO.n_subjects_all = Inf;
    IO.n_samples = 1;
end
    
if inp.currmodal>1 && isfield(NM.(inp.fldnam){inp.oocvind},'cases')
    IO.ID = NM.(inp.fldnam){inp.oocvind}.cases;
else
    IO = rmfield(IO,'ID');
    if isfield(IO,'survanal_time'), IO = rmfield(IO,'survanal_time'); end
end
    
if strcmp(IO.datasource,'matrix')
    IO.matrix_edit = inp.na_str;
    IO.sheets = inp.na_str;
    IO.sheet = inp.na_str;
    IO.sheets = inp.na_str;
    IO.M_edit = inp.na_str;
    IO.featnames_cv = NM.featnames{inp.currmodal};
else
    if strcmp(IO.datasource,'spm')
        IO.datasource = 'nifti'; 
        IO.groupmode = 1;
        IO = rmfield(IO,'design');
        IO = SetFileFilter(IO,IO.groupmode,IO.datasource);
    end
    IO.globvar_edit = inp.na_str;
    if isfield(IO,'g') && ~isempty(IO.g), IO = rmfield(IO,'g'); end
    if IO.labels_known
        IO.P = repmat({[]},1,IO.n_samples);
        IO.V = IO.P;
    else
        IO.P = []; 
        IO.V = [];
    end
    IO.PP = [];
    IO = rmfield(IO,'Vinfo');
    IO = rmfield(IO,'Vvox');
    IO = rmfield(IO,'F');
    IO = rmfield(IO,'files');
    if isfield(IO,'L') && ~isempty(IO.L),
        IO.label_edit = inp.na_str;
        IO = rmfield(IO,'L'); 
    end
end
t_act = Inf; t_mess = [];while ~strcmp(t_act,'BACK'), [ IO, t_act, t_mess ] = DataIO( NM.(inp.fldnam)(inp.oocvind) , mestr, IO, t_mess, inp.currmodal);  end
if IO.completed
    NM.(inp.fldnam){inp.oocvind} = TransferModality2NM( NM.(inp.fldnam){inp.oocvind}, IO, inp.currmodal ); 
    NM.(inp.fldnam){inp.oocvind}.n_subjects_all = size(NM.(inp.fldnam){inp.oocvind}.cases,1);
else
    NM.(inp.fldnam){inp.oocvind} = Y;
end
% _________________________________________________________________________
function NM = ClearOOCVModality(inp, NM)

if iscell(NM.(inp.fldnam){inp.oocvind}.Y)
    NM.(inp.fldnam){inp.oocvind}.Y{inp.currmodal} = [];
else
    NM.(inp.fldnam){inp.oocvind}.Y = [];
end
NM.(inp.fldnam){inp.oocvind}.brainmask{inp.currmodal} = [];
NM.(inp.fldnam){inp.oocvind}.badcoords{inp.currmodal} = [];
NM.(inp.fldnam){inp.oocvind}.datadescriptor{inp.currmodal} = [];
NM.(inp.fldnam){inp.oocvind}.files{inp.currmodal} = [];
NM.(inp.fldnam){inp.oocvind}.featnames{inp.currmodal} = [];

if iscell(NM.(inp.fldnam){inp.oocvind}.Y) &&  ~sum(~cellfun(@isempty,NM.(inp.fldnam){inp.oocvind}.Y ))
    NM.(inp.fldnam){inp.oocvind} = rmfield(NM.(inp.fldnam){inp.oocvind},'Y');
    NM.(inp.fldnam){inp.oocvind} = rmfield(NM.(inp.fldnam){inp.oocvind},'brainmask');
    NM.(inp.fldnam){inp.oocvind} = rmfield(NM.(inp.fldnam){inp.oocvind},'badcoords');
    NM.(inp.fldnam){inp.oocvind} = rmfield(NM.(inp.fldnam){inp.oocvind},'datadescriptor');
    NM.(inp.fldnam){inp.oocvind} = rmfield(NM.(inp.fldnam){inp.oocvind},'files');
    NM.(inp.fldnam){inp.oocvind} = rmfield(NM.(inp.fldnam){inp.oocvind},'featnames') ;
    NM.(inp.fldnam){inp.oocvind} = rmfield(NM.(inp.fldnam){inp.oocvind},'cases');
    if isfield(NM.(inp.fldnam){inp.oocvind},'covars')
        NM.(inp.fldnam){inp.oocvind} = rmfield(NM.(inp.fldnam){inp.oocvind},'covars');
    end
    if isfield(NM.(inp.fldnam){inp.oocvind},'groupnames')
        NM.(inp.fldnam){inp.oocvind} = rmfield(NM.(inp.fldnam){inp.oocvind},'groupnames');
    end
    NM.(inp.fldnam){inp.oocvind} = rmfield(NM.(inp.fldnam){inp.oocvind},'label');  
    NM.(inp.fldnam){inp.oocvind}.n_subjects = 0;
    NM.(inp.fldnam){inp.oocvind}.n_subjects_all = 0;
end

