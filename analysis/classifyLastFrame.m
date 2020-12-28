%Find all cells in the last frame
frames = {S17.Tracks.Frames};

isLastFrame = cellfun(@(x) ismember(S17.MaxFrame, x), frames);

idx = find(isLastFrame);
%%
%Plot the majoraxislengths
%1 - Growing
%2 - Stopped
%3 - Error

for ii = 1:numel(idx)
    
    tt = S17.Tracks(idx(ii)).Frames;
    cellLength = [S17.Tracks(idx(ii)).Data.MajorAxisLength{:}];
    
    plot(tt, cellLength, 'red');
    hold on
    %Get mother cell (if exist)
    if ~isnan(S17.Tracks(idx(ii)).MotherID)
        tt = S17.Tracks(S17.Tracks(idx(ii)).MotherID).Frames;
        
        motherLength = [S17.Tracks(S17.Tracks(idx(ii)).MotherID).Data.MajorAxisLength{:}];
        
        plot(tt, motherLength, 'blue');
    end
    hold off
    
    str = input('Classification?');
    
    storeClassification(ii) = str;
    
end


find(storeClassification == 3)
%%

%Count number dead 
wtAlive = 0;
wtDead = 0;
cpcAlive = 0;
cpcDead = 0;

for ii = 1:numel(idx)
    
    switch lower(S17.Tracks(idx(ii)).Type)
        
        case 'wt'
            
            if storeClassification(ii) == 1
                wtAlive = wtAlive + 1;                
            else
                wtDead = wtDead + 1;
            end            
            
        case 'cpc'
            
            if storeClassification(ii) == 1
                cpcAlive = cpcAlive + 1;
            else
                cpcDead = cpcDead + 1;
            end            

    end    

end

%% Maybe a better metric is to look at tracks that existed just after irraditaion (i.e. frame 21). Did they divide again?

frames = {S17.Tracks.Frames};

isPresent = cellfun(@(x) ismember(21, x), frames);

idx = find(isPresent);

wtAlive = 0;
wtDead = 0;
cpcAlive = 0;
cpcDead = 0;

wtColonyAlive = [];
wtColonyDead = [];
cpcColonyAlive = [];
cpcColonyDead = [];

for ii = 1:numel(idx)
    
    switch lower(S17.Tracks(idx(ii)).Type)
        
        case 'wt'
            if ~any(isnan(S17.Tracks(idx(ii)).DaughterID))
                wtAlive = wtAlive + 1;
                wtColonyAlive = [wtColonyAlive S17.Tracks(idx(ii)).Colony];
            else
                wtDead = wtDead + 1;
                wtColonyDead = [wtColonyDead S17.Tracks(idx(ii)).Colony];
            end
            
            
        case 'cpc'
            
            if ~any(isnan(S17.Tracks(idx(ii)).DaughterID))
                cpcAlive = cpcAlive + 1;
                cpcColonyAlive = [cpcColonyAlive S17.Tracks(idx(ii)).Colony];
            else
                cpcDead = cpcDead + 1;
                cpcColonyDead = [cpcColonyDead S17.Tracks(idx(ii)).Colony];
            end
    end 
            
end

%Find number of colonies with assymmetric survival events

wtColonyAlive = unique(wtColonyAlive);
wtColonyDead = unique(wtColonyDead);
cpcColonyAlive = unique(cpcColonyAlive);
cpcColonyDead = unique(cpcColonyDead);

wtAsymmetricColony = [];
wtAllAliveColony = [];
wtAsymmetric = 0;
wtAllAlive = 0;

for ii = 1:numel(wtColonyAlive)
    
    if ismember(wtColonyAlive(ii), wtColonyDead)
        
        wtAsymmetric = wtAsymmetric + 1;
        wtAsymmetricColony = [wtAsymmetricColony, wtColonyAlive(ii)];
        
    else
        
        wtAllAlive = wtAllAlive + 1;
        wtAllAliveColony = [wtAllAliveColony, wtColonyAlive(ii)];
        
    end
    
end

%Check if all dead
wtAllDeadColony = [];
wtAllDead = 0;
for ii = 1:numel(wtColonyDead)
    
    if ~ismember(wtColonyDead(ii), wtAsymmetricColony) && ...
            ~ismember(wtColonyDead(ii), wtAllAliveColony) 
        wtAllDead = wtAllDead + 1;
        wtAllDeadColony = [wtAllDeadColony, wtColonyDead(ii)];
        
    end
    
end

disp('WT colonies (allAlive)')
disp(wtAllAliveColony)
disp('WT colonies (allDead)')
disp(wtAllDeadColony)
disp('WT colonies (assymm)')
disp(wtAsymmetricColony)

disp('WT colonies total')
disp(numel(wtAsymmetricColony) + numel(wtAllAliveColony) + numel(wtAllDeadColony))

%%

%Find number of colonies with assymmetric survival events

cpcColonyAlive = unique(cpcColonyAlive);
cpcColonyDead = unique(cpcColonyDead);

cpcAsymmetricColony = [];
cpcAllAliveColony = [];
cpcAsymmetric = 0;
cpcAllAlive = 0;

for ii = 1:numel(cpcColonyAlive)
    
    if ismember(cpcColonyAlive(ii), cpcColonyDead)
        
        cpcAsymmetric = cpcAsymmetric + 1;
        cpcAsymmetricColony = [cpcAsymmetricColony, cpcColonyAlive(ii)];
        
    else
        
        cpcAllAlive = cpcAllAlive + 1;
        cpcAllAliveColony = [cpcAllAliveColony, cpcColonyAlive(ii)];
        
    end
    
end

%Check if all dead
cpcAllDeadColony = [];
cpcAllDead = 0;
for ii = 1:numel(cpcColonyDead)
    
    if ~ismember(cpcColonyDead(ii), cpcAsymmetricColony) && ...
            ~ismember(cpcColonyDead(ii), cpcAllAliveColony) 
        cpcAllDead = cpcAllDead + 1;
        cpcAllDeadColony = [cpcAllDeadColony, cpcColonyDead(ii)];
        
    end
    
end

disp('CPC colonies (allAlive)')
disp(cpcAllAliveColony)
disp('CPC colonies (allDead)')
disp(cpcAllDeadColony)
disp('CPC colonies (assymm)')
disp(cpcAsymmetricColony)

disp('CPC colonies total')
disp(numel(cpcAsymmetricColony) + numel(cpcAllAliveColony) + numel(cpcAllDeadColony))


%% Make plots





%showFrame(S17, 21, 1, 'showcolonies')