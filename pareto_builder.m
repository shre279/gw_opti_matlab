clear all;
% load('mopso_all_data.mat')
% isd = DetermineDomination(all_cost(:,1:2));
% %scatter(all_cost(:,2),all_cost(:,1))
% scatter(all_cost(~isd,2),all_cost(~isd,1),"filled",'r')
% hold on;
load('mopso_all_data.mat')
isd = DetermineDomination(all_cost(:,1:2));
% scatter(all_cost(:,2),all_cost(:,1))
scatter(all_cost(~isd,2),all_cost(~isd,1),'b')
