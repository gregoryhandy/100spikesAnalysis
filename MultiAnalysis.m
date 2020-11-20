%% Load Experiments/Setup
clear
close all


addpath(genpath('100spikesAnalysis'), genpath('Ian Code'), genpath('analysis-code/matlab')) % will pathing
%%

[loadList, loadPath ]= uigetfile('Z:\ioldenburg\outputdata','MultiSelect','on');

%%
% loadList = loadList(15);


% allLoadList;
% oriLoadList;
% SSTOriLoadList;
% PVOriLoadList;
u19LoadList;

% loadPath = 'U:\ioldenburg\outputdata1'
% loadPath = 'C:\Users\ian\Dropbox\Adesnik\Data\outputdata1'
% loadPath = 'C:\Users\SabatiniLab\Dropbox\Adesnik\Data\outputdata1' %Ian Desktop
% loadPath = 'C:\Users\Will\Local Data\100spikes-results\outfiles-ori'
% loadPath = 'T:\Outfiles';
loadPath = 'E:\100spikes-results\outfiles-master';
%%
numExps = numel(loadList);
disp(['There are ' num2str(numExps) ' Exps in this LoadList'])
if numExps ~= 0
    clear All
    if ~iscell(loadList)
        numExps=1;
        temp = loadList;
        clear loadList;
        loadList{1} = temp;
    end
    for ind = 1:numExps
        pTime =tic;
        fprintf(['Loading Experiment ' num2str(ind) '...']);
        All(ind) = load(fullfile(loadPath,loadList{ind}),'out');
        fprintf([' Took ' num2str(toc(pTime)) 's.\n'])
    end
else
    disp('Did you press this by accident?')
end

%% Fix Known Errors
%CAUTION! ERRORS WILL OCCUR IF YOU RUN MORE THAN ONCE!
[All] = allLoadListErrorFixer(All,loadList);



%% clean Data, and create fields.

opts.FRDefault=6;
opts.recWinRange = [0.5 1.5];% %from vis Start in s [1.25 2.5];


%Stim Success Thresholds
opts.stimsuccessZ = 0.25; %0.3, 0.25 over this number is a succesfull stim
opts.stimEnsSuccess = 0.5; %0.5, fraction of ensemble that needs to be succsfull

%run Threshold
opts.runThreshold = 6 ; %trials with runspeed below this will be excluded


[All, outVars] = cleanData(All,opts);

ensStimScore        = outVars.ensStimScore;
hzEachEns           = outVars.hzEachEns;
numCellsEachEns     = outVars.numCellsEachEns;
numSpikesEachStim   = outVars.numSpikesEachStim;
percentLowRunTrials = outVars.percentLowRunTrials;
numSpikesEachEns    = outVars.numSpikesEachEns;
numSpikesEachCell   = outVars.numSpikesEachCell;

outVars.numCellsEachEnsBackup = outVars.numCellsEachEns;

names=[];
for Ind = 1:numel(All)
    names{Ind}=lower(strrep(All(Ind).out.info.mouse, '_', '.'));
end
outVars.names = names;

%% Make all dataPlots into matrixes of mean responses
%%Determine Vis Responsive and Process Correlation

opts.visAlpha = 0.05;

%oftarget risk params
opts.thisPlaneTolerance = 11.25;%7.5;%1FWHM%10; %in um;% pixels
opts.onePlaneTolerance = 22.5;%15;%2FWHM %20;
opts.distBins =  [0:25:1000]; [0:25:1000];

[All, outVars] = meanMatrixVisandCorr(All,opts,outVars); %one of the main analysis functions

visPercent = outVars.visPercent;
outVars.visPercentFromExp = visPercent;
ensIndNumber =outVars.ensIndNumber;


%% Optional: Calc pVisR from Visual Epoch [CAUTION: OVERWRITES PREVIOUS pVisR]
[All, outVars] = CalcPVisRFromVis(All,opts,outVars);
visPercent = outVars.visPercent;
outVars.visPercentFromVis = visPercent;

%% if there is a red section (will run even if not...)
[outVars] = detectShotRedCells(All,outVars);
ensHasRed = outVars.ensHasRed;

try
arrayfun(@(x) sum(~isnan(x.out.red.RedCells)),All)
arrayfun(@(x) mean(~isnan(x.out.red.RedCells)),All)
catch end
%% Identify the Experiment type for comparison or exclusion
[All,outVars] = ExpressionTypeIdentifier(All,outVars);
indExpressionType = outVars.indExpressionType;
ensExpressionType = indExpressionType(outVars.ensIndNumber);
outVars.ensExpressionType = ensExpressionType;

%% Missed Target Exclusion Criteria
%detects if too many targets were not detected in S2p
opts.FractionMissable = 0.33; %what percent of targets are missable before you exclude the ens
[outVars] = missedTargetDetector(All,outVars,opts);

ensMissedTargetF = outVars.ensMissedTargetF; %Fraction of targets per ensemble Missed
ensMissedTarget = outVars.ensMissedTarget; %Ensemble is unuseable
numMatchedTargets = outVars.numMatchedTargets;
%% main Ensembles to Use section
% ensemblesToUse = numSpikesEachEns > 75 & numSpikesEachEns <125 & highVisPercentInd & ensIndNumber~=15 & ensIndNumber~=16; %& numCellsEachEns>10 ;

numTrialsPerEns =[];numTrialsPerEnsTotal=[]; numTrialsNoStimEns=[];
for ind=1:numExps
    us=unique(All(ind).out.exp.stimID);

    for i=1:numel(us)
        trialsToUse = All(ind).out.exp.lowMotionTrials &...
            All(ind).out.exp.lowRunTrials &...
            All(ind).out.exp.stimSuccessTrial &...
            All(ind).out.exp.stimID == us(i) & ...
            (All(ind).out.exp.visID == 1 | All(ind).out.exp.visID == 0); %restrict just to no vis stim conditions

        numTrialsPerEns(end+1)=sum(trialsToUse);
        numTrialsPerEnsTotal(end+1) = sum(All(ind).out.exp.stimID == us(i));

        if i==1
            numTrialsNoStimEns(ind) = sum(trialsToUse);
        end
    end


end
numTrialsPerEns(numSpikesEachStim==0)=[];
numTrialsPerEnsTotal(numSpikesEachStim==0)=[];

%ID inds to be excluded
opts.IndsVisThreshold = 0.10; %default 0.05

highVisPercentInd = ~ismember(ensIndNumber,find(visPercent<opts.IndsVisThreshold)); %remove low vis responsive experiments
lowRunInds = ismember(ensIndNumber,find(percentLowRunTrials>0.5));

%exclude certain expression types:
uniqueExpressionTypes = outVars.uniqueExpressionTypes;
% excludedTypes = {'AAV CamK2'};
excludedTypes = {'AAV CamK2' 'Ai203'};
% excludedTypes = {'Ai203'};
% excludedTypes = {'AAV Tre'};
% excludedTypes = {};

exprTypeExclNum = find(ismember(uniqueExpressionTypes,excludedTypes));
excludeExpressionType = ismember(ensExpressionType,exprTypeExclNum);

% only include times where rate == numpulses aka the stim period is 1s.
ensembleOneSecond = outVars.numSpikesEachEns./outVars.numCellsEachEns == outVars.hzEachEns;

%spot to add additional Exclusions
excludeInds = ismember(ensIndNumber,[]); %Its possible that the visStimIDs got messed up

%Options
opts.numSpikeToUseRange = [80 120];[1 inf];[80 120];%[0 1001];
opts.ensStimScoreThreshold = 0.5; % default 0.5
opts.numTrialsPerEnsThreshold = 10; % changed from 10 by wh 4/23 for testing stuff

lowBaseLineTrialCount = ismember(ensIndNumber,find(numTrialsNoStimEns<opts.numTrialsPerEnsThreshold));


ensemblesToUse = numSpikesEachEns > opts.numSpikeToUseRange(1) ...
    & numSpikesEachEns < opts.numSpikeToUseRange(2) ...
    & highVisPercentInd ...
    & lowRunInds ...
    & ensStimScore > opts.ensStimScoreThreshold ... %so like we're excluding low success trials but if a holostim is chronically missed we shouldn't even use it
    & ~excludeInds ...
    & numTrialsPerEns > opts.numTrialsPerEnsThreshold ... ;%10;%&...
    & ~lowBaseLineTrialCount ...
    & ~ensHasRed ...
    & ~excludeExpressionType ...
    & ~ensMissedTarget ...
    & numMatchedTargets >= 3 ...
    ... & ensembleOneSecond ... %cuts off a lot of the earlier
    ;
%& numCellsEachEns>10 ;

indsSub = ensIndNumber(ensemblesToUse);
IndsUsed = unique(ensIndNumber(ensemblesToUse));

sum(ensemblesToUse)

outVars.ensemblesToUse      = ensemblesToUse;
outVars.IndsUsed            = IndsUsed;
outVars.indsSub             = indsSub;
outVars.numTrialsPerEns     = numTrialsPerEns;
outVars.highVisPercentInd    = highVisPercentInd;
outVars.lowRunInds           = lowRunInds;

%%Optional: Where are the losses comming from

disp(['Fraction of Ens correct Size: ' num2str(mean(numSpikesEachEns > opts.numSpikeToUseRange(1) & numSpikesEachEns < opts.numSpikeToUseRange(2)))]);
disp(['Fraction of Ens highVis: ' num2str(mean(highVisPercentInd))]);
disp(['Fraction of Ens lowRun: ' num2str(mean(lowRunInds))]);
disp(['Fraction of Ens high stimScore: ' num2str(mean(ensStimScore>opts.ensStimScoreThreshold))]);
disp(['Fraction of Ens high trial count: ' num2str(mean(numTrialsPerEns>opts.numTrialsPerEnsThreshold))]);
disp(['Fraction of Control Ens high trial count: ' num2str(mean(~lowBaseLineTrialCount))]);
disp(['Fraction of Ens No ''red'' cells shot: ' num2str(mean(~ensHasRed))]);
disp(['Fraction of Ens usable Expression Type: ' num2str(mean(~excludeExpressionType))]);
disp(['Fraction of Ens enough targets detected by s2p: ' num2str(mean(~ensMissedTarget))]);

disp(['Total Fraction of Ens Used: ' num2str(mean(ensemblesToUse))]);
disp([num2str(sum(ensemblesToUse)) ' Ensembles Included'])

%% Set Default Trials to Use
for ind=1:numExps
    trialsToUse = All(ind).out.exp.lowMotionTrials &...
        All(ind).out.exp.lowRunTrials &...
        All(ind).out.exp.stimSuccessTrial;% & ...
%         All(ind).out.exp.visID == 1 | ...
%         All(ind).out.exp.visID == 0;
    All(ind).out.anal.defaultTrialsToUse = trialsToUse;
end
%% Create time series plot

[All, outVars] = createTSPlot(All,outVars);
[All, outVars] = createTSPlotAllVis(All,outVars);

%% Optional group ensembles into small medium and large
numCellsEachEns = outVars.numCellsEachEnsBackup;
numCellsEachEns(numCellsEachEns < 10) = 5;
numCellsEachEns(numCellsEachEns > 10) = 20;

outVars.numCellsEachEns= numCellsEachEns;

%% set them all the same
numCellsEachEns(numCellsEachEns >0 ) = 1;
outVars.numCellsEachEns= numCellsEachEns;

%% Optional Reset ensemble grouping to default
numCellsEachEns = outVars.numCellsEachEnsBackup;
outVars.numCellsEachEns= numCellsEachEns;

%% Basic Response Plots
outVars.defaultColorMap = 'viridis';
plotAllEnsResponse(outVars)
plotResponseBySize(outVars,0)
plotPopResponseBySession(All,outVars)
plotPopResponseByExpressionType(All,outVars);
[All, outVars] = createTSPlotByEnsSize(All,outVars);
[All, outVars] = createTSPlotByEnsSizeAllVis(All,outVars);

%% Distance Response Plots
opts.distBins = 0:25:1000; 
plotResponseByDistance(outVars,opts);

%% Second more flexible way to make Distance Plots


%% Compare Distance responses
figure(102);clf

distTypes = {'min' 'geo' 'mean' 'harm'};
for i =1:4
    disp(['working on ' distTypes{i}])
    opts.distType = distTypes{i}; %options: min geo mean harm
    CellToUseVar = [];
    [popRespDist] = popDistMaker(opts,All,CellToUseVar,0);
    ax = subplot(2,2,i);
    opts.distAxisRange = [0 550]; %[0 350] is stand
    plotDistRespGeneric(popRespDist,outVars,opts,ax);
    title(distTypes{i})
end
disp('done')

%% Distance by Vis Response (will only work if consistent number of unique(visID)
plotResponseByDistanceContrast(outVars,opts); %warning won't throw an error even if you have no contrasts
%% Contrast Response Functions

opts.distBinCRF = [50:50:350]; %split Contrast Response Fun by distance
opts.visAlphaCRF = 10.05; %visAlpha for looking just at vis responsive cells;

[outVars] = plotContrastResponseFunction(All,outVars,opts);

%% Orientation Tuning and OSI

[All, outVars] = getTuningCurve(All, opts, outVars);
[All, outVars] = calcOSI(All, outVars);
[All, outVars] = calcTuningCircular(All, outVars); % note: only works on tuned cells (ie. not for max of visID=1)
[All, outVars] = getEnsembleOSI(All, outVars); % for ensembles specifically
%% plot vis things
opts.ensOSImethod = 'ensOSI';% 'ensOSI'; 'meanEnsOSI'

plotOSIdists(outVars, opts);
plotPopResponseEnsOSI(outVars, opts)

%% within pyramids cell analysis

opts.visAlpha = 0.05;
[outVars] = makeMeanRespEnsByCell(All, outVars);
[All, outVars] = compareAllCellsTuning(All, outVars, opts);
[outVars] = getRespByTuningDiff(All, outVars);



%% plot pyr cells connectivity

opts.ensXaxis = 'osi'; % order, osi, dist, corr, size...
plotCompareAllCellsTuning(outVars, opts);
opts.goodOSIthresh = 0.5;
plotResponseByDifferenceinAnglePref(outVars, opts)

%% ensemble Plots to look at


%% seperate by posNeg
[All outVars] = posNegIdentifiers(All,outVars,opts);
outVars = getRespByTuningDiffPosNeg(All, outVars);
%%
plotResponseByDiffAnglePrefPosNeg(outVars,opts);

%% ensemble tuning curve examples

OSImin = 0.5;

goodOSIens = outVars.ensCurve(2:9,outVars.ensOSI > OSImin);
goodOSIensSEM = outVars.ensCurveSEM(2:9,outVars.ensOSI > OSImin);

r = randi(size(goodOSIens,2));
figure(222)
e = errorbar(goodOSIens(:,r), goodOSIensSEM(:,r));
e.LineWidth = 1.5;
e.Color = 'k';
ylabel('ZDF')
xlabel('Orientation')
xticklabels([0:45:315])

%% Red Cell Analysis (will only run if you have the red section on all your recordings).
opts.numExamples = 5;
opts.osiThreshold4Examples = 0.5;
opts.visAlpha = 0.05;

[outVars] = plotResponseOfRedCells(All, outVars, opts);
[All, outVars] = redCellTuningAnalysis(All, outVars, opts);
[outVars] = makeMeanRespEns2(All, outVars);

%% Within Red Cell Analysis

[All, outVars] = compareRedCellsVisResp(All, outVars);
[All, outVars] = compareRedCellsTuning(All, outVars);

opts.redCellName = 'SST';
opts.redCellXaxis = 'size'; % order, osi, dist, corr, size... % correlation stuff is below, so might need to run that first if choosing corr
plotCompareRedCellVisResp(outVars, opts);
plotCompareRedCellVisTuning(outVars, opts);

%% Red cell connectivity
[outVars] = getRespByTuningDiffNotRed(All, outVars);
[outVars] = getRespByTuningDiffRed(All, outVars);
%%
opts.goodOSIthresh = 0.5;
plotResponseByDifferenceinAnglePrefRed(outVars, opts)
%%
opts.goodOSIthresh = 0;
opts.redCellName = 'SST Cells';

plotRedandPyrConnTogether(outVars, opts)

%% Red Distance section
for ind = 1:numExps
    if isfield(All(ind).out.red,'isRed')
        All(ind).out.red.notRed = ~All(ind).out.red.isRed;
    end
end

opts.distType = 'min';

CellToUseVar = 'red.isRed';
[popRespDistEnsRed] = popDistMaker(opts,All,CellToUseVar,0);
CellToUseVar = 'red.notRed';
[popRespDistEnsNotRed] = popDistMaker(opts,All,CellToUseVar,0);

figure(9);clf
ax =subplot(1,2,1);
plotDistRespGeneric(popRespDistEnsRed,outVars,opts,ax);
title('Red Cells')
ax2 = subplot(1,2,2);
plotDistRespGeneric(popRespDistEnsNotRed,outVars,opts,ax2);
title('Not Red Cells')
linkaxes([ax ax2])

%% Pos vs Neg by Distance
opts.posNegThreshold = 0.1; 
[All outVars] = posNegIdentifiers(All,outVars,opts);
opts.distType = 'min';
opts.distBins = [0:25:1000];

numEns = numel(outVars.posCellbyInd);

ensIndNumber = outVars.ensIndNumber;
ensHNumber = outVars.ensHNumber;

clear popToPlotPos popToPlotNeg
for i=1:numEns %i know its slow, but All is big so don't parfor it
    if mod(i,round(numEns/10))==1
        fprintf('.')
    end
    if outVars.ensemblesToUse(i)
    cellToUseVar = outVars.posCellbyInd{i};
    popToPlotPos(i,:) = popDistMakerSingle(opts,All(ensIndNumber(i)),cellToUseVar,0,ensHNumber(i));

     cellToUseVar = outVars.negCellbyInd{i};
    popToPlotNeg(i,:) = popDistMakerSingle(opts,All(ensIndNumber(i)),cellToUseVar,0,ensHNumber(i));

    else
        popToPlotPos(i,:) = nan([numel(opts.distBins)-1 1]);
        popToPlotNeg(i,:) = nan([numel(opts.distBins)-1 1]);
    end
end
disp('Done')

%%Plot Dist REsp
figure(10);clf
opts.distAxisRang = [0 350];

ax =subplot(1,2,1);
plotDistRespGeneric(popToPlotPos,outVars,opts,ax);
title('Cells that go up')
ax2 =subplot(1,2,2);
plotDistRespGeneric(popToPlotNeg,outVars,opts,ax2);
title('Cells That go down')
% linkaxes([ax ax2]);
% xlim([0 250])
%% Distance of Ensemble
[All, outVars] = defineDistanceTypes(All, outVars);
plotEnsembleDistanceResponse(outVars,100,1)
%% Correlation Pick One. Option A. Vis activity from interleaved Trials
%Functions are Mutually Exclusive.
[All, outVars] = defineCorrelationTypes(All,outVars); %Caution this and below are mutually exclusive
plotEnsembleCorrelationResponse(outVars,200,1);

opts.CorrSpace = linspace(-0.5,0.5,40);
opts.CorrToPlot = 'SpontCorr'; % Options are: 'SpontCorr' 'AllCorr' AllMCorr' 'SignalCorr' and 'NoiseCorr'
[outVars] = plotCorrelationResponse(All,outVars,opts);
%% Correlation Pick One. Option B. Vis Activity from out.vis epoch
[All, outVars] = defineCorrelationTypesOnVis(All, outVars); %Caution this and above are mutually exclusive
plotEnsembleCorrelationResponse(outVars,300,1)

opts.CorrSpace = linspace(-0.2,0.2,40);
opts.CorrToPlot = 'AllCorr'; % Options are: 'SpontCorr' 'AllCorr' AllMCorr' 'SignalCorr' and 'NoiseCorr'
[outVars] = plotCorrelationResponse(All,outVars,opts);

%% Seperate Correlation by Pos and Neg

opts.CorrSpace = linspace(-0.5,0.5,40);linspace(-1,1,40);%
opts.CorrToPlot = 'NoiseCorr'; % Options are: 'SpontCorr' 'AllCorr' AllMCorr' 'SignalCorr' and 'NoiseCorr'

numEns = numel(outVars.posCellbyInd);

ensIndNumber = outVars.ensIndNumber;
ensHNumber = outVars.ensHNumber;

clear popToPlotPos popToPlotNeg
for i=1:numEns %i know its slow, but All is big so don't parfor it
    if mod(i,round(numEns/10))==1
        fprintf('.')
    end
    if outVars.ensemblesToUse(i)
    cellToUseVar = outVars.posCellbyInd{i} ;
    popToPlotCorrPos(i,:) = popCorrMakerSingle(opts,All(ensIndNumber(i)),cellToUseVar,0,ensHNumber(i));

     cellToUseVar = outVars.negCellbyInd{i};
    popToPlotCorrNeg(i,:) = popCorrMakerSingle(opts,All(ensIndNumber(i)),cellToUseVar,0,ensHNumber(i));

    else
        popToPlotCorrPos(i,:) = nan([numel(opts.CorrSpace)-1 1]);
        popToPlotCorrNeg(i,:) = nan([numel(opts.CorrSpace)-1 1]);
    end
end
disp('Done')

figure(11);clf
ax =subplot(1,2,1);
plotRespGeneric(popToPlotCorrPos,opts.CorrSpace,outVars,opts,ax);
title('Cells that go up')
ax2 =subplot(1,2,2);
plotRespGeneric(popToPlotCorrNeg,opts.CorrSpace,outVars,opts,ax2);
title('Cells That go down')

%% 2D Ensemble Response Plot
opts.distType = 'min';
[outVars] = grandDistanceMaker(opts,All,outVars);

distRange = [50 150];%[50 150];
for i = 1:numEns
    responseToPlot(i) = nanmean(outVars.mRespEns{i}(...
        outVars.distToEnsemble{i}>=distRange(1) & ...
        outVars.distToEnsemble{i}<distRange(2) & ...
        ~outVars.offTargetRiskEns{i} ));
end
% responseToPlot = outVars.popResponseEns; %outVars.mRespEns;
yToPlot = outVars.ensOSI;
xToPlot = outVars.ensMaxD;

ensemblesToUse = outVars.ensemblesToUse & outVars.numMatchedTargets>2 ;%& outVars.numMatchedTargets<12;

figure(142);clf
scatter(xToPlot(ensemblesToUse),yToPlot(ensemblesToUse),100,responseToPlot(ensemblesToUse),'filled');
colormap(puor)
colorbar
caxis([-0.1 0.1])
xlabel({'Span of Ensemble (\mum)' ' (i.e. max distance between targets)'})
ylabel('Ensemble OSI')


%% Plot Sorted Cell Response

ensemblesToUse = outVars.ensemblesToUse & outVars.numMatchedTargets>=3;% & outVars.numCellsEachEns==10  & outVars.ensOSI>0.5 ;
yToPlot = outVars.ensMaxD; %outVars.ensOSI; outVars.numCellsEachEns;outVars.ensOSI;

numpts =1000;

distRange = [50 150];[0 inf];[0 50];%[50 150];
sortedCellResp = [];
for i = 1:numEns
    fprintf('.');
    if mod(i,100)==0;
        disp(' ')
    end
    cellsToUse =         outVars.distToEnsemble{i}>=distRange(1) & ...
        outVars.distToEnsemble{i}<distRange(2) & ...
        ~outVars.offTargetRiskEns{i};
    if sum(cellsToUse)<2
        temp = [NaN NaN];
    else
        temp = outVars.mRespEns{i}(cellsToUse);
        temp = sort(temp);
    end
    sortedCellResp(i,:) = interp1(1:numel(temp),temp,linspace(numel(temp),1,numpts));
end
disp('done')

ensemblesToUseList = find(ensemblesToUse);

[s sidx] = sort(yToPlot(ensemblesToUse)) ;
sortedEnsList = ensemblesToUseList(sidx); 

datToPlot = sortedCellResp(sortedEnsList,:);
figure(143);clf
imagesc(datToPlot')
colormap(rdbu)
caxis([-1 1])

xticks([1 numel(s)])
xticklabels({'Close' 'Far'})
yticks([])
ylabel('Cell Response Sorted')
xlabel('Span of Ensemble')
colorbar
box off
%% Plot Distance Curves in different Ori Bands

opts.posNegThreshold = 0.1; 
[All outVars] = posNegIdentifiers(All,outVars,opts);
opts.distType = 'min';
opts.distBins = [0:25:400];

ensemblesToUse = outVars.ensemblesToUse & outVars.numMatchedTargets>=3 & outVars.ensOSI>0.5;% & outVars.numCellsEachEns==10   ;

oriVals = [NaN 0:45:315];
% numEns = numel(outVars.posCellbyInd);

ensIndNumber = outVars.ensIndNumber;
ensHNumber = outVars.ensHNumber;

clear popToPlot
for i=1:numEns %i know its slow, but All is big so don't parfor it
    if mod(i,round(numEns/10))==1
        fprintf('.')
    end
    if ensemblesToUse(i)
        ind = ensIndNumber(i);
        
       cellOris = oriVals(outVars.prefOris{ind});
       cellOrisDiff = cellOris-outVars.ensPO(i);
       
       diffsPossible = [0 45 90 135 180];
       
    cellToUseVar = ~outVars.offTargetRiskEns{i}...
        & outVars.pVisR{ind} <0.05 ...
        & outVars.osi{ind} > 0.5 ...
        ;
    
    for k=1:numel(diffsPossible)
        popToPlot(i,:,k) = popDistMakerSingle(opts,All(ensIndNumber(i)),cellToUseVar & abs(cellOrisDiff)==diffsPossible(k),0,ensHNumber(i));
    end
    
    



    else
        popToPlot(i,:,:) = nan([numel(opts.distBins)-1 1 5]);
    end
end
disp('Done')

%%Plot Dist REsp
figure(10);clf
opts.distAxisRang = [0 350];

% ax =subplot(1,1,1);
%  hold on
clear ax
for k = 1:5
    ax(k) =subplot(1,5,k);
title(['Cells Pref Angle \Delta' num2str(diffsPossible(k)) '\circ'])
plotDistRespGeneric(popToPlot(:,:,k),outVars,opts,ax(k));
end
linkaxes(ax)
xlim([0 400])
ylim([-0.1 0.15])
% title('Cells by Tuning')
% ax2 =subplot(1,2,2);
% plotDistRespGeneric(popToPlotNeg,outVars,opts,ax2);
% title('Cells That go down')

%% 2D Plot Maker Corr vs Distance

opts.CorrSpace =linspace(-0.2,0.3,21); %linspace(-0.2,0.3,41);
opts.CorrToPlot = 'AllCorr'; % Options are: 'SpontCorr' 'AllCorr' AllMCorr' 'SignalCorr' and 'NoiseCorr'

opts.distType = 'min';
opts.distBins = linspace(0,600,41);% linspace(0,600,91);% [0:25:600];

numEns = numel(outVars.posCellbyInd);
ensIndNumber = outVars.ensIndNumber;
ensHNumber = outVars.ensHNumber;

clear popResp2D numResponders
for i=1:numEns %i know its slow, but All is big so don't parfor it
    if mod(i,round(numEns/10))==1
        fprintf('.')
    end
    if outVars.ensemblesToUse(i)
        cellToUseVar = [];outVars.negCellbyInd{i} ;%outVars.posCellbyInd{i} ;
        [popResp2D(i,:,:) numResponders(i,:,:)] = distCorr2DSingle(opts,All(ensIndNumber(i)),cellToUseVar,0,ensHNumber(i));
    else
        popResp2D(i,:,:) = nan([numel(opts.CorrSpace)-1 numel(opts.distBins)-1]);
        numResponders(i,:,:) = nan([numel(opts.CorrSpace)-1 numel(opts.distBins)-1]);
    end
end
disp('done')

%%


colormaptouse = 'rdbu';
climTouse = [-0.2 0.2];%[-0.25 0];%[-0.2 0.2]; %color to use, set this or below to [] to skip.
cprctile = [5 95]; %or both to 0 to auto
xSpcing = 3;12;
ySpcing = 2;4;

numCellsEachEns = outVars.numCellsEachEns;
ensemblesToUse = outVars.ensemblesToUse;

figure(13);clf
subplot(1,2,1)
imagesc(squeeze(nanmean(popResp2D,1)));
colormap(colormaptouse)

if ~isempty(climTouse)
    caxis(climTouse)
end
ylabel('Correlation')
xlabel('Distance \mum')
xticks(1:xSpcing:numel(opts.distBins))
xticklabels(opts.distBins(1:xSpcing:end))
yticks(1:ySpcing:numel(opts.CorrSpace))
yticklabels(opts.CorrSpace(1:ySpcing:end))

subplot(1,2,2)
imagesc(log10(squeeze(nansum(numResponders,1))));
colormap(colormaptouse)
% caxis([-0.1 0.1])
ylabel('Correlation')
xlabel('Distance \mum')
xticks(1:xSpcing:numel(opts.distBins))
xticklabels(opts.distBins(1:xSpcing:end))
yticks(1:ySpcing:numel(opts.CorrSpace))
yticklabels(opts.CorrSpace(1:ySpcing:end))
h = colorbar;
set(get(h,'label'),'string','Log Number of Sources per Pixel');

figure(16);clf
numSzs = numel(unique(numCellsEachEns(ensemblesToUse)));
szs = unique(numCellsEachEns(ensemblesToUse));

clear ax
for i=1:numSzs
    ax(i) = subplot(1,numSzs,i);
    datToPlot = squeeze(nanmean(popResp2D(numCellsEachEns==szs(i),:,:),1));
    imagesc(datToPlot);
    colormap(colormaptouse)
    if ~isempty(climTouse)
        caxis(climTouse)
    elseif ~isempty(cprctile)
        caxis([prctile(datToPlot(:),cprctile(1)) prctile(datToPlot(:),cprctile(2))]);
    end
    ylabel('Correlation')
    xlabel('Distance \mum')
    xticks(1:xSpcing:numel(opts.distBins))
    xticklabels(opts.distBins(1:xSpcing:end))
    yticks(1:ySpcing:numel(opts.CorrSpace))
    yticklabels(opts.CorrSpace(1:ySpcing:end))

    title(['Ensemble of Size ' num2str(szs(i))]);
end
    linkaxes(ax)
h = colorbar;
set(get(h,'label'),'string','Avg. \Delta Z-Score dF/F');

%% Sparsity

plotSparsityBySize(All,outVars)


%% Stim Rate vs Pop Response
 plotPopRespByStimRate(outVars)
