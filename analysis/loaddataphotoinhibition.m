%Load latest datasets
clearvars
clc

S1 = PhotodamageAnalyzer;
S1 = importdata(S1, 'D:\Projects\2020Feb Photodamage\data\MergeProcess20200429\Reprocessed\ChannelRed,Cy5,RFP_Seq0000_series1_merged.mat');
S1.iXY = 1;

S17 = PhotodamageAnalyzer;
S17 = importdata(S17, 'D:\Projects\2020Feb Photodamage\data\MergeProcess20200429\Reprocessed\ChannelRed,Cy5,RFP_Seq0000_series17_merged.mat');
S17.iXY = 17;

%%
S20 = PhotodamageAnalyzer;
S20 = importdata(S20, 'D:\Projects\2020Feb Photodamage\data\MergeProcess20200429\ChannelRed,Cy5,RFP_Seq0000_series20_merged.mat');
S20 = setFileMetadata(S20, 'Filename', 'D:\Projects\2020Feb Photodamage\data\20200222\ChannelRed,Cy5,RFP_Seq0000.nd2; D:\Projects\2020Feb Photodamage\data\20200222\ChannelRed,Cy5,RFP_Seq0001.nd2');
S20.iXY = 20;
