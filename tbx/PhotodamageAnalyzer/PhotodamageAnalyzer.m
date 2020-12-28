classdef PhotodamageAnalyzer < DataAnalyzer
    
    properties
        iXY = 1;
        CPC_rfpThresh = 400;
        NotCell_Cy5Thresh = 200;
        
        maxstd_cpc_dead = 1.5;
        maxstd_wt_dead = 1.5;
    end
    
    properties (SetAccess = private, Hidden)
        
        reader = '';
        
    end
    
    methods
        
        function obj = analyze(obj)
            
            %Run analysis from DataAnalyzer - this function computes growth
            %rate, generation number, and colony IDs
            obj = analyze@DataAnalyzer(obj);
            
            for iT = 1:numel(obj)
                
                %Compute average RFP and Cy5 intensities of the first frame
                obj.Tracks(iT).RFPInit = obj.Tracks(iT).Data.TotalIntRFP{1} ./ obj.Tracks(iT).Data.Area{1};
                obj.Tracks(iT).Cy5Init = obj.Tracks(iT).Data.TotalIntCy5{1} ./ obj.Tracks(iT).Data.Area{1};
                
                %Compute average RFP and Cy5 intensities over time
                obj.Tracks(iT).Data.MeanRFP = num2cell([obj.Tracks(iT).Data.TotalIntRFP{:}] ./ [obj.Tracks(iT).Data.Area{:}]);
                obj.Tracks(iT).Data.MeanCy5 = num2cell([obj.Tracks(iT).Data.TotalIntCy5{:}] ./ [obj.Tracks(iT).Data.Area{:}]);
                
                %Classify objects: CPC, WT, and objects that are not cells
                if isnan(obj.Tracks(iT).MotherID)
                    if obj.Tracks(iT).Cy5Init < obj.NotCell_Cy5Thresh
                        obj.Tracks(iT).Type = 'NotCell';
                        
                    else
                        if obj.Tracks(iT).RFPInit < obj.CPC_rfpThresh
                            obj.Tracks(iT).Type = 'CPC';
                        else
                            obj.Tracks(iT).Type = 'WT';
                        end
                    end
                else
                    obj.Tracks(iT).Type = obj.Tracks(obj.Tracks(iT).MotherID).Type;
                end
                
                %Classify cells that die by whether they divide or not
                if any(isnan(obj.Tracks(iT).DaughterID)) && isnan(obj.Tracks(iT).MotherID)
                    %These are either microscope debris or cells that were
                    %dead to begin with
                    obj.Tracks(iT).Classification = 'exclude';
                    
                elseif ~any(isnan(obj.Tracks(iT).DaughterID))
                    %If cells divided then they must still be alive
                    obj.Tracks(iT).Classification = 'alive';
                    
                elseif numel(obj.Tracks(iT).Frames) < 10
                    %If tracks are too short, we cannot reliably classify
                    %(or plot) them
                    obj.Tracks(iT).Classification = 'tooshort';
                    
                else
                    
                    %Determine which are tracks that are just at the end of
                    %the movie vs tracks that are actually dead
                    yy = smooth([obj.Tracks(iT).Data.MajorAxisLength{:}], 3);
                    tt = obj.FileMetadata.Timestamps(obj.Tracks(iT).Frames)/3600;
                    
                    ss = stdfilt(yy, ones(5, 1));
                    
                    data = ([obj.Tracks(iT).Data.MajorAxisLength{:}] - obj.Tracks(iT).Data.MajorAxisLength{1})./ ...
                        (max([obj.Tracks(iT).Data.MajorAxisLength{:}]));
                    tp = 0.4;
                    figure(98)
                    
                    if strcmpi(obj.Tracks(iT).Type, 'wt')
                        
                        if nnz(ss <= obj.maxstd_wt_dead) > 5
                            obj.Tracks(iT).Classification = 'dead';
                            
                            subplot(1, 2, 1)
                            plot(data, 'color', [0.6, 0.6, 0.6, tp]);
                            hold on
                        else
                            obj.Tracks(iT).Classification = 'alive';
                            
                            subplot(1, 2, 2)
                            plot(data, 'color', [0.6, 0.6, 0.6, tp]);
                            hold on
                        end
                        
                    elseif strcmpi(obj.Tracks(iT).Type, 'cpc')
                        
                        data = data - 0.6;
                        changept = findchangepts(yy, 'Statistic', 'linear');
                        
                        figure(98)
                        
            
                        if (obj.Tracks(iT).Data.MajorAxisLength{end} - obj.Tracks(iT).Data.MajorAxisLength{changept}) < 5
                            
                            obj.Tracks(iT).Classification = 'dead';
                            
                            subplot(1, 2, 1)
                            plot(data, 'color', [0.6, 0, 0.6, tp]);
                            hold on
                            
                        else
                            
                            obj.Tracks(iT).Classification = 'alive';
                            
                            subplot(1, 2, 2)
                            plot(data, 'color', [0.6, 0, 0.6, tp]);
                            hold on
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
        function showFrame(obj, frame, channel, varargin)
            
            filenames = strsplit(obj.FileMetadata.Filename, '; ');
            nd2_pre = ND2reader(filenames{1});
            nd2_post = ND2reader(filenames{2});
            
            if nd2_pre.sizeT >= frame
                
                %Open a reader
                %nd2 = ND2reader(obj.FileMetadata.Filename);
                I = getImage(nd2_pre, 1, frame, obj.iXY);
                I = I(:, :, channel);
                
            else
                
                I = getImage(nd2_post, 1, frame - nd2_pre.sizeT + 1, obj.iXY);
                I = I(:, :, channel);
                
            end
            
            %Normalize
            I = double(I);
            I = I ./ max(I(:));
            
            if ~isempty(varargin)
                %Look for colonies in the frame
                for iTrack = 1:numel(obj.Tracks)
                    if ismember(frame, obj.Tracks(iTrack).Frames)
                        iFrame = obj.Tracks(iTrack).Frames == frame;
                        
                        if ismember('showcolonies', varargin)
                            I = insertText(I, obj.Tracks(iTrack).Data.Centroid{iFrame} + [3 3], obj.Tracks(iTrack).Colony, ...
                                'BoxOpacity', 0, 'TextColor', 'blue', 'FontSize', 12);
                        end
                        
                        if ismember('showcellid', varargin)
                            I = insertText(I, obj.Tracks(iTrack).Data.Centroid{iFrame}, obj.Tracks(iTrack).ID, ...
                                'BoxOpacity', 0, 'TextColor', 'white', 'FontSize', 12);
                        end
                    end
                end
            end
            
            imshow(I, []);
        end
        
        function varargout = displayType(obj, frame)
            %DISPLAYTYPE  Make an image showing type of cells (cpc or WT)
            %
            % DISPLAYTYPE(OBJ, FRAME)
            
            %Split filenames
            files = strsplit(obj.FileMetadata.Filename, '; ');
            
            %Open a reader
            nd2 = ND2reader(files{1});
            if frame > nd2.sizeT
                frame = frame - nd2.sizeT;
                nd2 = ND2reader(files{2});
            end
            
            I = getImage(nd2, 1, frame, obj.iXY);
            maskCPC = false(size(I, 1), size(I, 2));
            maskWT = false(size(I, 1), size(I, 2));
            maskNotCell = false(size(I, 1), size(I, 2));
            
            %Determine which tracks in the current frame
            for iT = 1:numel(obj)
                
                fIdx = find(obj.Tracks(iT).Frames == frame);
                
                if ~isempty(fIdx)
                    
                    switch obj.Tracks(iT).Type
                        
                        case 'NotCell'
                            maskNotCell(obj.Tracks(iT).Data.PixelIdxList{fIdx}) = true;
                            
                        case 'CPC'
                            maskCPC(obj.Tracks(iT).Data.PixelIdxList{fIdx}) = true;
                            
                        case 'WT'
                            maskWT(obj.Tracks(iT).Data.PixelIdxList{fIdx}) = true;
                    end
                end
                
            end
            
            Iout = showoverlay(I(:, :, 2), maskCPC, 'Opacity', 30, 'Color', [1 1 0]);
            Iout = showoverlay(Iout, maskWT, 'Opacity', 30, 'Color', [0 0 1]);
            if any(maskNotCell(:))
                Iout = showoverlay(Iout, maskNotCell, 'Opacity', 30, 'Color', [1 0 0]);
            end
            
            if nargout == 1
                varargout{1} = Iout;
            else
                imshow(Iout)
            end
            
        end
        
        function exportVideo(obj, channel)
            
            files = strsplit(obj.FileMetadata.Filename, '; ');
            
            maxFrames = max(cat(2, obj.Tracks.Frames));
            currFrame = 0;
            
            for iFile = 1:numel(files)
                
                %Open a reader
                nd2 = ND2reader(files{iFile});
                
                if iFile == 1
                    storeI = zeros(nd2.height, nd2.width, maxFrames, 'uint16');
                end
                
                for iT = 1:nd2.sizeT
                    currFrame = currFrame + 1;
                    
                    I = getImage(nd2, 1, iT, obj.iXY);
                    storeI(:, :, currFrame) = I(:, :, channel);
                end
            end
            
            maxInt = max(double(storeI), [], 'all');
            
            [~, outputFN] = fileparts(files{1});
            
            vid = VideoWriter([outputFN(1:end-4), '_series', int2str(obj.iXY), '.avi']);
            vid.FrameRate = 10;
            open(vid);
            
            for iFrame = 1:size(storeI, 3)
                
                Iout = double(storeI(:, :, iFrame)) ./ maxInt;
                
                %Make mask
                mask = false(size(Iout));
                for iTrack = 1:numel(obj)
                    
                    isInFrame = ismember(obj.Tracks(iTrack).Frames, iFrame);
                    if any(isInFrame)
                        mask(obj.Tracks(iTrack).Data.PixelIdxList{isInFrame}) = true;
                        Iout = insertText(Iout, obj.Tracks(iTrack).Data.Centroid{isInFrame}, obj.Tracks(iTrack).ID, ...
                            'BoxOpacity', 0, 'FontSize', 32, 'TextColor', 'white');
                    end
                    
                end
                
                Iout = showoverlay(Iout, bwperim(mask));
                
                writeVideo(vid, Iout);
            end
            
            close(vid)
            
            
        end
        
        function snapshot(obj, rootID, outputDir, varargin)
            %SNAPSHOT  Returns a series of frames cropped around the colony
            %
            %  SNAPSHOT(OBJ, TRACKID) saves a series of TIFF files showing
            %  the cell in the track specified.
            
            if ~isfolder(outputDir)
                error('Output directory must be a valid folder');
            end
            
            ip = inputParser;
            ip.addParameter('NumFrames', 5);
            ip.addParameter('BaseFilename', ['cell', int2str(rootID)]);
            ip.addParameter('Channel', 'Cy5');
            ip.addParameter('AddPixels', [0 0]);
            parse(ip, varargin{:});
            
            
            ids = traverse(obj, rootID, 'level');
            
            cm = magma(65535);
            storeImg = getImages(obj, ids, varargin{:});
            %Save images
            outputImg = zeros(size(storeImg(:, :, 1)));
            for ii = 1:size(storeImg, 3)
                
                %Apply colormap
                for iC = 1:3
                    currCM = cm(:, iC);
                    outputImg(:, :, iC) = currCM(storeImg(:, :, ii) + 1);
                end
                imwrite(outputImg, fullfile(outputDir, [ip.Results.BaseFilename, '_', ip.Results.Channel, '_', int2str(ii), '.tif']), 'Compression', 'none');
            end
        end
        
        function varargout = heatmap(obj, propToPlot, varargin)
            %HEATMAP  Plot cell timeseries data as a heatmap
            %
            %  HEATMAP(OBJ, D) plots the timeseries datafield D as a
            %  heatmap. By default, the heatmap is generated with all
            %  cells, and is scaled by the minimum and maximum values of
            %  the property specified.
            %
            %  HEATMAP(..., [minI, maxI]) will generate the heatmap scaled
            %  to minI and maxI. Any values less than minI or larger than
            %  maxI will be clipped to minI and maxI, respectively.
            %
            %  HEATMAP(..., 'Type', T) allows the cell type ('cpc' or
            %  'wt') to be specified. By default, all cells are plotted.
            
            ip = inputParser;
            addOptional(ip, 'Scale', NaN);
            addParameter(ip, 'Type', 'all');
            parse(ip, varargin{:});
            
            %Check that the specified property contains timeseries data
            if ~isfield(obj.Tracks(1).Data, propToPlot)
                error('PhotodamageAnalyzer:heatmap:DataNotTimeseries', ...
                    'The specified datafield ''%s'' does not contain timeseries data.', ...
                    propToPlot);
            elseif numel(obj.Tracks(1).Data.(propToPlot){1}) > 1
                error('PhotodamageAnalyzer:heatmap:DataNotVectorizable', ...
                    'The datafield ''%s'' contains data with too many dimensions. Each timepoint should be a single number.', ...
                    propToPlot);
            end
            
            %Determine type of cells to plot
            if strcmpi(ip.Results.Type, 'all')
                tracksToPlot = 1:numel(obj.Tracks);
            else
                tracksToPlot = find(ismember(lower({obj.Tracks.Type}), lower(ip.Results.Type)));
                
                if isempty(tracksToPlot)
                    error('PhotodamageAnalyzer:heatmap:NoTracksToPlot', ...
                        'Type ''%s'' returned no tracks to plot.', ...
                        ip.Results.Type);
                end
            end
            
            %Initialize storage variables
            storeData = nan(numel(tracksToPlot), obj.MaxFrame);  %Data
            storeClass = zeros(numel(tracksToPlot), 1); %Dead/Alive/NaN for ignore,
            
            %Gather data
            for ii = 1:numel(tracksToPlot)
                iTrack = tracksToPlot(ii);
                storeData(ii, obj.Tracks(iTrack).Frames) = [obj.Tracks(iTrack).Data.(propToPlot){:}];
                
                if strcmpi(obj.Tracks(iTrack).Classification, 'dead')
                    storeClass(ii) = 0;
                    
                elseif strcmpi(obj.Tracks(iTrack).Classification, 'alive')
                    storeClass(ii) = 1;
                    
                else
                    storeClass(ii) = NaN;
                end
            end
            
            if ~isempty(varargin)
                minInt = varargin{1}(1);
                maxInt = varargin{1}(2);
            else
                %Combine all to get the max and min
                minInt = min(storeData, [], 'all', 'omitnan');
                maxInt = max(storeData, [], 'all', 'omitnan');
            end
            
            heatmapDead = getHeatmap(storeData(storeClass == 0, :), minInt, maxInt);
            heatmapAlive = getHeatmap(storeData(storeClass == 1, :), minInt, maxInt);
            
            if nargout == 0
                
                subplot(1, 2, 1)
                imshow(heatmapDead, [])
                yticks(1:size(heatmapDead, 1))
                yticklabels(strsplit(num2str(find(storeClass == 0)'), ' '));
                axis on
                
                title('Dead')
                subplot(1, 2, 2)
                imshow(heatmapAlive, [])
                yticklabels(strsplit(num2str(find(storeClass == 1)'), ' '));
                yticks(1:size(heatmapAlive, 1))
                title('Alive')
                axis on
                
            else
                varargout{1} = heatmapDead;
                varargout{2} = heatmapAlive;
            end
            
            
            function outputImg = getHeatmap(M, minInt, maxInt)
                
                %                 %Trim the matrices
                %                 lastIdx = find(any(isnan(M), 1), 1, 'first');
                %                 M = M(:, 1:lastIdx);
                
                cmap = plasma(65536);
                cmap(1,:) = 0;
                
                %Normalize
                M = round(((M - minInt)./(maxInt - minInt)) * 65535);
                M(M > 65535) = 65535;
                M(M < 0) = 0;
                M(isnan(M)) = 0;
                
                outputImg = nan([size(M), 3]);
                for iC = 1:3
                    cm = cmap(:, iC);
                    try
                        outputImg(:, :, iC) = cm(M + 1);
                    catch
                        keyboard
                    end
                end
                
            end
            
        end
        
        function storeData = getDataByCellType(obj, prop, celltype)
            
            %Check that the specified property contains timeseries data
            if ~isfield(obj.Tracks(1).Data, prop)
                error('PhotodamageAnalyzer:heatmap:DataNotTimeseries', ...
                    'The specified datafield ''%s'' does not contain timeseries data.', ...
                    prop);
            elseif numel(obj.Tracks(1).Data.(prop){1}) > 1
                error('PhotodamageAnalyzer:heatmap:DataNotVectorizable', ...
                    'The datafield ''%s'' contains data with too many dimensions. Each timepoint should be a single number.', ...
                    prop);
            end
            
            %Determine type of cells to plot
            if strcmpi(celltype, 'all')
                tracksToPlot = 1:numel(obj.Tracks);
            else
                tracksToPlot = find(ismember(lower({obj.Tracks.Type}), lower(celltype)));
                
                if isempty(tracksToPlot)
                    error('PhotodamageAnalyzer:heatmap:NoTracksToPlot', ...
                        'Type ''%s'' returned no tracks to plot.', ...
                        celltype);
                end
            end
            
            %Initialize storage variables
            storeData = nan(numel(tracksToPlot), obj.MaxFrame);  %Data
            
            %Gather data
            for ii = 1:numel(tracksToPlot)
                iTrack = tracksToPlot(ii);
                storeData(ii, 1:numel(obj.Tracks(iTrack).Frames)) = [obj.Tracks(iTrack).Data.(prop){:}];
            end
            
        end
        
        function plotData(obj, dataType)
            %PLOTDATA
            
            %Find leaf nodes (i.e. daughterIdx = NaN)
            leafIDs = find(cellfun(@(x) any(isnan(x)), {obj.Tracks.DaughterID}));
            
            switch lower(dataType)
                
                case 'productivity'
                    
                    for iTrack = 1:numel(leafIDs)
                        
                        %Get list of IDs
                        IDs = traverse(obj, leafIDs(iTrack), 'backwards');
                        
                        if numel(IDs) >= 2
                            
                            %Concatenate
                            combined = [];
                            frames = [];
                            for ii = 1:numel(IDs)
                                
                                cellLength = [obj.Tracks(IDs(ii)).Data.MajorAxisLength{:}];
                                dL = [0 diff(cellLength)];
                                
                                %                                 if isempty(combined)
                                %                                     cellLength = [obj.Tracks(IDs(ii)).Data.MajorAxisLength{:}];
                                %                                     dL = diff(cellLength);
                                %                                 else
                                %                                     cellLength = [obj.Tracks(IDs(ii)).Data.MajorAxisLength{:}] + combined(end);
                                %                                 end
                                %
                                combined = [combined dL];
                                frames = [frames obj.Tracks(IDs(ii)).Frames];
                                
                            end
                            
                            switch lower(obj.Tracks(leafIDs(iTrack)).Classification)
                                
                                case 'alive'
                                    
                                    color = 'r';
                                    
                                case 'dead'
                                    color = 'b';
                                    
                                case 'tooshort'
                                    color = 'r';
                                    
                                case 'excluded'
                                    color = 'y';
                                    
                            end
                            
                            
                            if strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'WT')
                                
                                subplot(1,2,1)
                                plot(obj.FileMetadata.Timestamps(frames)/3600, cumsum(combined) .* obj.FileMetadata.PhysicalPxSize(1), ...
                                    'Color', color)
                                hold on
                                
                            elseif strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'cpc')
                                
                                subplot(1,2,2)
                                plot(obj.FileMetadata.Timestamps(frames)/3600, cumsum(combined) .* obj.FileMetadata.PhysicalPxSize(1), ...
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
                        IDs = traverse(obj, leafIDs(iTrack), 'backwards');
                        
                        if numel(IDs) >= 2
                            
                            %Concatenate
                            combined = [];
                            frames = [];
                            for ii = 1:numel(IDs)
                                
                                cy5 = [obj.Tracks(IDs(ii)).Data.MeanCy5{:}];
                                
                                combined = [combined cy5];
                                frames = [frames obj.Tracks(IDs(ii)).Frames];
                                
                            end
                            switch lower(obj.Tracks(leafIDs(iTrack)).Classification)
                                
                                case 'alive'
                                    
                                    color = 'r';
                                    
                                case 'dead'
                                    color = 'b';
                                    
                                case 'tooshort'
                                    color = 'r';
                                    
                                case 'excluded'
                                    color = 'y';
                                    
                            end
                            
                            
                            
                            if strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'WT')
                                
                                subplot(1,2,1)
                                plot(obj.FileMetadata.Timestamps(frames)/3600, combined, ...
                                    'Color', color)
                                hold on
                                
                            elseif strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'cpc')
                                
                                subplot(1,2,2)
                                plot(obj.FileMetadata.Timestamps(frames)/3600, combined, ...
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
                        IDs = traverse(obj, leafIDs(iTrack), 'backwards');
                        
                        if numel(IDs) >= 2
                            
                            %Concatenate
                            combined = [];
                            frames = [];
                            for ii = 1:numel(IDs)
                                
                                rfp = [obj.Tracks(IDs(ii)).Data.MeanRFP{:}];
                                
                                combined = [combined rfp];
                                frames = [frames obj.Tracks(IDs(ii)).Frames];
                                
                            end
                            
                            switch lower(obj.Tracks(leafIDs(iTrack)).Classification)
                                
                                case 'alive'
                                    
                                    color = 'r';
                                    
                                case 'dead'
                                    color = 'b';
                                    
                                case 'tooshort'
                                    color = 'r';
                                    
                                case 'excluded'
                                    color = 'y';
                                    
                            end
                            
                            
                            if strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'WT')
                                
                                subplot(1,2,1)
                                plot(obj.FileMetadata.Timestamps(frames)/3600, combined, ...
                                    'Color', color)
                                hold on
                                
                            elseif strcmpi(obj.Tracks(leafIDs(iTrack)).Type, 'cpc')
                                
                                subplot(1,2,2)
                                plot(obj.FileMetadata.Timestamps(frames)/3600, combined, ...
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
            
        end
        
    end
    
    methods (Hidden)
        
        function storeImg = getImages(obj, trackIDs, varargin)
            %GETIMAGES  Get images of the specified track(s)
            %
            %  I = GETIMAGES(OBJ, TRACKIDS) returns every frame containing
            %  the specified track(s). The output image will be cropped to
            %  the smallest size while containing the identified track(s).
            %  I is a matrix with each frame stored along the 3rd
            %  dimension.
            %
            %  I = GETIMAGES(..., 'FrameRange', F) returns the specified
            %  frames F. F should be a single number or a 1x2 vector
            %  containing the start and end frame to return.
            %
            %  I = GETIMAGES(..., 'NumFrames', N) returns at most N frames.
            %  If the track length is < N, then every frame will be
            %  returned. If the 'FrameRange' is set, then the returned
            %  frames will be between F(1):N:F(end).
            %
            %  I = GETIMAGES(..., 'AddPixels', [W H]) adds W pixels to the
            %  width of the image and H pixels to the height. The track
            %  will be kept near the center of the image.
            %
            %  Example:
            %  %Get set of IDs
            %  ids = traverse(obj, 1, 'level');
            %  I = getImages(obj, ids);
            
            %Validate information
            if ~isfield(obj.FileMetadata, 'Filename') || isempty(obj.FileMetadata.Filename)
                error('PhotodamageAnalyzer:GetImages:NoFilename', ...
                    'No image file has been assigned with this data. Use setFileMetadata to set the field ''filename'' with the path to the image file.')
            end
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'FrameRange', Inf);
            addParameter(ip, 'NumFrames', Inf);
            addParameter(ip, 'AddPixels', [0 0]);
            addParameter(ip, 'Normalize', false);
            addParameter(ip, 'Channel', 'RFP');
            parse(ip, varargin{:});
            
            %Create ND2 readers for the files. Assumption here is that
            %there are two files, one containing pre-irradiation images and
            %the other containing post-irradiation images.
            filenames = strsplit(obj.FileMetadata.Filename, '; ');
            nd2_pre = ND2reader(filenames{1});
            nd2_post = ND2reader(filenames{2});
            
            if isinf(ip.Results.FrameRange)
                %Find the frames containing the tracks of interest
                frameRange = [max(cat(2, obj.Tracks(trackIDs).Frames)),...
                    min(cat(2, obj.Tracks(trackIDs).Frames))];
            else
                frameRange = ip.Results.NumFrames;
            end
            
            if isinf(ip.Results.NumFrames)
                numFrames = frameRange(2) - frameRange(1)  + 1;
            else
                numFrames = ip.Results.NumFrames;
            end
            
            %Get frames to extract
            frames = round(linspace(frameRange(1), frameRange(2), numFrames));
            
            %Estimate the size of the image using the final frame of the
            %track (assumed that the cells are growing)
            mask = false(nd2_pre.height, nd2_pre.width);
            for iTrack = trackIDs
                if ismember(frameRange(2), obj.Tracks(iTrack).Frames)
                    mask(obj.Tracks(iTrack).Data.PixelIdxList{end}) = true;
                end
            end
            
            %Get output image size from the final mask
            outputWidth = [find(any(mask, 1), 1, 'first'), find(any(mask, 1), 1, 'last')] + [-ip.Results.AddPixels(1), ip.Results.AddPixels(1)];
            outputWidth = outputWidth(2) - outputWidth(1);
            outputHeight = [find(any(mask, 2), 1, 'first'), find(any(mask, 2), 1, 'last')] + [-ip.Results.AddPixels(end), ip.Results.AddPixels(end)];
            outputHeight = outputHeight(2) - outputHeight(1);
            
            %Initialize data
            storeImg = zeros(outputHeight, outputWidth, numel(frames));
            maxInt = -Inf;
            minInt = Inf;
            for ii = 1:numel(frames)
                currFrame = frames(ii);
                
                if currFrame > nd2_pre.sizeT
                    I = getPlane(nd2_post, 1, ip.Results.Channel, currFrame - nd2_pre.sizeT, obj.iXY);
                else
                    I = getPlane(nd2_pre, 1, ip.Results.Channel, currFrame, obj.iXY);
                end
                
                %Find center of colony
                centroids = [];
                mask = false(nd2_pre.height, nd2_pre.width);
                for iTrack = trackIDs
                    if ismember(currFrame, obj.Tracks(iTrack).Frames)
                        centroids(end + 1, :) = obj.Tracks(iTrack).Data.Centroid{currFrame == obj.Tracks(iTrack).Frames};
                        mask(obj.Tracks(iTrack).Data.PixelIdxList{end}) = true;
                    end
                end
                colonyCenter = mean(centroids, 1);
                
                colStart = round(colonyCenter(1) - outputWidth/2);
                rowStart = round(colonyCenter(2) - outputHeight/2);
                
                storeImg(:, :, ii) = I(rowStart:(rowStart + outputHeight - 1), colStart:(colStart + outputWidth - 1));
                
                maxInt = max([maxInt, max(I(mask))]);
                minInt = min([minInt, min(I(mask))]);
            end
            
            %Normalize if set
            if ip.Results.Normalize
                storeImg = double(storeImg);
                maxInt = double(maxInt);
                maxInt = maxInt - 0.10 * maxInt;
                minInt = double(minInt);
                
                maxInt = repmat(maxInt, size(storeImg));
                minInt = repmat(minInt, size(storeImg));
                
                storeImg = (storeImg - minInt) ./ (maxInt - minInt);
                storeImg(storeImg > 1) = 1;
                storeImg(storeImg < 0) = 0;
                storeImg = uint16(storeImg * 65535);
            end
            
        end
        
    end
    
    
end