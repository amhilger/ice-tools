
input_dir = '/data/schroeder/BAS_Data/BBAS/BBAS_results/';
save_dir = '/data/cees/amhilger/BBAS_PIG/results/';

for i = 1:32
    file_name = ['B' num2str(i, '%02i') 'Bot.txt'];
    read_Bot_results(file_name, input_dir, save_dir);
end
