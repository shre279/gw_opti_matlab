%....................Cost function............%
function cost = get_cost_pop(x)

global max_col;
global max_row;
global filename;
global index_wells;
global glo_stress_period;
global all_cost;
global well_position_mat;
global cp;
global gen_wise_data;

f_name = [filename '.mfs'];
cost = ones([size(x,1) 2]);
d = ones([size(x,1) 1]);

..............read well data to update file...%
    
% well_data = read_well();
% well_data.discharge(:) = x;
% write_well(well_data);

total_discharge = 0;
temp = h5read([filename '.h5'],'///Well/07. Property');
arcs = size(temp,2) -  size(index_wells,2);


for p = 1:size(x,1)
    xn = x(p,:);
    temp = h5read([filename '.h5'],'///Well/07. Property');
    total_discharge = 0;
for i = 1:numel(xn)
    
    temp(:,[false([1 arcs]) index_wells(i,:)],1) = ones(glo_stress_period,sum(index_wells(i,:))).*xn(i);
    % total discharge calculated
    total_discharge = total_discharge + xn(i)*sum(index_wells(i,:));
    
end
h5write([filename '.h5'],'///Well/07. Property',temp);


% Runmodflow

[s t] = system(sprintf('mf2k_h5.exe "%s" ', f_name));



if(contains(t,'Error'))
%     cost(p,1) = 1000000;
%     cost(p,2) = 1000000;
cost
else
    
    temp3 = readDat([filename '.hed']);
    
    if size(temp3,1)<glo_stress_period
        % penalty multiplied by the number of unconverged stress periods
        cost(p,1) = 100000*(glo_stress_period-size(temp3,1));
        cost(p,2) = 100000*(glo_stress_period-size(temp3,1));
        
    else
        
        temp2 = reading_ccf();
        temp2 = temp2{7,glo_stress_period*8};
        total_leakage_out = sum(temp2(temp2(:)<0));
        
        % leakage out is negative and is needed to be maximised
        cost(p,1) = total_leakage_out;
        
        % discharge -> negative, (maximization)
        cost(p,2) = total_discharge;    % total_discharge
        
        % add constraints to drawdown
        temp = readDat([filename '.drw']);
        drawdown = temp(end).values;
        dd = drawdown(well_position_mat);
        dd_threshold = 2;
        index = dd>dd_threshold;
        dd_distance = sqrt(sum((dd(index)-dd_threshold).^2));
        % drawndown should not be greater than 2.
        % decreasing the magnitude as penalty
        cost(p,1) = cost(p,1) + cp*dd_distance ; 
        cost(p,2) = cost(p,2) + cp*dd_distance ; 
        d(p) = dd_distance;
        
        
        % only valid solutions without penalty are recorded in the
        % variable all_cost
        
    end
    
    
end

end

gen_wise_data{end+1,1} = {x};
gen_wise_data{end,2} = {cost};
gen_wise_data{end,3} = {d};


all_cost = vertcat(all_cost,[cost d x]);
end