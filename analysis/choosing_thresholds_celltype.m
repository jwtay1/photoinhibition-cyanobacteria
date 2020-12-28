%Script to choose threshold to identify cell types (WT or deltaCPC)
if ~exist('S1', 'var')
    loaddataphotoinhibition;
end

%%
%Looking at the series1_merged data (reprocessed)
cpcCellIDs_S1 = [5, 7, 3, 6, 22, 23];
WTcellIDs_S1 = [1, 2, 11, 12, 19, 29, 30, 31];

cpcCellIDs_S17 = [4, 30, 25, 28, 29, 9, 12, 11, 15, 18, 3, 14, 17];
WTcellIDs_S17 = [26, 27, 33, 13, 19, 20, 21];

cpcCellIDs_S20 = [17, 18, 19, 9, 3];
WTcellIDs_S20 = [16, 71, 70, 49, 45, 26, 27];

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
xlabel('Mean phycobilisome intensity')
ylabel('Number of cells')