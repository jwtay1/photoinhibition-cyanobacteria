ids = [17, 61, 62, 124, 125, 137, 138];

for id = ids
    
    track = getTrack(S1, id);
    
    plot(S1.FileMetadata.Timestamps(track.Frames) / 3600, track.MajorAxisLength * S1.FileMetadata.PhysicalPxSize);    
    hold on
        
end

hold off
ylabel('Length (\mum)')
xlabel('Time (hours)')