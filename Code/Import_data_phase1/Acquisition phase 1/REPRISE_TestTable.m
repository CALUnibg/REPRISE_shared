classdef REPRISE_TestTable
    % Class that cotains the data corresponding to a test table
    
    properties(SetAccess = private, GetAccess = private)
        name
        
        % definition
        force
        offset
        ampl        
        freq
        
        % data
        data
    end
    
    methods
        function self = REPRISE_TestTable(name, force, offset, ampl, freq )
            self.name = name;
            
            self.force = force;
            self.offset = offset;
            self.ampl = ampl;
            self.freq = freq;
            
            self.data = containers.Map('KeyType', 'char','ValueType', 'any');
            
            self.data('phase_A') = containers.Map('KeyType', 'char','ValueType', 'any');
            self.data('phase_B') = containers.Map('KeyType', 'char','ValueType', 'any');
            self.data('phase_C') = containers.Map('KeyType', 'char','ValueType', 'any');
            self.data('torquemeter') = containers.Map('KeyType', 'char','ValueType', 'any');
            
            self.data('linear_Motor_Drive_Current') = containers.Map('KeyType', 'char','ValueType', 'any');
            self.data('EMA_Position_reference_cDAQ') = containers.Map('KeyType', 'char','ValueType', 'any');
            self.data('Siko_linear_encoder') = containers.Map('KeyType', 'char','ValueType', 'any');
            
            self.data('absolute_encoder_biss') = containers.Map('KeyType', 'char','ValueType', 'any'); 
            self.data('bit_failure') = containers.Map('KeyType', 'char','ValueType', 'any'); 
            self.data('EMA_LVDT_position') = containers.Map('KeyType', 'char','ValueType', 'any'); 
            self.data('EMA_position_reference_cRIO') = containers.Map('KeyType', 'char','ValueType', 'any'); 
            self.data('linear_motor_supplied_current') = containers.Map('KeyType', 'char','ValueType', 'any'); 
            self.data('load_cell_measure') = containers.Map('KeyType', 'char','ValueType', 'any'); 
            self.data('load_cell_reference') = containers.Map('KeyType', 'char','ValueType', 'any'); 
            self.data('relative_encoder_biss') = containers.Map('KeyType', 'char','ValueType', 'any');
            self.data('temperature') = containers.Map('KeyType', 'char','ValueType', 'any');
            
            for kk = keys(self.data)
                key = kk{1};
                
                % force
                self.data(key) = containers.Map('KeyType', 'char','ValueType', 'any');
                l1 = self.data(key);
                for ll = force
                    load = ll{1};
                    l1(load) = containers.Map('KeyType', 'char','ValueType', 'any');
                    l2 = l1(load);
                    
                    % offset
                    for oo = offset
                        off = oo{1};
                        l2(off) = containers.Map('KeyType', 'char','ValueType', 'any');
                        l3 = l2(off);

                        % amplitude
                        for aa = ampl
                            amp = aa{1};
                            l3(amp)  = containers.Map('KeyType', 'char','ValueType', 'any');
                            l4 = l3(amp);

                            % freq
                            for frfr = freq
                                fr = frfr{1};
                                l4(fr) = 0;
                            end
                        end
                    end
                end              
            end

        end
        
        function set(self, dataType, force, offset, ampl, freq, signal)
            l1 = self.data(dataType);
            l2 = l1(force);
            l3 = l2(offset);
            l4 = l3(ampl);
            l4(freq) = signal; %#ok<NASGU>
        end
        
        function signal = get(self, dataType,force, offset, ampl, freq)
            % return the signal corresponding to the parameter
            %   Input:
            %       dataType: the type of data 
            %               (see *.getDataTypes for the possible options)
            %       force: the force used in the requested signal
            %               (see *.getForces for the possible options)
            %       offset: the offset used in the requested signal
            %               (see *.getOffsets for the possible options)
            %       ampl: the amplitude used in the requested signal
            %               (see *.getAmplitudes for the possible options)
            %       freq: the frequency used in the requested signal
            %               (see *.getfrequencies for the possible options)
            %
            %   Output:
            %       signal: a timeseries object containing the requested signal
            %                   (see "help timeseries" for more information)
            
            l1 = self.data(dataType);
            l2 = l1(force);
            l3 = l2(offset);
            l4 = l3(ampl);
            signal = l4(freq);
        end
        
        function n = getName(self)
            n = self.name;
        end
        
        function dataTypes = getDataTypes(self)
            dataTypes = keys(self.data)';
        end

        function forces = getForces(self)
            forces = self.force';
        end
        
        function offsets = getOffsets(self)
            offsets = self.offset';
        end
        
        function ampls = getAmplitudes(self)
            ampls = self.ampl';
        end

        function freqs = getfrequencies(self)
            freqs = self.freq';
        end
    end
    
end

