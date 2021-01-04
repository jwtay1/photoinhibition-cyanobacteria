%S1 - Cells 17, 61, 62, 124, 125, 137, 138

leafIDs = [124, 125, 137, 138];

dataType = 'lineage';


switch lower(dataType)
    
    case 'lineage'
        
        for iTrack = 1:numel(leafIDs)
            
            %Get list of IDs
            IDs = traverse(S1, leafIDs(iTrack), 'backwards');
            
            for ii = 1:numel(IDs)

                tt = S1.FileMetadata.Timestamps(S1.Tracks(IDs(ii)).Frames)/3600;
                
                
                rfp = [S1.Tracks(IDs(ii)).Data.MeanRFP{:}];
                subplot(1, 2, 1)
                plot(tt, rfp);
                hold on
                
                cy5 = [S1.Tracks(IDs(ii)).Data.MeanCy5{:}];
                subplot(1, 2, 2)
                plot(tt, cy5);
                hold on
            end
                        
        end
        
        subplot(1, 2, 1)
        hold off
        ylim([0 14000])
        ylabel('Chlorophyll Intensity (\mum)')
        xlabel('Hours')
    
        subplot(1, 2, 2)
        hold off
        ylim([0 4000])
        ylabel('Phycobilisome Intensity (\mum)')
        xlabel('Hours')
    
    case 'productivity'
        
        for iTrack = 1:numel(leafIDs)
            
            %Get list of IDs
            IDs = traverse(S1, leafIDs(iTrack), 'backwards');
            
            if numel(IDs) >= 2
                
                %Concatenate
                combined = [];
                frames = [];
                for ii = 1:numel(IDs)
                    
                    cellLength = [S1.Tracks(IDs(ii)).Data.MajorAxisLength{:}];
                    dL = [0 diff(cellLength)];
                    
                    %                                 if isempty(combined)
                    %                                     cellLength = [obj.Tracks(IDs(ii)).Data.MajorAxisLength{:}];
                    %                                     dL = diff(cellLength);
                    %                                 else
                    %                                     cellLength = [obj.Tracks(IDs(ii)).Data.MajorAxisLength{:}] + combined(end);
                    %                                 end
                    %
                    combined = [combined dL];
                    frames = [frames S1.Tracks(IDs(ii)).Frames];
                    
                end
                
                switch lower(S1.Tracks(leafIDs(iTrack)).Classification)
                    
                    case 'alive'
                        
                        color = 'r';
                        
                    case 'dead'
                        color = 'b';
                        
                    case 'tooshort'
                        color = 'r';
                        
                    case 'excluded'
                        color = 'y';
                        
                end
                
                
                if strcmpi(S1.Tracks(leafIDs(iTrack)).Type, 'WT')
                    
                    subplot(1,2,1)
                    plot(S1.FileMetadata.Timestamps(frames)/3600, cumsum(combined) .* S1.FileMetadata.PhysicalPxSize(1), ...
                        'Color', color)
                    hold on
                    
                elseif strcmpi(S1.Tracks(leafIDs(iTrack)).Type, 'cpc')
                    
                    subplot(1,2,2)
                    plot(S1.FileMetadata.Timestamps(frames)/3600, cumsum(combined) .* S1.FileMetadata.PhysicalPxSize(1), ...
                        'Color', color)
                    hold on
                    
                end
                
                
            end
            
            
        end
        
        %Stop the hold
        subplot(1, 2, 1)
        hold off
        ylim([0 20])
        ylabel('Sum of cell length (\mum)')
        xlabel('Hours')
        
        subplot(1, 2, 2)
        hold off
        ylim([0 20])
        ylabel('Sum of cell length (\mum)')
        xlabel('Hours')
        
    case 'meanchlorophyll'
        
        for iTrack = 1:numel(leafIDs)
            
            %Get list of IDs
            IDs = traverse(S1, leafIDs(iTrack), 'backwards');
            
            if numel(IDs) >= 2
                
                %Concatenate
                combined = [];
                frames = [];
                for ii = 1:numel(IDs)
                    
                    cy5 = [S1.Tracks(IDs(ii)).Data.MeanCy5{:}];
                    
                    combined = [combined cy5];
                    frames = [frames S1.Tracks(IDs(ii)).Frames];
                    
                end
                switch lower(S1.Tracks(leafIDs(iTrack)).Classification)
                    
                    case 'alive'
                        
                        color = 'r';
                        
                    case 'dead'
                        color = 'b';
                        
                    case 'tooshort'
                        color = 'r';
                        
                    case 'excluded'
                        color = 'y';
                        
                end
                
                
                
                if strcmpi(S1.Tracks(leafIDs(iTrack)).Type, 'WT')
                    
                    subplot(1,2,1)
                    plot(S1.FileMetadata.Timestamps(frames)/3600, combined, ...
                        'Color', color)
                    hold on
                    
                elseif strcmpi(S1.Tracks(leafIDs(iTrack)).Type, 'cpc')
                    
                    subplot(1,2,2)
                    plot(S1.FileMetadata.Timestamps(frames)/3600, combined, ...
                        'Color', color)
                    hold on
                    
                end
                
                
            end
            
            
        end
        
        %Stop the hold
        subplot(1, 2, 1)
        hold off
        ylim([0 14000])
        ylabel('Chlorophyll Intensity (\mum)')
        xlabel('Hours')
        
        subplot(1, 2, 2)
        hold off
        ylim([0 3500])
        ylabel('Chlorophyll Intensity  (\mum)')
        xlabel('Hours')
        
        
    case 'meanphycobilisome'
        
        for iTrack = 1:numel(leafIDs)
            
            %Get list of IDs
            IDs = traverse(S1, leafIDs(iTrack), 'backwards');
            
            if numel(IDs) >= 2
                
                %Concatenate
                combined = [];
                frames = [];
                for ii = 1:numel(IDs)
                    
                    rfp = [S1.Tracks(IDs(ii)).Data.MeanRFP{:}];
                    
                    combined = [combined rfp];
                    frames = [frames S1.Tracks(IDs(ii)).Frames];
                    
                end
                
                switch lower(S1.Tracks(leafIDs(iTrack)).Classification)
                    
                    case 'alive'
                        
                        color = 'r';
                        
                    case 'dead'
                        color = 'b';
                        
                    case 'tooshort'
                        color = 'r';
                        
                    case 'excluded'
                        color = 'y';
                        
                end
                
                
                if strcmpi(S1.Tracks(leafIDs(iTrack)).Type, 'WT')
                    
                    subplot(1,2,1)
                    plot(S1.FileMetadata.Timestamps(frames)/3600, combined, ...
                        'Color', color)
                    hold on
                    
                elseif strcmpi(S1.Tracks(leafIDs(iTrack)).Type, 'cpc')
                    
                    subplot(1,2,2)
                    plot(S1.FileMetadata.Timestamps(frames)/3600, combined, ...
                        'Color', color)
                    hold on
                    
                end
                
                
            end
            
            
        end
        
        %Stop the hold
        subplot(1, 2, 1)
        hold off
        ylim([0 4000])
        ylabel('Phycobilisome Intensity (\mum)')
        xlabel('Hours')
        
        subplot(1, 2, 2)
        hold off
        ylim([0 1500])
        ylabel('Phycobilisome Intensity  (\mum)')
        xlabel('Hours')
        
        
        
end


% subplot(1, 2, 1)
% ylim('auto')