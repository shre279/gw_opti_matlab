function [temp, right, front] = reading_ccf(vargin)

global filename;

f_name = [filename '.ccf'];
if nargin == 1 
    f_name = [filename '.ccf2'];
end
fid = fopen(f_name, 'r');
%fid = fopen("feb_final.ccf",'r');
k = 0;
while ~feof(fid)
    k = k+1;
    CBC(k,1).KSPT = fread(fid, 1, 'int32');
    CBC(k,1).KPER = fread(fid, 1, 'int32');
    CBC(k,1).DESC = fread(fid, 16, 'char');
    CBC(k,1).DESC = char(CBC(k,1).DESC');
    CBC(k,1).NCOL = fread(fid, 1, 'int32');
    CBC(k,1).NROW = fread(fid, 1, 'int32');
    CBC(k,1).NLAY = fread(fid, 1, 'int32');
    %fprintf('Reading %s for time step %i, stress period %i\n', CBC(k,1).DESC, CBC(k,1).KSPT, CBC(k,1).KPER);
    
    if CBC(k,1).NLAY > 0
        % If NLAY is greater than zero, a 3D array of real numbers follows NLAY.
        % The number of values is NCOL x NROW x NLAY. To read it, you can use
        % a loop over the layers that contains a loop over rows that contains
        % a loop over columns.
        data0 = read_modflow_array(fid, CBC(k,1).NROW, CBC(k,1).NCOL, abs(CBC(k,1).NLAY));
        
        data0 = reshape(data0,[CBC(k,1).NCOL CBC(k,1).NROW abs(CBC(k,1).NLAY)]);
        data0_dash = zeros([CBC(k,1).NROW CBC(k,1).NCOL abs(CBC(k,1).NLAY)]);
        for i = 1:abs(CBC(k,1).NLAY)
            data0_dash(:,:,i) = data0(:,:,i)';
        end
        
        CBC(k,1).data = data0_dash;
        
    elseif CBC(k,1).NLAY <= 0
        %error('negative NLAY cases not implemented yet')
        ITYPE = fread(fid, 1, 'int32');
        DELT = fread(fid, 1, 'float');
        PERTIM = fread(fid, 1, 'float');
        TOTIM = fread(fid, 1, 'float');
        
        if ITYPE == 0 || ITYPE == 1
            data0 = read_modflow_array(fid, CBC(k,1).NROW, CBC(k,1).NCOL, abs(CBC(k,1).NLAY));
            
            data0 = reshape(data0,[CBC(k,1).NCOL CBC(k,1).NROW abs(CBC(k,1).NLAY)]);
            data0_dash = zeros([CBC(k,1).NROW CBC(k,1).NCOL abs(CBC(k,1).NLAY)]);
            for i = 1:abs(CBC(k,1).NLAY)
                data0_dash(:,:,i) = data0(:,:,i)';
            end
            
            CBC(k,1).data = data0_dash;
            %             to read this 3d data
            %             im = reshape(data0,[ max_col max_row max_layer])
            %             img(:,:,i) = im(:,:,i)';
            
        elseif ITYPE == 3 % read in row major order
            
            data3 = fread(fid,CBC(k,1).NROW*CBC(k,1).NCOL,'int32');
            data3_dash = fread(fid,CBC(k,1).NROW*CBC(k,1).NCOL,'float');
            CBC(k,1).data = [ data3 data3_dash ];
            %             to arrange data in 2D:
            %             im = reshape(data3_dash, [max_col max_row]);
            %             im = im';
            
        elseif ITYPE == 2
            ICELL = [];
            v = [];
            NLIST = fread(fid,1,'int32'); %remove comment after debugging
            data2 = zeros(CBC(k,1).NROW*CBC(k,1).NCOL,1);
            NVAL = 1;
            if(NLIST > 0)
                NRC = CBC(k,1).NROW*CBC(k,1).NCOL*abs(CBC(k,1).NLAY);
            end
            fieldsizes = [4 ones(1,NVAL).*4 ];%...]; %int32 float ...
                skip = @(n) sum(fieldsizes) - fieldsizes(n); %sum up of field sizes except field n
                offset = @(n) sum(fieldsizes(1:n)); %offset to element n+1
                temp_fid = ftell(fid);
                ICELL = fread(fid, NLIST, 'int32', skip(1));
                %fseek(fid, offset(1), -1);
                if NLIST > 0
                for i  = 1:NVAL
                    fseek(fid,temp_fid,-1);
                    fseek(fid, offset(i), 0);
                    v(i,:) = fread(fid, NLIST, 'float', skip(i+1));
                end
                fseek(fid,skip(NVAL)*-1,0);
                end
             CBC(k,1).data = [ICELL v'];
            
            
        elseif ITYPE == 5 
            Value = [];
            VAL = [];
            ICELL = [];
            
            NVAL = fread(fid,1,'int32');
            if(NVAL>1)
                for i = 1:NVAL-1
                    t = fread(fid,16,'char');
                    titles{i} = char(t');
                end
            end
            NLIST = fread(fid,1,'int32');
            if(NLIST > 0)
                
                %data = float(fread(fid,NLIST,['int32 ' repmat('float ',[1 NVAL])]));
                % reading in invalid format to speed up the code.
                %data1 = fread(fid,NLIST,'int32');
                %data2 = fread(fid,NLIST*NVAL,'float');
                % code slow down here due to loop.
                
                
                %% debugging
                v = [];
                fieldsizes = [4 ones(1,NVAL).*4 ];%...]; %int32 float ...
                skip = @(n) sum(fieldsizes) - fieldsizes(n); %sum up of field sizes except field n
                offset = @(n) sum(fieldsizes(1:n)); %offset to element n+1
                temp_fid = ftell(fid);
                ICELL = fread(fid, NLIST, 'int32', skip(1));
                %fseek(fid, offset(1), -1);
                for i  = 1:NVAL
                    fseek(fid,temp_fid,-1);
                    fseek(fid, offset(i), 0);
                    v(i,:) = fread(fid, NLIST, 'float', skip(i+1));
                end
                fseek(fid,skip(NVAL)*-1,0);
                %% old, slow and definitely correct
                %                 for i = 1: NLIST
                %                     ICELL(i) = fread(fid,1,'int32');
                %                     v = fread(fid,NVAL,'float');
                %                     Value(i,:) = v';
                %
                %                 end
                CBC(k,1).data = [ICELL v'];
            end
            
            %NLIST = fread(fid,1,'int32');
        elseif ITYPE == 4
            
            data0 = read_modflow_array(fid, CBC(k,1).NROW, CBC(k,1).NCOL, 1);
            
            data0 = reshape(data0,[CBC(k,1).NCOL CBC(k,1).NROW 1]);
            data0_dash = zeros([CBC(k,1).NROW CBC(k,1).NCOL 1]);
            for i = 1:abs(CBC(k,1).NLAY)
                data0_dash(:,:,i) = data0(:,:,i)';
            end
            CBC(k,1).data = data0_dash;
        end
        
    end
    
    
end

temp = struct2cell(CBC);
right = temp(7,3);
front = temp(7,4);

fclose(fid);

    function data = read_modflow_array(fid, NR, NC, NL)
        data = zeros([NR* NC* NL 1]);    %(100,100,1)
        %         for il = 1:NL
        %             for ir = 1:NR
        %                 for ic = 1:NC
        %                     data(ir,ic, il)=fread(fid, 1, 'float');
        %                 end
        %             end
        %         end
        data(:)=fread(fid, NR*NC*NL, 'float');
    end

end