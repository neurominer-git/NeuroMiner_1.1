function [model] = ml_unsupervised_HMM(X, options)
% Description:
%       Models observation data in input X as generated by a
%       chain-structured latent variable distribution with the Markov
%       property
%
% Options:
% 
%   - observed: Observation/Emission probability matrix
%   - transition: Transition probability matric
%   - pi: initial distribution of states
%   - emissionsProbabilitiesGuess: initialization for EM algorithm
%   - transitionProbaiblitiesGuess: initialization for EM algorithm
%   - maxIter: maximum number of iterations to run Baum Welch/EM
%   - nHiddenStatesGuess: number of latent states at each step

% process inputs
[O, T, pi, Oguess, Tguess, maxIter, nStates] = ...
            myProcessOptions(options, 'observed', [], ...
                            'transition', [], 'pi', [], ...
                            'emissionsProbabilitiesGuess', [], ...
                            'transitionProbabilitiesGuess', [], ...
                            'maxIter', 500, ...
                            'nHiddenStatesGuess', 0);
                        
model.Obs = X;
model.observedProbabilities = O;
model.transitionProbabilities = T;
model.initialDistribution = pi;
model.Oguess = Oguess;
model.Tguess = Tguess; 
model.maxIter = maxIter;
model.nHiddenStates = nStates;
model.individuallyMostLikely = @individuallyMostLikely;
model.Viterbi = @Viterbi;
model.BaumWelch = @BaumWelch;
end

function [B, T, pi] = BaumWelch(model)
Oguess = model.Oguess;
Tguess = model.Tguess;
maxIter = model.maxIter;
nHiddenStates = model.nHiddenStates;
S = model.Obs;
nObservableStates = length(unique(S));

if nHiddenStates == 0 
   error(['Must provide guess of number (>0) of hidden states ', ...
         'in order to use Baum Welch algorithm'])
end

if isempty(Tguess)
    Trand = rand(nHiddenStates);
    Tguess = bsxfun(@rdivide, Trand, sum(Trand,2));
end

if isempty(Oguess)
    Orand = rand(nHiddenStates,nObservableStates);
    Oguess = bsxfun(@rdivide, Orand, sum(Orand,2));
end
[numSequences, seqLen] = size(S);

[nHidden, observableStates] = size(Oguess);

% initialize p based on S
pi = rand(nHidden, 1); pi = pi ./ sum(pi);

% O is b_ij <--> emission probability for hidden state i at time j
% T is a_ij <--> transition probability from hidden state i to j
T = Tguess;
B = Oguess;

iter = 0;
tol = 1e-5;
% Follow notation of Rabiner 1988
ll = 0;

% Do Baum-Welch iterations / EM updates
while iter < maxIter
Xi = zeros(nHidden, nHidden);
gamma = zeros(nHidden, observableStates);
lastll = ll;
ll = 0;

%% ----- E-step -----
for l = 1:numSequences
    S_l = S(l,:); seq = S_l;
    % Forward-Backward pass with current model
    [Alpha_l, c_l] = forwardProbabilities(B, T, pi, S_l, nHidden, seqLen);
    Beta_l = backwardProbabilities(B, T, S_l, c_l, nHidden, seqLen);
    S_l = [0 S_l]; % offset for comparison with standard implementations
    ll = ll + sum(log(c_l));
    
    for k = 1:nHidden
        for l = 1:nHidden % from Si time n-1 to Sj at time n
             for t = 1:seqLen
                Xi(k, l) = Xi(k, l) + (Alpha_l(k, t) * ...
                                 T(k, l) * B(l, S_l(t+1) ) * ...
                                 Beta_l(l, t+1) ) ./ c_l(t+1);
            end
        end
    end
    
    for k = 1:nHidden
        for i = 1:observableStates
            observedI = find(S_l == i);
            if isempty(observedI)
                error(['Baum Welch failed: some sequence did not', ...
                       'have all observable states in it']);
            end
            % sum up each gamma where we observed class k
           gamma(k,i) = gamma(k,i) + sum(Alpha_l(k, ...
                                         observedI).*Beta_l(k, observedI));
        end
    end
end

%% ----- M-step -----
T = Xi ./ repmat(sum(Xi, 2),[1, nHidden]);
B = gamma ./ repmat(sum(gamma, 2),[1, nObservableStates]);

% Fail on division by zero
if(any(isnan(T)))
    error('NaN found')
end
if(any(isnan(B)))
    error('NaN found')
end

if abs(ll - lastll) < tol
    fprintf('Convergence reached within tolerance after %d iterations', ...
            iter);
    break;
end
    
iter = iter + 1;
end
end

function [q] = Viterbi(model)
obs = model.Obs;
O = model.observedProbabilities;
T = model.transitionProbabilities;
p = model.initialDistribution;
% Validate input 
if isempty(O) || isempty(T) || isempty(p)
    error('Viterbi was called without specifying distribution');
end
[nHidden, ~] = size(T);
[~, len] = size(obs);

% Follows notation in Rabiner 1989
delta = zeros(nHidden, len);
psi = zeros(nHidden, len);
q = zeros(1, len); % optimal hidden states

% ----- Initialization
for i = 1:nHidden
    delta(i, 1) = p(i) * O(i, obs(1));
    psi(i, 1) = 0;
end

% ----- Recursion
for t = 2:len
    for j = 1:nHidden
        [prob, state] = max(delta(:, t-1) .* T(:, j));
        delta(j, t) = prob*O(j, obs(t));
        psi(j, t) = state;
    end
end
[~, q(len)] = max(delta(:, len));

% ----- Backtracking
for t = len-1:-1:1
    q(t) = psi(q(t+1), t+1);
end
end

function [likelySeq] = individuallyMostLikely(model)
obs = model.Obs;
O = model.observedProbabilities;
T = model.transitionProbabilities;
p = model.initialDistribution;
[nHidden, ~] = size(T);
[~, len] = size(obs);

% Validate input 
if isempty(O) || isempty(T) || isempty(p)
    error(['Individually Most Likely sequence function ', ... 
           'was called without specifying distribution']);
end

% ----- Forward probabilities ---------------------------------------------
[alpha, c] = forwardProbabilities(O, T, p, obs, nHidden, len);

% ----- Backward Probabilities --------------------------------------------
beta = backwardProbabilities(O, T, obs, c, nHidden, len);

gamma = zeros(nHidden, len);
for t = 1:len
    for i = 1:nHidden
        gamma(i, t) = (alpha(i, t) * beta(i, t)) / ...
                        sum(alpha(:, i) .* beta(:, i));
    end
end
[~, likelySeq] = max(gamma);
end

function[beta] = backwardProbabilities(O, T, obs, scales, nHidden, seqLen)
    obs = [-1, obs];
    seqLen = length(obs);
    beta = ones(nHidden, seqLen);
    beta(:, seqLen) = ones(nHidden, 1);
    for t = seqLen-1:-1:1
        for i = 1:nHidden
            beta(i, t) =  sum(T(i,:)' .* O(:, obs(t+1)) .* ...
                          beta(:, t+1))./scales(t+1);
        end
    end
end

function [alpha, scales] = forwardProbabilities(O, T, p, obs, nHidden, ...
                                                seqLen)
    % add extra symbol at start to make comparison with Mathworks easier
    obs2 = [-1, obs];
    seqLen = length(obs2);
    alpha = zeros(nHidden, seqLen);
    alpha(1,1) = 1; % assume start in state 1
    scales = zeros(1, seqLen);
    scales(1) = 1;
    for t = 1:seqLen-1
        for hiddenState = 1:nHidden
            alpha(hiddenState, t+1) = (sum(alpha(:, t) .*  T(:,hiddenState))) ...
                                      * O(hiddenState, obs2(t+1));
        end
        scales(t+1) = sum(alpha(:, t+1));
        alpha(:, t+1) = alpha(:, t+1) ./ scales(t+1);
    end 
end