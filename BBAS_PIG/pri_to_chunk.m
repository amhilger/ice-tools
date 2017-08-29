function [chunk_num, trace_num] = pri_to_chunk(transect_name, pri_num)
%determines the data chunk and trace index within the chunk for a given PRI
%number (pulse repitition interval) and given transect name (e.g., 'b03')

index_name = [transect_name 'priIndex.mat'];

%retrieving the priIndex
orig_dir = cd('/data/cees/amhilger/BBAS_PIG/rawIndotM');
index = load(index_name);
pri_index = index.priIndex;

%returns number of first chunk whose first entry is greater than pri_num.
chunk_num = find(pri_index > pri_num, 1);

if isempty(chunk_num)
    cd(orig_dir);
    load bad_attrib_traces.mat
    bad_trace_index = transect_to_bad_attrib_index(transect_name);
    last_good_chunk = bad_traces(bad_trace_index).last_good_chunk;
    
    %if no chunk has a first entry exceeding the pri_num, it should be in
    %the last chunk, assuming a valid pri_num
    chunk_num = last_good_chunk;
    if last_good_chunk > length(pri_index)
        disp(['Unexpected condition for pri ' num2str(pri_num)])
        disp('Last good chunk > number of attribute chunks (per priIndex)')
    end
    cd('/data/cees/amhilger/BBAS_PIG/rawIndotM')
    
else
    %normally, decrement the result of find to get the chunk containing the
    %pri_num
    chunk_num = chunk_num-1;
end

if chunk_num == 0
    disp('Chunk_num in pri_to_chunk is 0.')
    disp(['Pri number is ' num2str(pri_num)])
end


%load the attrib array of identified chunk 
attrib_name = [transect_name 'attribChunk' ...
                num2str(chunk_num, '%03i') '.mat'];
attrib = load(attrib_name);
attrib_array = attrib.attrib_array;

cd(orig_dir)

%search the pri numbers in attrib array to find the pri_num
trace_num = find(attrib_array(1,:) == pri_num, 1);

%if no exact match
if isempty(trace_num)  
    disp(['Warning: PRI ' num2str(pri_num) 'not found'])
    %try to find closest
    high_trace_num = find(attrib_array(1,:) >= pri_num, 1);
    low_trace_num = find(fliplr(attrib_array(1,:)) <= pri_num, 1);
    if ~isempty(high_trace_num) && ~isempty(low_trace_num)
        high_found_pri = attrib_array(1, high_trace_num);
        low_found_pri = attrib_array(1, low_trace_num);
        if high_found_pri - pri_num < low_found_pri - pri_num
            trace_num = high_trace_num;
            found_pri = high_found_pri;
        else
            trace_num = low_trace_num;
            found_pri = low_found_pri;
        end
    elseif ~isempty(high_trace_num)
        trace_num = high_trace_num;
        found_pri = attrib_array(1, high_trace_num);
    else
        trace_num = low_trace_num;
        found_pri = attrib_array(1, low_trace_num);
    end
    disp(['Closest PRI is ' num2str(found_pri)])
    if abs(found_pri - pri_num) > 3600
        trace_num = [];
        disp(['No pri found within 3600 pulse intervals (~0.25 s). ' ...
            ' Closest is ' num2str(found_pri)]) 
    else
        disp(['Found pri ' num2str(found_pri) ' in chunk ' num2str(chunk_num) ...
           ' at trace ' num2str(trace_num)]);
    end
else
   disp(['Found pri ' num2str(pri_num) ' in chunk ' num2str(chunk_num) ...
       ' at trace ' num2str(trace_num)]);
end


    
end

