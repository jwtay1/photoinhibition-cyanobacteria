ppDistTime_cpc = [];
ppDistTime_WT = [];

storeMaxChlInt_WT = [];
storeMaxChlInd_WT = [];

storeMaxPcbInt_WT = [];
storeMaxPcbInd_WT = [];

storeMaxChlInt_cpc = [];
storeMaxChlInd_cpc = [];

storeMaxPcbInt_cpc = [];
storeMaxPcbInd_cpc = [];

for iL = 1:numel(S20.Lineages)
    
    if numel(S20.Lineages(iL).IDs) >= 2
        
        %Concatenate
        combinedCy5 = [];
        combinedRFP = [];
        for ii = 1:numel(S20.Lineages(iL).IDs)
            
            cy5 = [S20.Tracks(S20.Lineages(iL).IDs(ii)).Data.MeanCy5{:}];
            
            combinedCy5 = [combinedCy5 cy5];
            
            rfp = [S20.Tracks(S20.Lineages(iL).IDs(ii)).Data.MeanRFP{:}];
            combinedRFP = [combinedRFP rfp];           
           
        end
          
        %Find peak to peak distance
        [maxChlInt, maxChlInd] = max(combinedCy5);
        [maxPcbInt, maxPcbInd] = max(combinedRFP);
        
        ppDist = maxPcbInd - maxChlInd;
        
        %Plot
%         plot(1:numel(combinedCy5), combinedCy5, ...
%             maxChlInd, combinedCy5(maxChlInd), 'bo', ...
%             1:numel(combinedRFP), combinedRFP, ...
%             maxPcbInd, combinedRFP(maxPcbInd), 'ro');
%         
%         keyboard            
        
        ppDistTime = ppDist * 30;
        
        if strcmpi(S20.Lineages(iL).Type, 'WT')
            
            ppDistTime_WT = [ppDistTime_WT, ppDistTime];
            storeMaxChlInt_WT = [storeMaxChlInt_WT, maxChlInt];
            storeMaxChlInd_WT = [storeMaxChlInd_WT, maxChlInd];
            
            storeMaxPcbInt_WT = [storeMaxPcbInt_WT, maxPcbInt];
            storeMaxPcbInd_WT = [storeMaxPcbInd_WT, maxPcbInd];
            
        elseif strcmpi(S20.Lineages(iL).Type, 'cpc')
            
            ppDistTime_cpc = [ppDistTime_cpc, ppDistTime];
            storeMaxChlInt_cpc = [storeMaxChlInt_cpc, maxChlInt];
            storeMaxChlInd_cpc = [storeMaxChlInd_cpc, maxChlInd];
            
            storeMaxPcbInt_cpc = [storeMaxPcbInt_cpc, maxPcbInt];
            storeMaxPcbInd_cpc = [storeMaxPcbInd_cpc, maxPcbInd];
            
        end        
        
    end
    
    
end


subplot(1,2,1)
plot(ppDistTime_WT)

subplot(1,2,2)
plot(ppDistTime_cpc)

%%

figure(2)
subplot(1,2,1)
plot(S20.FileMetadata.Timestamps(storeMaxChlInd_WT)/3600, storeMaxChlInt_WT, 'bo',S20.FileMetadata.Timestamps(storeMaxPcbInd_WT)/3600, storeMaxChlInt_WT, 'ro')
xlim([0 35])

subplot(1,2,2)
plot(S20.FileMetadata.Timestamps(storeMaxChlInd_cpc)/3600, storeMaxChlInt_cpc, 'bo', S20.FileMetadata.Timestamps(storeMaxPcbInd_cpc)/3600, storeMaxChlInt_cpc, 'ro')
xlim([0 35])

