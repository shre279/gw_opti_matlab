%.......................Reading ibound data....................%
function ibound = get_ibound()

global glo_n_layers;
global filename;
global max_row;
global max_col;

f_name = [filename '.h5'];

for i = 1:glo_n_layers
    path = ['///Arrays/ibound' num2str(i)];
    a = h5read(f_name,path);
    ibound(:,:,i) = reshape(a,[max_col max_row])';
    

end

cell_id = h5read([filename '.h5'],'/Stream/02. Cell IDs');
map_temp = int32(zeros([max_col max_row]));
map_temp(cell_id) = 1;
ibound(:,:,1) = ibound(:,:,1) + map_temp';
end

%%
% b = reshape(ibound(:,1),[360 272]);
% imagesc(b');
