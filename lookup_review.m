function lookup_review(matPath,row,jsonDir,printText)

% LOOKUP_REVIEW  Show the original Yelp review for a given split row.
%
%   lookup_review(matPath, rowIdx, jsonDir)
%   lookup_review(matPath, rowIdx, jsonDir, true)   % also print full text
%
% INPUT
%   matPath : 'train.mat' | 'val.mat' | 'test.mat'
%   rowIdx  : 1-based index of the row to inspect
%   jsonDir : folder that contains *yelp_academic_dataset_review.json*
%   printText (optional, default = false)
%             when true, the entire review text is printed.
%
% The function converts the internal user/item indices back to the
% original Yelp IDs using the dictionaries saved by *preprocess_yelp*,
% then scans the review JSON file until the matching record is found.
% ---------------------------------------------------------------------

if nargin<4, printText=false; end
load(matPath,'U','V');
load userMap.mat uStr
load itemMap.mat iStr
uID = uStr(U(row));  iID = iStr(V(row));

fid = fopen(fullfile(jsonDir,'yelp_academic_dataset_review.json'));
while true
    ln = fgetl(fid);
    if ~ischar(ln), error('Review not found'); end
    r = jsondecode(ln);
    if strcmp(r.user_id,uID) && strcmp(r.business_id,iID)
        fprintf('\nUser  : %s\nItem  : %s\nDate  : %s\nStars : %d\n',...
                uID,iID,r.date,r.stars);
        if printText, fprintf('\n%s\n',r.text); end
        break
    end
end
fclose(fid);
end