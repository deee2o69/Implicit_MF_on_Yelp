clearvars

% =======================  train_mf_baseline.m  ========================
% 1. build the split if it does not exist
if ~exist('train.mat','file')
    preprocess_yelp('/data');  % <-- adjust
end

% 2. load splits (U,V)
load train.mat  U V
T  = load('test.mat','U','V');
Ut = T.U;  Vt = T.V;

nU = double(max([U;Ut]));
nI = double(max([V;Vt]));
R  = sparse(double(U),double(V),1,nU,nI);   % implicit positives

% ---------- ALS hyper-parameters -------------------------------------
k = 40;  alpha = 40;  lambda = 0.1;  nIter = 15;
C = 1 + alpha*R;

P = 0.01*randn(nU,k);
Q = 0.01*randn(nI,k);
I = eye(k);

fprintf('Training implicit MF (ALS)…\n');
for it = 1:nIter
    % ---- update P ----------------------------------------------------
    QtQ = Q.'*Q;
    for u = 1:nU
        idx = find(R(u,:));
        if isempty(idx),  continue;  end
        Cu = C(u,idx)';                     % |idx| × 1
        Qu = Q(idx,:);                      % |idx| × k
        A  = QtQ + Qu.'*(diag(Cu)-eye(numel(idx)))*Qu + lambda*I;
        b  = Qu.'*Cu;
        P(u,:) = (A\b).';
    end
    % ---- update Q ----------------------------------------------------
    PtP = P.'*P;
    for i = 1:nI
        idx = find(R(:,i));
        if isempty(idx),  continue;  end
        Ci = C(idx,i);                      % |idx| × 1
        Pi = P(idx,:);                      % |idx| × k
        A  = PtP + Pi.'*(diag(Ci)-eye(numel(idx)))*Pi + lambda*I;
        b  = Pi.'*Ci;
        Q(i,:) = (A\b).';
    end
    fprintf('  iter %2d / %d\n', it, nIter);
end

% --- save factors -----------------------------------------------------
mf_utils('save', P, Q, 'mf_model.mat');

% ---------- Top-20 recommendations -----------------------------------
testUsers = unique(Ut);
top20 = cell(numel(testUsers),1);
for kU = 1:numel(testUsers)
    u = testUsers(kU);
    score = P(u,:) * Q.';          % 1 × nI
    seenIdx = find(R(u,:));        % <-- list of items already seen
    score(seenIdx) = -inf;         % mask them
    [~,top20{kU}] = maxk(score,20);
    top20{kU} = uint32(top20{kU});
end
save top20_mf.mat testUsers top20 -v7

% ---------- evaluation -----------------------------------------------
[rec,ndcg] = eval_top20('top20_mf.mat','test.mat', nI);
fprintf('\nRecall@20 = %.4f   NDCG@20 = %.4f\n', rec, ndcg);