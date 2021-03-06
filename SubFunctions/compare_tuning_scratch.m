% function [All, outVars] = compareRedCellsTuning(All, outVars)

clear coTunedRedResp notCoTunedRedResp coTunedRedEnsResp notCoTunedRedEnsResp temp resp

mRespRed = outVars.mRespRed; % {expt}(cells, ensemble)
umouse = outVars.uMouse; % which mouse/expt each ensemble belongs to
ensTunings = outVars.ensPO;
uEnsTunings = rmmissing(unique(outVars.ensPO)); % must have > Matlab2018-ish to nix nans this way

% maybe make a table so it's easier?

% find ensembles per mouse
mice = diff([0, find(diff(umouse)), numel(umouse)]);

% make mRespEns a cell array by animal so it's easier to index
% mRespRed is {expt}(redCell, ensemble)
mRespRed = cellfun(@cell2mat, mat2cell(mRespRed, 1, mice), 'un', 0);
ensTunings = arrayfun(@cell2mat, mat2cell(ensTunings, 1, mice), 'un', 0);

for ind = 1:numel(All)
    
    % red cell tuning is an arr of tunings, the length of redVisCells,
    % but we want their positional index out of all red cells so we can
    % then index into mRespRed
    redCells = find(All(ind).out.red.isRed); % all red cells logical arr (used to get index)
    redVisCells = All(ind).out.red.isVisCells; % red and vis responsive cells, logical arr
    redVisIdx = find(ismember(redCells, redVisCells));
    redCellTuning = All(ind).out.red.redTuningOri;
    
    % nans will show up as not-co-tuned but are visually responsive
    % but they won't appear as a 'tuning' because they are removed as a
    % uniquely shot tuning
    isCoTuned = redVisIdx(ismember(redCellTuning, tuning));
    isNotCoTuned = redVisIdx(~ismember(redCellTuning, tuning));
    isNotVisResp = ~ismember(redCells, redVisCells);
    
    % so now we have a way to index into mRespRed to get co-tuned resps etc
    % how best to store data?
    

    
    for tune = 1:numel(uEnsTunings)
        tuning = uEnsTunings(tune);
        ensTuned = ensTunings{ind} == tuning;
        
        allEnsResp{ind}(tune, :) = nanmean(mRespRed{ind}, 1);
        allEnsResp{ind}(tune, ~ensTuned) = nan;
        
        notVisResp{ind}(tune, :) = nanmean(mRespRed{ind}(isNotVisResp, :), 1);
        notVisResp{ind}(tune, ~ensTuned) = nan;
        
        coTunedRedResp{ind}(tune, :) = nanmean(mRespRed{ind}(isCoTuned, :), 1);
        coTunedRedResp{ind}(tune, ~ensTuned) = nan;
        
        notCoTunedRedResp{ind}(tune, :) = nanmean(mRespRed{ind}(isNotCoTuned, :), 1);
        notCoTunedRedResp{ind}(tune, ~ensTuned) = nan;
        
    end
    
    allEnsResp{ind} = nanmean(allEnsResp{ind}, 1);
    notVisResp{ind} = nanmean(notVisResp{ind}, 1);
    coTunedRedResp{ind} = nanmean(coTunedRedResp{ind}, 1);
    notCoTunedRedResp{ind} = nanmean(notCoTunedRedResp{ind}, 1);
   
end

outVars.allRedEnsResp = cell2mat(allEnsResp);
outVars.coTunedRedEnsResp = cell2mat(coTunedRedResp);
outVars.notCoTunedRedEnsResp = cell2mat(notCoTunedRedResp);
outVars.notVisRespRedEnsResp = cell2mat(notVisRespRedResp);



