function plotDataS17(obj)
%PLOTDATA
%Updated: 2021-01-14
%Adjusted metric for classifying cpc lineages as alive or dead
%Checked the dead traces and found that only 1 was real - the others were
%due to errors. Removed erroneous traces.


%Find leaf nodes (i.e. daughterIdx = NaN)
leafIDs = find(cellfun(@(x) any(isnan(x)), {obj.Tracks.DaughterID}));

%Create struct to hold data
lineageData = struct('Type', {}, 'IDs', {}, 'Classification', {}, ...
    'Frames', {}, 'Time', {}, ...
    'Productivity', {}, 'MeanChl', {}, 'MeanPcb', {});

for iTrack = 1:numel(leafIDs)

    %Get list of IDs
    IDs = traverse(obj, leafIDs(iTrack), 'backwards');
    
    %Filter data (too short)
    if numel(IDs) < 2 || obj.Tracks(IDs(1)).Frames(1) ~= 1
    %if obj.Tracks(IDs(1)).Frames(1) ~= 1
        
        %Skip
        continue
        
    end
        
    newIdx = numel(lineageData) + 1;
    
    lineageData(newIdx).IDs = IDs;
    lineageData(newIdx).Type = obj.Tracks(leafIDs(iTrack)).Type;
    
    frames = [];
    combinedLength = [];
    combinedCy5 = [];
    combinedRFP = [];
    
    for ii = 1:numel(IDs)
        
        frames = [frames obj.Tracks(IDs(ii)).Frames];
        
        cellLength = [obj.Tracks(IDs(ii)).Data.MajorAxisLength{:}];
        dL = [0 diff(cellLength)];
        combinedLength = [combinedLength dL];
                
        cy5 = [obj.Tracks(IDs(ii)).Data.MeanCy5{:}];
        combinedCy5 = [combinedCy5 cy5];
        
        rfp = [obj.Tracks(IDs(ii)).Data.MeanRFP{:}];        
        combinedRFP = [combinedRFP rfp];
        
    end
    
    lineageData(newIdx).Frames = frames;
    lineageData(newIdx).Time = obj.FileMetadata.Timestamps(frames)/3600;
    
    lineageData(newIdx).Productivity = cumsum(combinedLength) .* obj.FileMetadata.PhysicalPxSize(1);
    
    lineageData(newIdx).MeanChl = combinedCy5;
    lineageData(newIdx).MeanChlNorm = lineageData(newIdx).MeanChl / mean(lineageData(newIdx).MeanChl(1));
    
    lineageData(newIdx).MeanPcb = combinedRFP;
    lineageData(newIdx).MeanPcbNorm = lineageData(newIdx).MeanPcb / mean(lineageData(newIdx).MeanPcb(1));
    
%     %Filter out invalid tracks - tracks that did not track long enough?
%     if numel(lineageData(newIdx).Frames) < 61
%         continue;        
%     end
    
    
    %Classify based on Cy5 intensity
    if strcmpi(lineageData(newIdx).Type, 'wt')
        
        %if max(lineageData(newIdx).MeanChl) < 5000 && max(lineageData(newIdx).MeanPcb) < 1800
        if max(lineageData(newIdx).MeanChlNorm) < 2.7 && max(lineageData(newIdx).MeanPcbNorm) < 3
        %if lineageData(newIdx).Productivity(end) > 8.5
            lineageData(newIdx).Classification = 'Growing';
            
            figure(1)
            subplot(1,2,1)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).Productivity, ...
                'Color', 'red')
            hold on
            
            figure(2)
            subplot(1,2,1)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).MeanChlNorm, ...
                'Color', 'red')
            hold on
            
            figure(3)
            subplot(1,2,1)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).MeanPcbNorm, ...
                'Color', 'red')
            hold on
%             keyboard
        else
            
            lineageData(newIdx).Classification = 'Stopped';
            
            figure(1)
            subplot(1,2,1)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).Productivity, ...
                'Color', 'blue')
            hold on
            
            figure(2)
            subplot(1,2,1)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).MeanChlNorm, ...
                'Color', 'blue')
            hold on
            
            figure(3)
            subplot(1,2,1)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).MeanPcbNorm, ...
                'Color', 'blue')
            hold on
            
        end
        
    elseif strcmpi(lineageData(newIdx).Type, 'cpc')
        
        if max(lineageData(newIdx).MeanChl) < 1600
        %if lineageData(newIdx).Productivity(end) > 1.5
            
            lineageData(newIdx).Classification = 'Growing';
            disp(lineageData(newIdx).IDs)

            
            figure(1)
            subplot(1,2,2)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).Productivity, ...
                'Color', 'red')
            hold on
            
            figure(2)
            subplot(1,2,2)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).MeanChl, ...
                'Color', 'red')
            hold on
            
            figure(3)
            subplot(1,2,2)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).MeanPcb, ...
                'Color', 'red')
            hold on
%             keyboard
        else
            
            %Skip the three that I know are wrong
            if any(ismember(lineageData(newIdx).IDs, 5))
                continue
            end
            
            lineageData(newIdx).Classification = 'Stopped';
            
            figure(1)
            subplot(1,2,2)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).Productivity, ...
                'Color', 'blue')
            hold on
            
            figure(2)
            subplot(1,2,2)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).MeanChl, ...
                'Color', 'blue')
            hold on
            
            figure(3)
            subplot(1,2,2)
            plot(obj.FileMetadata.Timestamps(frames)/3600, lineageData(newIdx).MeanPcb, ...
                'Color', 'blue')
            hold on
            
        end
        
        
    end
    
end

figure(1)
subplot(1, 2, 1)
hold off
subplot(1, 2, 2)
hold off

figure(2)
subplot(1, 2, 1)
hold off
subplot(1, 2, 2)
hold off

figure(3)
subplot(1, 2, 1)
hold off
subplot(1, 2, 2)
hold off


% 
% switch lower(dataType)
%     
%     case 'productivity'
%         
%         for iTrack = 1:numel(leafIDs)
%             
%             %Get list of IDs
%             IDs = traverse(obj, leafIDs(iTrack), 'backwards');
%             
%             if numel(IDs) >= 2
%                 
%                 %Concatenate
%                 combined = [];
%                 frames = [];
%                 for ii = 1:numel(IDs)
%                     
%                     cellLength = [obj.Tracks(IDs(ii)).Data.MajorAxisLength{:}];
%                     dL = [0 diff(cellLength)];
%                     
%                     %                                 if isempty(combined)
%                     %                                     cellLength = [obj.Tracks(IDs(ii)).Data.MajorAxisLength{:}];
%                     %                                     dL = diff(cellLength);
%                     %                                 else
%                     %                                     cellLength = [obj.Tracks(IDs(ii)).Data.MajorAxisLength{:}] + combined(end);
%                     %                                 end
%                     %
%                     combined = [combined dL];
%                     frames = [frames obj.Tracks(IDs(ii)).Frames];
%                     
%                 end
%                 
%                 switch lower(obj.Tracks(leafIDs(iTrack)).Classification)
%                     
%                     case 'alive'
%                         
%                         color = 'r';
%                         
%                     case 'dead'
%                         color = 'b';
%                         
%                     case 'tooshort'
%                         color = 'r';
%                         
%                     case 'excluded'
%                         color = 'y';
%                         
%                 end
%                 
%                 
%                 if strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'WT')
%                     
%                     subplot(1,2,1)
%                     plot(obj.FileMetadata.Timestamps(frames)/3600, cumsum(combined), ...
%                         'Color', color)
%                     hold on
%                     
%                 elseif strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'cpc')
%                     
%                     subplot(1,2,2)
%                     plot(obj.FileMetadata.Timestamps(frames)/3600, cumsum(combined), ...
%                         'Color', color)
%                     hold on
%                     
%                 end
%                 
%                 
%             end
%             
%             
%         end
%         
%         %Stop the hold
%         subplot(1, 2, 1)
%         hold off
%         ylim([0 250])
%         ylabel('Sum of cell length (\mum)')
%         xlabel('Hours')
%         
%         subplot(1, 2, 2)
%         hold off
%         ylim([0 250])
%         ylabel('Sum of cell length (\mum)')
%         xlabel('Hours')
%         
%     case 'meanchlorophyll'
%         
%         for iTrack = 1:numel(leafIDs)
%             
%             %Get list of IDs
%             IDs = traverse(obj, leafIDs(iTrack), 'backwards');
%             
%             if numel(IDs) >= 2
%                 
%                 %Concatenate
%                 combined = [];
%                 frames = [];
%                 for ii = 1:numel(IDs)
%                     
%                     cy5 = [obj.Tracks(IDs(ii)).Data.MeanCy5{:}];
%                     
%                     combined = [combined cy5];
%                     frames = [frames obj.Tracks(IDs(ii)).Frames];
%                     
%                 end
%                 switch lower(obj.Tracks(leafIDs(iTrack)).Classification)
%                     
%                     case 'alive'
%                         
%                         color = 'r';
%                         
%                     case 'dead'
%                         color = 'b';
%                         
%                     case 'tooshort'
%                         color = 'r';
%                         
%                     case 'excluded'
%                         color = 'y';
%                         
%                 end
%                 
%                 
%                 
%                 if strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'WT')
%                     
%                     subplot(1,2,1)
%                     plot(obj.FileMetadata.Timestamps(frames)/3600, combined, ...
%                         'Color', color)
%                     hold on
%                     
%                 elseif strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'cpc')
%                     
%                     subplot(1,2,2)
%                     plot(obj.FileMetadata.Timestamps(frames)/3600, combined, ...
%                         'Color', color)
%                     hold on
%                     
%                 end
%                 
%                 
%             end
%             
%             
%         end
%         
%         %Stop the hold
%         subplot(1, 2, 1)
%         hold off
%         ylim([0 14000])
%         ylabel('Chlorophyll Intensity (\mum)')
%         xlabel('Hours')
%         
%         subplot(1, 2, 2)
%         hold off
%         ylim([0 3500])
%         ylabel('Chlorophyll Intensity  (\mum)')
%         xlabel('Hours')
%         
%         
%     case 'meanphycobilisome'
%         
%         for iTrack = 1:numel(leafIDs)
%             
%             %Get list of IDs
%             IDs = traverse(obj, leafIDs(iTrack), 'backwards');
%             
%             if numel(IDs) >= 2
%                 
%                 %Concatenate
%                 combined = [];
%                 frames = [];
%                 for ii = 1:numel(IDs)
%                     
%                     rfp = [obj.Tracks(IDs(ii)).Data.MeanRFP{:}];
%                     
%                     combined = [combined rfp];
%                     frames = [frames obj.Tracks(IDs(ii)).Frames];
%                     
%                 end
%                 
%                 switch lower(obj.Tracks(leafIDs(iTrack)).Classification)
%                     
%                     case 'alive'
%                         
%                         color = 'r';
%                         
%                     case 'dead'
%                         color = 'b';
%                         
%                     case 'tooshort'
%                         color = 'r';
%                         
%                     case 'excluded'
%                         color = 'y';
%                         
%                 end
%                 
%                 
%                 if strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'WT')
%                     
%                     subplot(1,2,1)
%                     plot(obj.FileMetadata.Timestamps(frames)/3600, combined, ...
%                         'Color', color)
%                     hold on
%                     
%                 elseif strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'cpc')
%                     
%                     subplot(1,2,2)
%                     plot(obj.FileMetadata.Timestamps(frames)/3600, combined, ...
%                         'Color', color)
%                     hold on
%                     
%                 end
%                 
%                 
%             end
%             
%             
%         end
%         
%         %Stop the hold
%         subplot(1, 2, 1)
%         hold off
%         ylim([0 4000])
%         ylabel('Phycobilisome Intensity (\mum)')
%         xlabel('Hours')
%         
%         subplot(1, 2, 2)
%         hold off
%         ylim([0 1500])
%         ylabel('Phycobilisome Intensity  (\mum)')
%         xlabel('Hours')
%         
%         
%         
% end

end