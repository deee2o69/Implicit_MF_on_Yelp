function show_split_head(matPath,n)
if nargin<2, n=5; end
S = load(matPath);
rows = 1:min(n,numel(S.U));
T = table(S.U(rows),S.V(rows),S.C(rows,1),S.C(rows,2),S.C(rows,3),S.C(rows,4),S.C(rows,5),...
          S.cid(rows),...
          'VariableNames',{'U','V','c_city','c_year','c_month','c_DoW','c_last','cid'});
disp(T)
end