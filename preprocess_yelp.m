function preprocess_yelp(jsonDir,nLines)
% PREPROCESS_YELP  —  creates train/val/test
%
%   preprocess_yelp(jsonDir)            % whole dataset
%   preprocess_yelp(jsonDir,80000)      % only 80k lines (demo)
%
%  →   train.mat  val.mat  test.mat   (U,V,C,cid)
%  →   userMap.mat   itemMap.mat      (string array: idx → original ID)
%
%  C = [c_city  c_year  c_month  c_DoW  c_last]

if nargin<2 || isempty(nLines); nLines = inf; end
rng(2022);                                 % seed for reproducibility

% ---------- 1.  city map ------------------------------------------------
bizPath = fullfile(jsonDir,'yelp_academic_dataset_business.json');
bizLines = read_n_lines(bizPath,nLines);
nb = numel(bizLines);
bizID = strings(nb,1);  city = bizID;
for i = 1:nb
    B = jsondecode(bizLines{i});
    bizID(i) = string(B.business_id);
    city(i)  = string(B.city);
end
[~,~,cityIdx] = unique(city,'stable');
cityMap = containers.Map(bizID,uint32(cityIdx));

% ---------- 2.  reviews -------------------------------------------------
revPath = fullfile(jsonDir,'yelp_academic_dataset_review.json');
revLines = read_n_lines(revPath,nLines);
nr = numel(revLines);
uRaw = strings(nr,1);  iRaw = uRaw;  tSt = NaT(nr,1);
for i = 1:nr
    R = jsondecode(revLines{i});
    uRaw(i) = string(R.user_id);
    iRaw(i) = string(R.business_id);
    tSt(i)  = datetime(R.date,'InputFormat','yyyy-MM-dd HH:mm:ss');
end

% ---------- 3.  filter ≥10 reviews ----------------------------------
[~,~,uTmp] = unique(uRaw,'stable');
keep = accumarray(uTmp,1) >= 10;
uRaw = uRaw(keep);  iRaw = iRaw(keep);  tSt = tSt(keep);
assert(~isempty(uRaw),'Nessun dato dopo il filtro ≥10.');

% ---------- 4.  remap (1-based) --------------------------------
[uStr,~,U] = unique(uRaw,'stable');  U = uint32(U);
[iStr,~,V] = unique(iRaw,'stable');  V = uint32(V);
save userMap.mat uStr
save itemMap.mat iStr

% ---------- 5. timestamp order -----------------------------------
[~,ord] = sort(tSt);
U = U(ord);  V = V(ord);  iRaw = iRaw(ord);  tSt = tSt(ord);

% ---------- 6.  context matrix ----------------------------
n = numel(U);
c_last = zeros(n,1,'uint32');
for k = 2:n
    if U(k)==U(k-1);  c_last(k)=V(k-1);  end
end
c_city  = zeros(n,1,'uint32');
mask    = isKey(cityMap,cellstr(iRaw));
c_city(mask) = cell2mat(cityMap.values(cellstr(iRaw(mask))));
c_year  = uint32(year(tSt));
c_month = uint32(month(tSt));
c_dow   = uint32(weekday(tSt,'dayofweek')-1);   % 0 = monday
C = [c_city c_year c_month c_dow c_last];

cidStr = strcat(string(c_city),'-',string(c_year),'-',string(c_month),'-', ...
                string(c_dow),'-',string(c_last));
[~,~,cid] = unique(cidStr,'stable');  cid = uint32(cid);

% ---------- 7.  leave-one-out split -----------------------------------
flag = zeros(n,1,'uint8');           % 0 = train
lastIdx = [find(diff(U)); n];  flag(lastIdx) = 2;   % test
secIdx  = lastIdx - 1;  secIdx(secIdx<1) = [];  flag(secIdx) = 1; % val

save_split('train.mat',U,V,C,cid,flag==0);
save_split('val.mat',  U,V,C,cid,flag==1);
save_split('test.mat', U,V,C,cid,flag==2);

fprintf('OK | users %d  items %d  train %d  val %d  test %d\n',...
        numel(uStr), numel(iStr), sum(flag==0), sum(flag==1), sum(flag==2));
end

% ======================================================================
function lines = read_n_lines(path,maxN)

fid = fopen(path,'r');  lines = {};  k = 0;
while k < maxN
    ln = fgetl(fid);  if ~ischar(ln); break; end
    k = k + 1;  lines{k,1} = ln;                 %#ok<AGROW>
end
fclose(fid);
end

function save_split(fname,U,V,C,cid,mask)
S = struct('U',U(mask),'V',V(mask),'C',C(mask,:),'cid',cid(mask));
save(fname,'-struct','S','-v7');
end