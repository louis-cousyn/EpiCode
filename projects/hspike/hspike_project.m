%% Analysis script for Spike x Sleep x SUA project
%
% (c) Stephen Whitmarsh, stephen.whitmarsh@gmail.com
%
set(0, 'DefaultFigurePosition', [2500 100  1000 1000]);
set(0, 'DefaultFigurePosition', [200 300  1000 500]);

%% Add path

restoredefaultpath
if isunix
    addpath /network/lustre/iss01/charpier/analyses/stephen.whitmarsh/fieldtrip
    addpath /network/lustre/iss01/charpier/analyses/stephen.whitmarsh/EpiCode/projects/hspike/
    addpath /network/lustre/iss01/charpier/analyses/stephen.whitmarsh/EpiCode/shared/
    addpath /network/lustre/iss01/charpier/analyses/stephen.whitmarsh/EpiCode/shared/utilities
    addpath(genpath('/network/lustre/iss01/charpier/analyses/stephen.whitmarsh/scripts/releaseDec2015/'));
    addpath /network/lustre/iss01/charpier/analyses/stephen.whitmarsh/EpiCode/external/subaxis    
    addpath /network/lustre/iss01/charpier/analyses/stephen.whitmarsh/EpiCode/external/sigstar-master
    addpath(genpath('/network/lustre/iss01/charpier/analyses/stephen.whitmarsh/epishare-master'));
end

if ispc
    addpath \\lexport\iss01.charpier\analyses\stephen.whitmarsh\fieldtrip
    addpath \\lexport\iss01.charpier\analyses\stephen.whitmarsh\EpiCode\projects\hspike
    addpath \\lexport\iss01.charpier\analyses\stephen.whitmarsh\EpiCode\shared
    addpath \\lexport\iss01.charpier\analyses\stephen.whitmarsh\EpiCode\shared\utilities
    addpath \\lexport\iss01.charpier\analyses\stephen.whitmarsh\EpiCode\external\altmany-export_fig-8b0ba13\
    addpath \\lexport\iss01.charpier\analyses\stephen.whitmarsh\EpiCode\external\subaxis    
    addpath \\lexport\iss01.charpier\analyses\stephen.whitmarsh\MatlabImportExport_v6.0.0
    addpath \\lexport\iss01.charpier\analyses\stephen.whitmarsh\EpiCode\external\sigstar-master
    addpath(genpath('\\lexport\iss01.charpier\analyses\stephen.whitmarsh\epishare-master'));
end
ft_defaults

feature('DefaultCharacterSet', 'CP1252') % To fix bug for weird character problems in reading neurlynx

config = hspike_setparams;
labels = ["BAD__START__", "BAD__END__", "PHASE_1__START__", "PHASE_1__END__", "PHASE_2__START__", "PHASE_2__END__", "PHASE_3__START__", "PHASE_3__END__", "REM__START__", "REM__END__", "AWAKE__START__", "AWAKE__END__", "NO_SCORE__START__", "NO_SCORE__END__"];

%% General analyses, looping over patients
%      exportHypnogram(config{ipatient})

for ipatient = 3:7
    
    config = hspike_setparams;

    MuseStruct{ipatient}                                        = readMuseMarkers(config{ipatient}, false);
    MuseStruct{ipatient}                                        = alignMuseMarkersXcorr(config{ipatient}, MuseStruct{ipatient}, false);
    [clusterindx{ipatient}, LFP_cluster{ipatient}]              = clusterLFP(config{ipatient}, MuseStruct{ipatient}, false);
    [MuseStruct{ipatient}, ~,~, LFP_cluster_detected{ipatient}] = detectTemplate(config{ipatient}, MuseStruct{ipatient}, LFP_cluster{ipatient}{1}.Hspike.kmedoids{6}, false);
    MuseStruct{ipatient}                                        = alignTemplates(config{ipatient}, MuseStruct{ipatient}, LFP_cluster_detected{ipatient});
    MuseStruct{ipatient}                                        = updateMarkers(config{ipatient}, MuseStruct{ipatient}, labels);
      
    % get hypnogram data
    [marker{ipatient}, hypnogram{ipatient}, hypmusestat{ipatient}] = hypnogramMuseStats(config{ipatient}, MuseStruct{ipatient}, true);
%     
%     % template LFP
    config{ipatient}.LFP.name = {'template1', 'template2', 'template3', 'template4', 'template5', 'template6'};
    LFP{ipatient}             = readLFP(config{ipatient}, MuseStruct{ipatient}, true);
%     
%     % template TFR
    config{ipatient}.TFR.name = {'template1', 'template2', 'template3', 'template4', 'template5', 'template6'};    
    TFR{ipatient}             = TFRtrials(config{ipatient}, true);
%     
%     writeSpykingCircusDeadfiles(config{ipatient}, MuseStruct{ipatient}, true);
    writeSpykingCircusFileList(config{ipatient}, true);
%     writeSpykingCircusParameters(config{ipatient});

    SpikeRaw{ipatient}                    = readSpikeRaw_Phy(config{ipatient}, false);
%     
%     if ipatient == 3
%         SpikeRaw{ipatient}{1}.template_maxchan(1) = 1;
%     end

    SpikeWaveforms{ipatient} = readSpikeWaveforms(config{ipatient}, SpikeRaw{ipatient}, true);
    
% figure; plot(mean(vertcat(SpikeWaveforms{ipatient}{1}{4}.trial{:})))

    % segment into trials based on IED markers
    config{ipatient}.spike.name         = {'template1', 'template2', 'template3', 'template4', 'template5', 'template6'};
    
    SpikeTrials_timelocked{ipatient}    = readSpikeTrials_MuseMarkers(config{ipatient}, MuseStruct{ipatient}, SpikeRaw{ipatient}, true);
    SpikeDensity_timelocked{ipatient}   = spikeTrialDensity(config{ipatient}, SpikeTrials_timelocked{ipatient}, true);
    
    config{ipatient}.plot.ncols         = 6;
    config{ipatient}.plot.name          = {'template1', 'template2', 'template3', 'template4', 'template5', 'template6'};    
    plot_patterns_multilevel_examples(config{ipatient});
    
    % segment into equal periods
    SpikeTrials_windowed{ipatient}      = readSpikeTrials_windowed(config{ipatient}, MuseStruct{ipatient}, SpikeRaw{ipatient}, false);
    SpikeStats_windowed{ipatient}       = spikeTrialStats(config{ipatient}, SpikeTrials_windowed{ipatient}, false);
    
  
    

    plotstats(config_trimmed{ipatient});

    %     SpikeWaveforms{ipatient}              = readSpikeWaveforms(config_trimmed{ipatient}, SpikeTrials_windowed{ipatient}, true);
    
end


% prepare spyking-circus

for ipatient = 3:7
    
    config                  = hspike_setparams;
    [MuseStruct{ipatient}]  = readMuseMarkers(config{ipatient});
    [MuseStruct{ipatient}]  = alignMuseMarkersXcorr(config{ipatient});
    
    % add any new artefacts
    MuseStruct{ipatient}    = updateMarkers(config{ipatient}, MuseStruct{ipatient}, labels);
    
    % write spyking-circus files
    writeSpykingCircusDeadfiles(config{ipatient}, MuseStruct{ipatient}, true);
    writeSpykingCircusFileList(config{ipatient}, true);
    writeSpykingCircusParameters_new(config{ipatient});
end
    
for ipatient = 2 : 4
        config = hspike_setparams;
        SpikeRaw{ipatient} = readSpikeRaw_Phy_new(config{ipatient}, false);
        SpikeWaveforms{ipatient} = readSpikeWaveforms(config{ipatient}, SpikeRaw{ipatient}, true);
end



% Average over patients
[dat_unit, dat_lfp]                         = stats_IED_behaviour(config, true);
[dat_window]                                = stats_unit_behaviour(config, true);
[dat_density, stats_all, stats_responsive]  = stats_unit_density(config, true);

for ipatient = 1 : 7
    plot_patterns_multilevel(config{ipatient});
end



%% Create slurm job list
config              = hspike_setparams;
fname_slurm_joblist = fullfile('//network/lustre/iss01/charpier/analyses/stephen.whitmarsh/EpiCode/projects/hspike/slurm_job_list.txt');
delete(fname_slurm_joblist);
for ipatient = 3:7
    for ipart = 1 : size(config{ipatient}.directorylist, 2)
        subjdir     = config{ipatient}.prefix(1:end-1);
        partdir     = ['p', num2str(ipart)];
        if ~isfield(config{ipatient}.circus, 'channelname')
            fid = fopen(fname_slurm_joblist, 'a');
            if fid == -1
                error('Could not create/open %s', fname_slurm_joblist);
            end
            filename    = 'SpykingCircus.params';
            dirname     = strcat('//network/lustre/iss01/charpier/analyses/stephen.whitmarsh/data/hspike/', subjdir, '/', partdir);
            fprintf(fid,'module load spyking-circus/1.0.8 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
            fclose(fid);
        else
            for chandir = unique(config{ipatient}.circus.channelname)
                fid = fopen(fname_slurm_joblist, 'a');
                if fid == -1
                    error('Could not create/open %s', fname_slurm_joblist);
                end
                temp        = strcmp(config{ipatient}.circus.channelname, chandir);
                firstchan   = string(config{ipatient}.circus.channel(find(temp,1,'first')));
                filename    = 'SpykingCircus.params';
                dirname     = strcat('//network/lustre/iss01/charpier/analyses/stephen.whitmarsh/data/hspike/', subjdir, '/', partdir, '/', string(chandir));
                fprintf(fid,'module load spyking-circus/1.0.8 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
                fclose(fid);
            end
        end
    end
end





% 
% 
% %% Create slurm job list
% config              = hspike_setparams;
% fname_slurm_joblist = fullfile(config{1}.datasavedir, 'slurm_job_list.txt');
% delete(fname_slurm_joblist);
% for ipatient = 1:7
%     for ipart = 1 : size(config{ipatient}.directorylist, 2)
%         subjdir     = config{ipatient}.prefix(1:end-1);
%         partdir     = ['p', num2str(ipart)];
%         if ~isfield(config{ipatient}.circus, 'channelname')
%             fid = fopen(fname_slurm_joblist, 'a');
%             if fid == -1
%                 error('Could not create/open %s', fname_slurm_joblist);
%             end
%             filename    = strcat(config{ipatient}.prefix, 'p', num2str(ipart), '-multifile-', config{ipatient}.circus.channel{1} ,'.ncs');
%             dirname     = strcat('//network/lustre/iss01/charpier/analyses/stephen.whitmarsh/data/hspike/', subjdir, '/', partdir);
%             fprintf(fid,'module load spyking-circus/0.9.9 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
%             fprintf('module load spyking-circus/0.9.9 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
%             fclose(fid);
%         else
%             for chandir = unique(config{ipatient}.circus.channelname)
%                 fid = fopen(fname_slurm_joblist, 'a');
%                 if fid == -1
%                     error('Could not create/open %s', fname_slurm_joblist);
%                 end
%                 temp        = strcmp(config{ipatient}.circus.channelname, chandir);
%                 firstchan   = string(config{ipatient}.circus.channel(find(temp,1,'first')));
%                 filename    = strcat(config{ipatient}.prefix, 'p', num2str(ipart), '-multifile-', firstchan ,'.ncs');
%                 dirname     = strcat('//network/lustre/iss01/charpier/analyses/stephen.whitmarsh/data/hspike/', subjdir, '/', partdir, '/', string(chandir));
%                 fprintf(fid,'module load spyking-circus/0.9.9 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
%                 fprintf('module load spyking-circus/0.9.9 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
%                 fclose(fid);
%             end
%         end
%     end
% end

%% BrainNetViewer
addpath '\\lexport\iss01.charpier\analyses\stephen.whitmarsh\BrainNetViewer_20191031'

config  = hspike_setparams;
nodes_all = [];

% Separate per patient
for ipatient = 1 : 7
    
    cfg     = config{ipatient};
    fname   = cfg.locfile;
    fid     = fopen(fname);
    dat     = textscan(fid, '%s%d%s%f%f%f%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s', 'Headerlines', 4, 'delimiter', ';');
    fclose(fid);
    
    clear elec
    toclear = [];
    
    for i = 1 : size(dat{1}, 1)
        elec(i).name = string(dat{1}{i});
        if isempty(dat{1}{i})
            elec(i).name = elec(i-1).name;
        end
        elec(i).plotnr = dat{2}(i);
        elec(i).MNI_x = dat{4}(i);
        elec(i).MNI_y = dat{5}(i);
        elec(i).MNI_z = dat{6}(i);
        elec(i).name_cat = strcat('_', elec(i).name, '_',  num2str(elec(i).plotnr));
        elec(i).color = 0;
        
        for name = string(cfg.LFP.channel)
            if contains(name, elec(i).name_cat)
                elec(i).color = 1;
            end
        end
        
        if elec(i).plotnr == 0
            toclear = [toclear, i];
        end
    end
    elec(toclear) = [];
    
    clear nodes
    for i = 1 : size(elec, 2)
        nodes(i, :) = [elec(i).MNI_x, elec(i).MNI_y, elec(i).MNI_z, elec(i).color, 3, ipatient];
    end
    
    fname_node  = fullfile(cfg.datasavedir, [cfg.prefix, 'brainnet.node']);
    fname_surf  = '\\lexport\iss01.charpier\analyses\stephen.whitmarsh\BrainNetViewer_20191031\Data\SurfTemplate\BrainMesh_Ch2.nv';
    fname_cfg   = '\\lexport\iss01.charpier\analyses\stephen.whitmarsh\data\hspike\brainnet_config.mat';
    fname_image = fullfile(cfg.imagesavedir, [cfg.prefix, 'brainnet.jpg']);
    
    dlmwrite(fname_node, nodes, '\t');
    
    % concatinate over patients
    nodes_all   = [nodes_all; nodes];
    
    BrainNet_MapCfg(fname_node, fname_surf, fname_cfg, fname_image);
end

fname_nodes_all = fullfile(cfg.datasavedir, 'brainnet_all.node');
fname_image_all = fullfile(cfg.imagesavedir, 'brainnet_all.jpg');

% resize nodes that are not analyzed
nodes_all(nodes_all(:, 4) == 0, 5) = 1;

dlmwrite(fname_nodes_all, nodes_all, '\t');
BrainNet_MapCfg(fname_nodes_all, fname_surf, fname_cfg, fname_image_all);

% https://www.nitrc.org/docman/view.php/504/1190/BrainNet%20Viewer%20Manual%201.41.pdf
% The node file is defined as an ASCII text file with the suffix node. In the node file, there
% are 6 columns: columns 1-3 represent node coordinates, column 4 represents node
% colors, column 5 represents node sizes, and the last column represents node labels.
% Please note, a symbol -(no ) in column 6 means no labels. The user may put the
% modular information of the nodes into column 4, like 1, 2, 3 or other information to
% be shown by color. Column 5 could be set as nodal degree, centrality, T-value, etc. to
% emphasize nodal differences by size. You can generate your nodal file according to the
% requirements.





