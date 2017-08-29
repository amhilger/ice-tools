

results_dir = '/data/cees/amhilger/BBAS_PIG/results';
orig_dir = pwd;

transects = [1:18 20:29 31 32];
figure(1); subplot(212)
hold on
leg = legend();

for i = find(transects == 5)
    cd(results_dir)
    load_name = ['b' num2str(transects(i), '%02i') 'Bot_results.mat'];
    load(load_name)
    cd('/data/cees/amhilger/BEDMAP')
    
    [x,y] = ll2ps(results.Lat, results.Long);
    %plot(x,y)
    hold off
    plot3(x,y,1:length(x))
    view(0, 90)

end



cd(orig_dir)
    
    