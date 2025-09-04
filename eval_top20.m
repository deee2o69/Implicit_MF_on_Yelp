function [rec, ndcg] = eval_top20(predFile, testFile, nItems)
% EVAL_TOP20  Compute Recall@20 and NDCG@20 for a Top-20 recommendation list.
%
%   [rec, ndcg] = eval_top20(predFile, testFile, nItems)
%
% INPUT
%   predFile : MAT-file produced by *train_mf_baseline* (or your model)
%              and containing two variables
%                   • testUsers  : [nUsers × 1] uint32
%                   • top20      : cell, each cell is 1 × 20 uint32
%
%   testFile : MAT-file written by *preprocess_yelp* that holds the ground
%              truth of the leave-one-out split; variables
%                   • U : user indices  (uint32)
%                   • V : item indices  (uint32)
%
%   nItems   : total number of distinct items (catalogue size).  This
%              parameter is not used in the current implementation but is
%              kept for compatibility with earlier variants.
%
% OUTPUT
%   rec  : Recall@20  – fraction of test users whose ground-truth item
%                       appears in the Top-20 recommendations.
%   ndcg : NDCG@20    – Discounted Cumulative Gain, i.e. 1/log2(rank+1)
%                       averaged over all test users.  The ideal DCG is 1
%                       because each user has exactly one relevant item.
%
% EVALUATION PROTOCOL
%   The evaluator assumes **one ground-truth item per user** (leave-one-out
%   split).  If the ground-truth item is found among the twenty suggested
%   items, Recall = 1 for that user; otherwise Recall = 0.  NDCG rewards a
%   higher position of the hit inside the Top-20 list.
%
% NOTE
%   No negative sampling is required here: the Top-20 list is already
%   provided by the model and compared directly with the ground truth.
%
% ---------------------------------------------------------------------

rng(2022);                             % fixed seed for reproducibility

% Load predictions and ground-truth split
S  = load(predFile, 'testUsers', 'top20');
T  = load(testFile, 'U', 'V');

% Build map: user index → ground-truth item
gt = containers.Map(double(T.U), double(T.V));

nU   = numel(S.testUsers);
hits = 0;           % number of users where GT is present in Top-20
dcg  = 0;           % cumulative discounted gain

for k = 1:nU
    u   = S.testUsers(k);
    g   = gt(u);                  % ground-truth item for this user
    top = S.top20{k};             % 20 recommendations

    % Recall@20: hit if ground truth is in the list
    idx = find(top == g, 1);      % position of g inside Top-20
    if ~isempty(idx)
        hits = hits + 1;
        % NDCG contribution: higher rank = larger gain
        dcg  = dcg + 1 / log2(idx + 1);
    end
end

rec  = hits / nU;                 % average hit ratio
ndcg = dcg  / nU;                 % ideal DCG = 1 because one relevant item
end