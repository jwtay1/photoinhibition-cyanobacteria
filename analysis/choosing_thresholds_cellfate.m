%Script to choose threshold to identify cells which are dead/alive at the
%end of the movie
if ~exist('S1', 'var')
    loaddataphotoinhibition;
end

%%
alive_cpc_cellIDs_S17 = [162 

%We only really care about the intensity at the first time point
rfp_cpc = [S1.Tracks(cpcCellIDs_S1).RFPInit, ...
    S17.Tracks(cpcCellIDs_S17).RFPInit, ...
    S20.Tracks(cpcCellIDs_S20).RFPInit];

rfp_WT = [S1.Tracks(WTcellIDs_S1).RFPInit, ...
    S17.Tracks(WTcellIDs_S17).RFPInit, ...
    S20.Tracks(WTcellIDs_S20).RFPInit];

binEdges = linspace(200, 800, 15);

histogram(rfp_WT, 'BinEdges', binEdges);
hold on
histogram(rfp_cpc, 'BinEdges', binEdges);
hold off
legend('WT', '\Deltacpc')
xlabel('Mean RFP Intensity/cell')
ylabel('Number of cells')