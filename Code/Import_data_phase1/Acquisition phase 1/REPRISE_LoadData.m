function data_table = REPRISE_LoadData( ...
                                saving_folder, ...
                                data_folder, ...
                                file_name, ...
                                force, ...
                                offset, ...
                                ampl, ...
                                freq, ...
                                type, ...
                                fs_el, ...
                                fs_me,...
                                to_save,...
                                torquemeter_test,...
                                verbose...
                                )
    % Function that load a complete test table in matlab and save it in a MAT file
    % 
    %   Input: 
    %       - saving_folder: the path to the folder in with the file has to be save.
    %
    %       - data_folder: a string containing the path of the folder that contains all the file
    %
    %       - file_name: the name of the loaded test. It will be used to select the name of the MAT
    %                    file
    %
    %       - offset: the values of offset used in this test
    %               NB: it has to be a row cell array
    %
    %       - ampl: the values of amplitudes used in this test                         
    %               NB: it has to be a row cell array
    %
    %       - freq: the values of frequency used in this test
    %               NB: it has to be a row cell array
    %
    %       - force: the values of load force used in this test   
    %               NB: it has to be a row cell array
    %
    %       - type: the format type:
    %             * lvm: if the cDAQ measurement are saved with the lvm format
    %             * with_time: if the cDAQ measurement are saved with the TDMS format with the time column
    %             * tdms: the cDAQ measurement are saved with the TDMS format without the time column
    %           NB: the string are not case sensitive
    %
    %       - fs_el: sampling frequency of cDAQ_EL
    %
    %       - fs_me: sampling frequency of cDAQ_ME
    %
    %       - to_save: boolean that indicates if the file has to be saved
    %    
    %       - torquemeter_test: boolean that indicates if a test is
    %                           torquemeter one or not
    %
    %       - verbose: boolean that indicates if a string output on the console is requested
    %
    %   Output:
    %       - data: an instance of the class TestTable containing all the imported data
    %
    %   INFORMATION ON THE FOLDERS STRUCTURE:
    %       The specified dataFolder has to contain 3 subfolder:
    %           cDAQ_EL
    %           cDAQ_ME
    %           cRIO
    %       and each of this has to contain all the TDMS file to import.
    %   FILE ORDER:
    %       All the file, sorted in alphabetical order, has to sweep all the possible combination
    %       with the following priority on the four parameter:
    %           Force
    %           Offset
    %           Ampl
    %           Freq

    %% Number of row
    nForce = length(force);
    nOffset = length(offset);
    nAmpl = length(ampl);
    nFreq = length(freq);

    nRow = nForce * nOffset * nAmpl * nFreq;
    
    data_table = REPRISE_TestTable(file_name, force, offset, ampl, freq );

    %% Files name
    folder_cDAQ_ME = strcat(data_folder,'\cDAQ_ME\');
    folder_cDAQ_EL = strcat(data_folder,'\cDAQ_EL\');
    folder_cRIO = strcat(data_folder,'\cRIO\');

    if strcmpi(type, 'lvm')
        files_cDAQ_ME = dir([folder_cDAQ_ME,'*.lvm']);
    else
        files_cDAQ_ME = dir([folder_cDAQ_ME,'*.tdms']);
    end
    
    names_cDAQ_ME = sort({files_cDAQ_ME.name});

    if strcmpi(type, 'lvm')
        files_cDAQ_EL = dir([folder_cDAQ_EL,'*.lvm']);
    else
        files_cDAQ_EL = dir([folder_cDAQ_EL,'*.tdms']);
    end
    
    names_cDAQ_EL = sort({files_cDAQ_EL.name});

    files_cRIO = dir([folder_cRIO,'*.tdms']);
    names_cRIO = sort({files_cRIO.name});
    
    %% Index initialization
    index_force = 1;
    index_offset = 1;
    index_ampl = 1;
    index_freq = 1;

    %% Load libray
    
    % TDMS
    LoadLibraryTDMS();
    
    % LVM
    delimiter = '\t';
    formatSpec = '%s%s%s%s%[^\n\r]';
    
    %% Load data
    for nn = 1 : 1 : nRow
    
        if verbose
            fprintf('Row = %i/%i \n',nn,nRow);
        end
        
        % Conversione degli indici in chiavi
        ll = force(index_force);
        ll = ll{1};
        
        oo = offset(index_offset);
        oo = oo{1};

        aa = ampl(index_ampl);
        aa = aa{1};

        ff = freq(index_freq);
        ff = ff{1};
        
        %% cDAQ ME

        % import data
        data = cell(2,1);
        
        fold_name = [ folder_cDAQ_ME names_cDAQ_ME{nn} ];
        
        if strcmpi( type, 'lvm' )
            fileID = fopen( fold_name, 'r');
            data_lvm = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string',  'ReturnOnError', false);
            fclose(fileID);
            
            nTime = length(data_lvm{1,1});
            time = zeros(nTime,1);
            
            for tt = 1 : 1 : nTime
                temp = textscan(char(strrep(data_lvm{1,1}(tt), ',', '.')), '%f');
                time(tt) =  temp{1};

                temp = textscan(char(strrep(data_lvm{1,2}(tt), ',', '.')), '%f');
                data{1}(tt) = temp{1}; % linear_Motor_Drive_Current

                temp = textscan(char(strrep(data_lvm{1,3}(tt), ',', '.')), '%f');
                data{2}(tt) = temp{1}; % EMA_Position_reference_cDAQ
                
                % Siko measure not used
                % temp = textscan(char(strrep(data_lvm{1,4}(tt), ',', '.')), '%f');
                % data{3}(tt) = temp{1}; % Siko_linear_encoder
            end
        else
            data_tdms = importTDMS(fold_name);

            time = 0 : (1/fs_me) : (length(data_tdms{1})-1)/fs_me;
            
            if strcmpi( type, 'with_time' )
                data{1} = data_tdms{2}';
                data{2} = data_tdms{3}';
                % data{3} = data_tdms{4}';
            else
                data{1} = data_tdms{1}';
                data{2} = data_tdms{2}';
                % data{3} = data_tdms{3}';
            end
            
        end
        
        % save data
        ts = timeseries(data{1}, time);
        ts.Name = 'linear_Motor_Drive_Current';
        ts.DataInfo.Units = 'A';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);

        ts = timeseries( data{2}, time);
        ts.Name = 'EMA_Position_reference_cDAQ';
        ts.DataInfo.Units = 'mm';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);

       % ts = timeseries( data{3}, time);
       % ts.Name = 'Siko_linear_encoder';
       % ts.DataInfo.Units = 'mm';
       % data_table.set(ts.Name,ll, oo, aa, ff, ts);

        %% cDAQ EL
        
        % import data
        data = cell(4,1);
        fold_name = [ folder_cDAQ_EL names_cDAQ_EL{nn} ];
        
        if strcmpi( type, 'lvm' )
            fileID = fopen(fold_name,'r');
            data_lvm = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string',  'ReturnOnError', false);
            fclose(fileID);
            
            nTime = length(data_lvm{1,1});
            time = zeros(nTime,1);
            
            for tt = 1 : 1 : nTime
                temp = textscan(char(strrep(data_lvm{1,1}(tt), ',', '.')), '%f');
                time(tt) =  temp{1};

                temp = textscan(char(strrep(data_lvm{1,2}(tt), ',', '.')), '%f');
                data{1}(tt) = temp{1}; % Phase A

                temp = textscan(char(strrep(data_lvm{1,3}(tt), ',', '.')), '%f');
                data{2}(tt) = temp{1}; % Phase B

                temp = textscan(char(strrep(data_lvm{1,4}(tt), ',', '.')), '%f');
                data{3}(tt) = temp{1}; % Phase C
                
                data{4}(tt) = 0; % Torquemeter
            end
        else
            data_tdms = importTDMS(fold_name);

            time = 0 : (1/fs_el) : (length(data_tdms{1})-1)/fs_el;
            
            if strcmpi( type, 'with_time' )
                data{1} = data_tdms{2}';
                data{2} = data_tdms{3}';
                data{3} = data_tdms{4}';
                data{4} = data_tdms{5}';
            else
                data{1} = data_tdms{1}';
                data{2} = data_tdms{2}';
                data{3} = data_tdms{3}';
                data{4} = data_tdms{4}';
            end
            
        end
        
        ts = timeseries(data{1}, time);
        ts.Name = 'phase_A';
        ts.DataInfo.Units = 'A';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);

        ts = timeseries(data{2}, time);
        ts.Name = 'phase_B';
        ts.DataInfo.Units = 'A';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);

        ts = timeseries(data{3}, time);
        ts.Name = 'phase_C';
        ts.DataInfo.Units = 'A';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);

        if torquemeter_test == false
            data{4} = zeros(length(time) , 1); % nel caso in cui la colonna torsiometro ha dati in più
        end
        ts = timeseries(convert_torque(data{4}), time);
        ts.Name = 'torquemeter';
        ts.DataInfo.Units = 'Nm';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);
        
       %% cRIO       
        fold_name = [ folder_cRIO names_cRIO{nn} ];
        data = importTDMS(fold_name);

        time = data{1}';
        time = time/1000; % per portarlo in secondi

        ts = timeseries(data{2}', time);
        ts.Name = 'EMA_position_reference_cRIO';
        ts.DataInfo.Units = 'mm';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);
        
        ts = timeseries(data{3}', time);
        ts.Name = 'absolute_encoder_biss';
        ts.DataInfo.Units = 'mm';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);
        
        ts = timeseries(data{4}', time);
        ts.Name = 'EMA_LVDT_position';
        ts.DataInfo.Units = 'mm';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);
        
        ts = timeseries(data{5}', time);
        ts.Name = 'linear_motor_supplied_current';
        ts.DataInfo.Units = 'A';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);
        
        ts = timeseries(data{6}', time);
        ts.Name = 'load_cell_measure';
        ts.DataInfo.Units = 'N';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);
        
        ts = timeseries(data{7}', time);
        ts.Name = 'temperature';
        ts.DataInfo.Units = '°C';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);
        
        ts = timeseries(data{8}', time);
        ts.Name = 'load_cell_reference';
        ts.DataInfo.Units = 'N';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);
        
        ts = timeseries(data{9}', time);
        ts.Name = 'relative_encoder_biss';
        ts.DataInfo.Units = 'mm';
        data_table.set(ts.Name,ll, oo, aa, ff, ts);
        
        % Bit check failure not used
        % if(length(data{10})<length(time))
        %    ts = timeseries([data{10}'; 0], time);
        % else
        %    ts = timeseries(data{10}', time);
        % end       
        % ts.Name = 'bit_failure';
        % data_table.set(ts.Name,ll, oo, aa, ff, ts);

        % update index
        index_freq = index_freq + 1;
        if index_freq > nFreq
            index_freq = 1;
            index_ampl = index_ampl + 1;
            if index_ampl > nAmpl
                index_ampl = 1;
                index_offset = index_offset + 1;
                if index_offset > nOffset
                    index_offset = 1;
                    index_force = index_force + 1;
                end
            end
        end
        
    end

    %% Unload library
    UnloadLibraryTDMS();
    
    %% Salvataggio
    if (to_save)
        if verbose
            fprintf('Saving...\n');
        end
        
        if strcmpi(saving_folder,'')
            path = strcat(file_name,'.mat');
        else
            path = strcat(saving_folder,'\',file_name,'.mat');
        end

        save(path, 'data_table','-v7.3');
        
        if verbose
            fprintf('Done\n');
        end
    end
    
end

