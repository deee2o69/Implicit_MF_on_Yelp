function run_yelp_pipeline(nLines)
% RUN_YELP_PIPELINE  Orchestrates the end-to-end workflow.
%
%   run_yelp_pipeline                % whole dataset
%   run_yelp_pipeline(80000)         % 80k lines (demo)
%
% Lancia:
%   1) preprocess_yelp      -> train/val/test + dicts
%   2) show_split_head       (debug: first lines)
%   3) train_mf_baseline    -> top20_mf.mat + metrics
%
% Time for each phase is evaluated.

% =============================== paths ================================
jsonDir = 'data';   % <— adjust
if nargin < 1, nLines = inf; end

fprintf('\n================  Yelp Pipeline  ================\n');
if isinf(nLines)
    fprintf('Dataset: FULL   |  JSON dir: %s\n', jsonDir);
else
    fprintf('Dataset: first %d lines | JSON dir: %s\n', nLines, jsonDir);
end
fprintf('Seed: 2022\n');

% =============================== 1. preprocessing =====================
t0 = tic;
fprintf('\n[1] Pre-processing …\n');
preprocess_yelp(jsonDir, nLines);
tPrep = toc(t0);
fprintf('[1] Done (%.1f s)\n', tPrep);

% ---------- debug: quick look at split --------------------------------
if exist('show_split_head.m','file')
    show_split_head('train.mat', 5);
end

% =============================== 2. training + eval ===================
t1 = tic;
fprintf('\n[2] Training MF baseline …\n');
train;          % stampa Recall / NDCG al proprio interno
tTrain = toc(t1);
fprintf('[2] Done (%.1f s)\n', tTrain);

% =============================== summary ==============================
fprintf('\nTotal runtime: %.1f seconds\n', toc(t0));
fprintf('=================================================\n');
end