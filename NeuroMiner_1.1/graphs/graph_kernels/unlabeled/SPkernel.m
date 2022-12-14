function [K, runtime, Phi] = SPkernel(Graphs, features)
% Compute the shortest path kernel for a set of graphs (by exact matching
% of shortest path lengths)
% Copyright 2012 Nino Shervashidze
% Input: Graphs - a 1xN array of graphs represented just with adjacency matrices
% 	 Graphs(i).am is the i'th adjacency matrix
%        Graphs(i) may have other fields, but they will not be considered by this script
%        features - a boolean: 1 if we want to output the feature
%                   vector representation for each graph, 0 otherwise
% Output: K - nxn kernel matrix K
%         runtime - scalar
%         Phi (if features = 1) - a NFxN times sparse matrix, where NF is the number
%               of features (shortest path lengths), containing the feature vector
%               representation of each graph

N=size(Graphs,2);
Ds = cell(1,N); % shortest path distance matrices for each graph
if nargin<2 features=0; end
Phi = [];

t=cputime; % for measuring runtime

% compute Ds and the length of the maximal shortest path over the dataset
maxpath=0;
for i=1:N
  Ds{i}=floydwarshall(Graphs(i).am);
  aux=max(Ds{i}(~isinf(Ds{i})));
  if aux > maxpath
    maxpath=aux;
  end
 % if rem(i,100)==0 disp(i); end
end
disp(['the preprocessing step took ', num2str(cputime-t), ' sec']);

sp=sparse((maxpath+1),N);
for i=1:N
  I=triu(~(isinf(Ds{i})));
  Ind=Ds{i}(I)+1; % some shortest paths will equal 0, so we have to
                  % add 1 to use them as indices of features
  aux=accumarray(Ind,ones(nnz(I),1));
  sp(Ind,i)=aux(Ind);
end
K=full(sp'*sp);
if features Phi=sp; end
runtime=cputime-t;
disp(['kernel computation took ', num2str(cputime-t), ' sec']);
end

