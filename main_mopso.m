%clear all;
tic
global max_row;
global max_col;
global filename;
global glo_n_layers;
global glo_ibound;
global glo_stress_period;
global well_position_mat;
global index_wells;
global well_nums;
global all_cost;
global cp;
global gen_wise_data;

warning off;
%% Variable initialisation
max_row = 164;
max_col = 118;
filename = 'modelain2.0';
gen_wise_data = {};
glo_n_layers = 1;

glo_stress_period = size(h5read([filename '.h5'],'/Well/07. Property'),1);
tw = size(h5read([filename '.h5'],'/Well/07. Property'),2);
glo_ibound = get_ibound();

% to deal with unwanted wells
if filename == "modelain2.0"
    l_well = 651;
    cp = 2006.7012992711;
elseif filename == "ain_domain3.0"
    l_well = 536;
    cp = 7854.72739146830;
elseif filename == "modelain4.1"
    l_well = 634;
    cp = 994.066666344009;
else
    l_well = 708;
    cp = 1000;
end

all_cost = [];

%% Well properties to be predetermined

% extract well categories and their corresponding indexes
temp  = char(h5read([filename '.h5'],'/Well/03. Name'));
temp = convertCharsToStrings(temp);
i = strfind(temp,"well");
temp = extractBetween(temp,i(1),strlength(temp));
well_names = split(temp,"w"); well_names(1) = [];well_names = deblank(well_names);
cell_id = double(h5read([filename '.h5'],'/Well/02. Cell IDs'));
arcs = numel(cell_id) - numel(well_names);
well_names = well_names(1:(l_well-arcs));


% get well row and col number


cell_id = cell_id(arcs+1:l_well);
nrc = max_col*max_row;
cell_layer = floor((cell_id - 1)./nrc + 1);
cell_row = floor((cell_id - (cell_layer - 1).*nrc)./max_col + 1);
cell_col = cell_id - (cell_layer - 1).*nrc - (cell_row - 1).*max_col;

% calculate matlab indexing of the wells
well_position_mat = (cell_col-1).*max_row + cell_row;


% calculate the distance of the well
[river_row,river_col] = find(glo_ibound==2);
river_row = repmat(river_row',numel(well_names),1);
river_col = repmat(river_col',numel(well_names),1);
well_dist = min(sqrt((river_row - cell_row).^2 + (river_col - cell_col).^2)');

% add distance based categorisation, threshold distance here!
dist_threshold = 4;         %250m * 4 = 1km is the threshold
index = well_dist>dist_threshold;
well_names(index) = well_names(index) + ".5"; 

well_nums = erase(unique(well_names),"ell"); 
%variables arranged accroding to well_nums


for i = 1:numel(well_nums)
    
    index_wells(i,:) = [endsWith(well_names,"l"+well_nums(i)); zeros([(tw - l_well) 1])]';
end
index_wells = logical(index_wells);


%% MOPSO problem set up

MultiObj.fun = @(x)get_cost_pop(x);
MultiObj.nVar = numel(well_nums);

zone_lu_data = csvread('well_zone_upper_lower.csv');
[~,ai, bi] = intersect(zone_lu_data(:,1), double(well_nums));


MultiObj.var_min(bi) = zone_lu_data(ai,2);       % Zone wise lower bound
MultiObj.var_max(bi) = zone_lu_data(ai,3);       % Zone wise upper bound

% Parameters
params.Np = 8;          % Population size
params.Nr = 600;        % Repository size
params.maxgen = 1000;     % Maximum number of generations
params.W = 0.4;         % Inertia weight
params.C1 = 2;          % Individual confidence factor
params.C2 = 2;          % Swarm confidence factor
params.ngrid = 20;      % Number of grids in each dimension
params.maxvel = 5;      % Maxmium vel in percentage
params.u_mut = 0.5;     % Uniform mutation percentage

% MOPSO
REP = MOPSO(params,MultiObj);
csvwrite('mopso_all_cost.csv',all_cost);
save('gen_wise_data_mopso.mat','gen_wise_data');
save('mopso_all_data.mat');
toc