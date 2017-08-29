%the below index contains the raw data in matlab parsed format
%   the data chunks have the power received by the receiver
%   the attrib chunks have the locations, aircraft data, and other metadata
%   the priIndex index the chunks by time (aka pulse repitition interval)
data_dir = '/data/cees/amhilger/BBAS_PIG/rawIndotM/';
%%% out_dir = ''; *** set your output directory here in your own folders 

save_SAR('b01', data_dir, out_dir)

