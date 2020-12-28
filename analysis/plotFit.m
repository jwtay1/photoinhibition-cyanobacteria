wtID = 30;
cpcID = 86;

wt_length = [S1.Tracks(wtID).Data.MajorAxisLength{:}] * S1.FileMetadata.PhysicalPxSize(1);
wtFrames = (1:numel(wt_length)) * 30;

wt_fitted = S1.Tracks(wtID).GRFitY * exp(S1.Tracks(wtID).GrowthRate * wtFrames);

plot(wtFrames, wt_length, 'o', wtFrames, wt_fitted);



cpc_length = S1.Tracks(cpcID).MajorAxisLength * S1.FileMetadata.PhysicalPxSize(1);
cpcFrames = (1:numel(cpc_length)) * 30;

