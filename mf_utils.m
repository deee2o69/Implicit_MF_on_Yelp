function varargout = mf_utils(cmd, varargin)
% MF_UTILS  – single-file toolbox for the Yelp MF baseline
%
%   mf_utils('save', P, Q, 'mf_model.mat')
%   [P,Q,meta] = mf_utils('load', 'mf_model.mat')
%   mf_utils('buildBiz', jsonDir)               % build businessName.mat
%   mf_utils('debugUser', userIdx, topK, jsonDir)
%
% Add the folder containing this file to MATLAB path, e.g.:
%   addpath /path/to/toolbox

switch lower(cmd)
    case 'save'
        save_model(varargin{:});
    case 'load'
        [varargout{1:3}] = load_model(varargin{:});
    case 'buildbiz'
        build_business_name_map(varargin{:});
    case 'debuguser'
        debug_user(varargin{:});
    otherwise
        error('Unknown command: %s', cmd);
end
end

% =====================  LOCAL FUNCTIONS  ==============================

% ---------- save / load ------------------------------------------------
function save_model(P,Q,fname)
meta.k = size(P,2); meta.nU = size(P,1); meta.nI = size(Q,1);
save(fname,'P','Q','meta','-v7');
fprintf('Model saved to %s  (u=%d, i=%d, k=%d)\n',...
        fname, meta.nU, meta.nI, meta.k);
end

function [P,Q,meta] = load_model(fname)
S = load(fname,'P','Q','meta');
P=S.P; Q=S.Q; meta=S.meta;
fprintf('Model loaded  (u=%d, i=%d, k=%d)\n', meta.nU, meta.nI, meta.k);
end

% ---------- build business-name map -----------------------------------
function build_business_name_map(jsonDir)
bizJSON = fullfile(jsonDir,'yelp_academic_dataset_business.json');
fid = fopen(bizJSON,'r');
if fid==-1, error('Cannot open %s', bizJSON); end
bMap = containers.Map('KeyType','char','ValueType','char');
while true
    ln = fgetl(fid); if ~ischar(ln), break; end
    B = jsondecode(ln);
    bMap(B.business_id) = B.name;
end
fclose(fid);
save businessName.mat bMap
fprintf('businessName.mat saved  (%d businesses)\n', bMap.Count);
end

% ---------- debug a single user ---------------------------------------
function debug_user(userIdx, topK, jsonDir)
if nargin<2 || isempty(topK), topK = 10; end

% 1. load model
[P,Q] = mf_utils('load','mf_model.mat');

if userIdx<1 || userIdx>size(P,1)
    fprintf('User index %d out of range.\n', userIdx); return; end

% 2. ground-truth item from test split
T = load('test.mat','U','V');
row = find(T.U==userIdx,1);
if isempty(row)
    fprintf('User %d not in test split.\n', userIdx); return; end
gtItem = T.V(row);

% 3. training mask
Tr = load('train.mat','U','V');
R = sparse(double(Tr.U),double(Tr.V),1,size(P,1),size(Q,1));

scores = P(userIdx,:) * Q.';         % 1 × nItems
scores(R(userIdx,:)) = -inf;   % mask seen items

[~,rec] = maxk(scores, topK);

% 4. dictionaries
load userMap.mat uStr
load itemMap.mat iStr

% optional business names
bizName = @(~)"";
if exist('businessName.mat','file')
    load businessName.mat bMap
    bizName = @(bid) conditionalName(bid,bMap);
end

fprintf('\n=== USER %d  [%s] ===\n', userIdx, uStr(userIdx));
fprintf('Ground truth: %s%s\n', iStr(gtItem), bizName(iStr(gtItem)));

for r = 1:numel(rec)
    tag = ""; if rec(r)==gtItem, tag=" <--- hit"; end
    fprintf('%2d) %s%s%s\n', r, iStr(rec(r)), bizName(iStr(rec(r))), tag);
end

lookup_review_inline(userIdx, gtItem, jsonDir);
end

function out = conditionalName(bid,bMap)
if isKey(bMap,bid), out = " ("+bMap(bid)+")"; else, out = ""; end
end

% ---------- inline review printer -------------------------------------
function lookup_review_inline(uIdx, itemIdx, jsonDir)
load userMap.mat uStr
load itemMap.mat iStr
uID = uStr(uIdx);  bID = iStr(itemIdx);

fid = fopen(fullfile(jsonDir,'yelp_academic_dataset_review.json'),'r');
while true
    ln = fgetl(fid); if ~ischar(ln), break; end
    R = jsondecode(ln);
    if strcmp(R.user_id,uID) && strcmp(R.business_id,bID)
        fprintf('\n----- ORIGINAL REVIEW -----\n');
        fprintf('Date  : %s   Stars: %d\n\n', R.date, R.stars);
        txt = R.text;  if strlength(txt)>400, txt = txt(1:400)+" ..."; end
        fprintf('%s\n', txt);
        break
    end
end
fclose(fid);
end