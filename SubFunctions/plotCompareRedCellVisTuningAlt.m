function plotCompareRedCellVisTuningAlt(outVars, opts)

by = opts.redCellXaxis;
cellname = opts.redCellName;

ensemblesToUse = outVars.ensemblesToUse;
popRespCoTuned = outVars.coTunedRedEnsResp(ensemblesToUse);
popRespOrthoTuned = outVars.orthoTunedRedEnsResp(ensemblesToUse);
popRespNotCoTuned = outVars.notCoTunedRedEnsResp(ensemblesToUse);
popRespNotVisResp = outVars.notVisRespRedEnsResp(ensemblesToUse);
allRedRespEns = outVars.allRedEnsResp;

switch by
    case 'order'
        x = 1:numel(popRespCoTuned);
        xname = 'Order of Being Done';
    case 'osi'
        x = outVars.ensOSI(ensemblesToUse);
        xname = 'Ensemble OSI';
    case 'dist'
        x = outVars.ensMeaD(ensemblesToUse);
        xname = 'Ensemble Mean Distance';
    case 'maxdist'
        x = outVars.ensMaxD(ensemblesToUse);
        xname = 'Ensemble Max Distance';
    case 'mindist'
        x = outVars.ensMinD(ensemblesToUse);
        xname = 'Ensemble Min Distance';
    case 'corr'
        x = outVars.ensAlCo(ensemblesToUse);
        xname = 'Ensemble All Corr';
    case 'size'
        x = outVars.numCellsEachEns(ensemblesToUse);
        xname = 'Ensemble Size';
end

f1 = figure(300);
clf
colormap(f1, 'viridis')

subplot (1,2,1)
s1 = scatter(x, popRespCoTuned, 'filled', 'MarkerFaceAlpha', 0.7);
hold on
s2 = scatter(x, popRespOrthoTuned, 'filled', 'MarkerFaceAlpha', 0.7);
% s3 = scatter(x, popRespNotCoTuned, 'filled', 'MarkerFaceAlpha', 0.7);
% s4 = scatter(x, popRespNotVisResp, 'filled', 'MarkerFaceAlpha', 0.7);


title({'Mean Population Response',cellname})
xlabel(xname)
ylabel([cellname ' Population Mean Response'])
% title('OSIs by Ensemble Size')
% set(gcf(),'Name','OSIs by Ensemble Size')
% % cb = colorbar('Ticks', unique(numCellsEachEns));
% % cb.Label.String = 'Number of Cells in Ensemble';
r = refline(0);
r.LineStyle =':';
% legend([s1, s2, s3, s4], {'Co-Tuned', 'Ortho-Tuned', 'Not Co-Tuned', sprintf('Not Vis\nResponsive')})
legend([s1, s2], {'Co-Tuned','Ortho-Tuned'})

% 
% subplot(1,3,2)
% 
% cats = categorical({'Co-Tuned', 'Ortho Tuned', 'Not Co-Tuned', 'Not Vis Resp', 'All'});
% cats = reordercats(cats, {'Co-Tuned', 'Ortho Tuned', 'Not Co-Tuned', 'Not Vis Resp', 'All'});
% data = [nanmean(popRespCoTuned) nanmean(popRespOrthoTuned) nanmean(popRespNotCoTuned) nanmean(popRespNotVisResp) nanmean(allRedRespEns)];
% sems = [sem2(popRespCoTuned, 2) sem2(popRespOrthoTuned, 2) sem2(popRespNotCoTuned, 2) sem2(popRespNotVisResp, 2) sem2(allRedRespEns, 2)];
% 
% bar(cats, data);
% nbars = 1:numel(data);
% 
% hold on
% 
% er = errorbar(nbars, data, sems);    
% er.Color = [0 0 0];                            
% er.LineStyle = 'none';
% er.LineWidth = 1;
% 
% title({'Pop Response To Ensemble', cellname})
% ylabel('Mean Population Response')
% xtickangle(45)

subplot(1,2,2)

fancyPlotSpread({popRespCoTuned; popRespOrthoTuned; popRespNotCoTuned}', ...
                    {'Co-Tuned', 'OrthoTuned', 'Not Co-Tuned'});
title({'Pop Response To Ensemble',cellname})
ylabel('Mean Population Response')
xtickangle(45)


%%----Not Red Cells----%%


ensemblesToUse = outVars.ensemblesToUse;
popRespCoTuned = outVars.coTunedOtherEnsResp(ensemblesToUse);
popRespOrthoTuned = outVars.orthoTunedOtherEnsResp(ensemblesToUse);
popRespNotCoTuned = outVars.notCoTunedOtherEnsResp(ensemblesToUse);
popRespNotVisResp = outVars.notVisRespOtherEnsResp(ensemblesToUse);
allOtherEnsResp = outVars.allOtherEnsResp;

switch by
    case 'order'
        x = 1:numel(popRespCoTuned);
        xname = 'Order of Being Done';
    case 'osi'
        x = outVars.ensOSI(ensemblesToUse);
        xname = 'Ensemble OSI';
    case 'dist'
        x = outVars.ensMeaD(ensemblesToUse);
        xname = 'Ensemble Mean Distance';
    case 'maxdist'
        x = outVars.ensMaxD(ensemblesToUse);
        xname = 'Ensemble Max Distance';
    case 'mindist'
        x = outVars.ensMinD(ensemblesToUse);
        xname = 'Ensemble Min Distance';
    case 'corr'
        x = outVars.ensAlCo(ensemblesToUse);
        xname = 'Ensemble All Corr';
    case 'size'
        x = outVars.numCellsEachEns(ensemblesToUse);
        xname = 'Ensemble Size';
end

f2 = figure(510);
clf
colormap(f2, 'viridis')

subplot (1,2,1)
s1 = scatter(x, popRespCoTuned, 'filled', 'MarkerFaceAlpha', 0.7);
hold on
s2 = scatter(x, popRespOrthoTuned, 'filled', 'MarkerFaceAlpha', 0.7);
% s3 = scatter(x, popRespNotCoTuned, 'filled', 'MarkerFaceAlpha', 0.7);
% s4 = scatter(x, popRespNotVisResp, 'filled', 'MarkerFaceAlpha', 0.7);

title({'Mean Population Response','Pyramidal Cells'})
xlabel(xname)
ylabel({'Pyramidal Cell Population Mean Response'})
% title('OSIs by Ensemble Size')
% set(gcf(),'Name','OSIs by Ensemble Size')
% % cb = colorbar('Ticks', unique(numCellsEachEns));
% % cb.Label.String = 'Number of Cells in Ensemble';
r = refline(0);
r.LineStyle =':';
% legend([s1, s2, s3, s4], {'Co-Tuned', 'Ortho Tuned', 'Not Co-Tuned', sprintf('Not Vis\nResponsive')})
legend([s1, s2], {'Co-Tuned','Ortho Tuned'})
% 
% subplot(1,3,2)
% 
% cats = categorical({'Co-Tuned', 'Ortho Tuned', 'Not Co-Tuned', 'Not Vis Resp', 'All'});
% cats = reordercats(cats, {'Co-Tuned', 'Ortho Tuned', 'Not Co-Tuned', 'Not Vis Resp', 'All'});
% data = [nanmean(popRespCoTuned) nanmean(popRespOrthoTuned, 2) nanmean(popRespNotCoTuned) nanmean(popRespNotVisResp) nanmean(allOtherEnsResp)];
% sems = [sem2(popRespCoTuned, 2) nanmean(popRespOrthoTuned, 2) sem2(popRespNotCoTuned, 2) sem2(popRespNotVisResp, 2) sem2(allOtherEnsResp, 2)];
% 
% bar(cats, data);
% nbars = 1:numel(data);
% 
% hold on
% 
% er = errorbar(nbars, data, sems);    
% er.Color = [0 0 0];                            
% er.LineStyle = 'none';
% er.LineWidth = 1;
% 
% title({'Pop Response To Ensemble','Pyramidal Cells'})
% ylabel('Mean Population Response')
% xtickangle(45)

subplot(1,2,2)

fancyPlotSpread({popRespCoTuned; popRespOrthoTuned; popRespNotCoTuned}', ...
                    {'Co-Tuned', 'Ortho Tuned', 'Not Co-Tuned'});
title({'Pop Response To Ensemble','Pyramidal Cells'})
ylabel('Mean Population Response')
xtickangle(45)


pval = anova1([popRespCoTuned; popRespOrthoTuned; popRespNotCoTuned]', [], 'off');
disp(['ANOVA across conditions: ' num2str(pval)])

[~, pval] = ttest2(popRespCoTuned, popRespNotCoTuned);
disp(['Ttest iso vs not: ' num2str(pval)])