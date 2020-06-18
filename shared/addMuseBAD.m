function [MuseStruct] = addMuseBAD(MuseStruct, cfg.part_list, cfg.dir_list, cfg.markerStart, cfg.markerEnd, cfg.sample_list, cfg.time_from_begin, cfg.time_from_end)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [MuseStruct] = addMuseBAD(cfg, MuseStruct)
%
% Converts Muse marker timings into BAD timings.
% For example, convert seizures identified by 'Crise_Start' and 'Crise_End'
% markers into BAD__START__ and BAD__END__ markers, so those periods are
% then considered as artefacts, and can be ignored with the appropriate
% scripts (writeSpykingCircus.m,  removetrials_MuseMarkers.m)
%
% ## Mandatory input :
% MuseStruct        : structure with all the marker timings created by Muse
%                     (see readMuseMarkers.m)
% cfg.markerStart   : name of the Muse marker used to identify timings to
%                     convert into BAD__START__. Can be 'begin', in this
%                     case the BAD__START__ marker is put at the begining
%                     of the dir.
% cfg.markerEnd     : name of the Muse marker used to identify timings to
%                     convert into BAD__END__. The marker used is the next
%                     occurence of cfg.markerEnd after the selected cfg.markerStart.
%                     Can be 'end', in this case the BAD__END__ marker is
%                     put at the end of the dir.
%
% ## Optional cfg fields :
% cfg.part_list     : list of parts to analyse. Can be 'all', 'last', or any
%                     array of indexes. Default = 'all'.
% cfg.dir_list      : list of directories to analyse. Can be 'all', 'last',
%                     or any array of indexes (note that in this case, the
%                     input indexes must exist in all the 'parts' of
%                     MuseStruct). Default = 'all'.
% cfg.sample_list   : indication of the samples indexes of cfg.markerStart to
%                     use to add BAD markers. Can be 'all', 'last', or any
%                     array of indexes (note that in this  case, the samples
%                     indexes must exist in all the parts and dirs
%                     selected). Default = 'all'.
% cfg.time_from_begin : delay from cfg.markerStart where the new BAD__START__
%                     markers will be defined. In seconds, can be positive
%                     or negative. Default = 0.
% cfg.time_from_end : delay from cfg.markerEnd where the new BAD__END__
%                     markers will be defined. In seconds, can be positive
%                     or negative. Default = 0.
%
% ## OUTPUT :
% MuseStruct        : The input structure, with the requested BAD markers
%                     added.
%
% Notes :
% - if no cfg.markerEnd is found after cfg.markerStart, then the end of the
%   file is used to put the BAD__END__ marker
% - if markersStart = 'begin' and no cfg.markerEnd is found on all the file,
%   nothing is done
% - it is not possible for now to put at the same time cfg.markerStart =
%   'begin' and markeEnd = 'end'
% - all BAD markers are sorted in ascending order after all were added, to
%   avoid bug with Spyking-Circus
%
% Paul Baudin (paul.baudin@live.fr)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the default options
cfg.partlist                = ft_getopt(cfg, 'partlist', 'all');
cfg.dir_list                = ft_getopt(cfg, 'dir_list', 'all');
cfg.sample_list             = ft_getopt(cfg, 'sample_list', 'all');
cfg.time_from_begin         = ft_getopt(cfg, 'time_from_begin', 0);
cfg.time_from_end           = ft_getopt(cfg, 'time_from_end', 0);

if strcmp(cfg.markerStart, 'begin') && strcmp(cfg.markerEnd, 'end')
    error('It is not possible for now to put at the same time cfg.markerStart = ''begin'' and markeEnd = ''end''');
end

if strcmp(cfg.part_list, 'all')
    cfg.part_list = 1:length(MuseStruct);
elseif strcmp(cfg.part_list, 'last')
    cfg.part_list = length(MuseStruct);
end

for ipart = cfg.part_list
    
    if strcmp(cfg.dir_list, 'all')
        cfg.dir_list = 1:length(MuseStruct{ipart});
    elseif strcmp(cfg.dir_list, 'last')
        cfg.dir_list = length(MuseStruct{ipart});
    end
    
    for idir = cfg.dir_list
        
        %find start samples
        samples = [];
        if strcmp(cfg.sample_list, 'all') || strcmp(cfg.sample_list, 'last') %find all samples if required
            if isfield(MuseStruct{ipart}{idir}.markers, cfg.markerStart)
                if isfield(MuseStruct{ipart}{idir}.markers.(cfg.markerStart), 'clock')
                    switch cfg.sample_list
                        case 'all'
                            samples = 1:size(MuseStruct{ipart}{idir}.markers.(cfg.markerStart).clock,2);
                        case 'last'
                            samples = size(MuseStruct{ipart}{idir}.markers.(cfg.markerStart).clock,2);
                    end
                end
            end
        else
            samples = cfg.sample_list; %take input sample list if required
        end
        if strcmp(cfg.markerStart, 'begin'), samples = 1; end %if cfg.markerStart = begin, use sample = 1
        
        for isample = samples
            
            %find idx of cfg.markerEnd
            if strcmp(cfg.markerStart, 'begin')
                start = 0;
            else
                start   = round(MuseStruct{ipart}{idir}.markers.(cfg.markerStart).synctime(isample));
            end
            
            end_idx = [];
            if isfield(MuseStruct{ipart}{idir}.markers, cfg.markerEnd)
                if isfield(MuseStruct{ipart}{idir}.markers.(cfg.markerEnd), 'synctime')
                    end_idx = find(round(MuseStruct{ipart}{idir}.markers.(cfg.markerEnd).synctime) >= start,1,'first');
                end
            end
            
            if strcmp(cfg.markerStart, 'begin') && isempty(end_idx)
                warning('With cfg.markerStart = ''begin'', part %d dir %d : no cfg.markerEnd found, nothing is done', ipart, idir);
                continue
            end
            
            %Add BAD__START__ and BAD__End__ new timings
            
            %if there is BAD__START__ marker, add sample to the end of the fields
            if isfield(MuseStruct{ipart}{idir}.markers, 'BAD__START__')
                
                if strcmp(cfg.markerStart, 'begin')
                    MuseStruct{ipart}{idir}.markers.BAD__START__.clock(end+1)       = MuseStruct{ipart}{idir}.starttime;
                    MuseStruct{ipart}{idir}.markers.BAD__START__.synctime(end+1)    = 0;
                else
                    MuseStruct{ipart}{idir}.markers.BAD__START__.clock(end+1) = ...
                        MuseStruct{ipart}{idir}.markers.(cfg.markerStart).clock(isample)  +  seconds(cfg.time_from_begin);
                    
                    MuseStruct{ipart}{idir}.markers.BAD__START__.synctime(end+1) = ...
                        MuseStruct{ipart}{idir}.markers.(cfg.markerStart).synctime(isample)  +  cfg.time_from_begin;
                end
                
            else
                % if there are no BAD__START markers, create field
                MuseStruct{ipart}{idir}.markers.BAD__START__.clock = datetime.empty;
                MuseStruct{ipart}{idir}.markers.BAD__START__.synctime = [];
                
                if strcmp(cfg.markerStart, 'begin')
                    MuseStruct{ipart}{idir}.markers.BAD__START__.clock(1)       = MuseStruct{ipart}{idir}.starttime;
                    MuseStruct{ipart}{idir}.markers.BAD__START__.synctime(1)    = 0;
                else
                    MuseStruct{ipart}{idir}.markers.BAD__START__.clock(1) = ...
                        MuseStruct{ipart}{idir}.markers.(cfg.markerStart).clock(isample)  +  seconds(cfg.time_from_begin);
                    
                    MuseStruct{ipart}{idir}.markers.BAD__START__.synctime(1) = ...
                        MuseStruct{ipart}{idir}.markers.(cfg.markerStart).synctime(isample)  +  cfg.time_from_begin;
                end
            end
            
            %Bad end
            if isfield(MuseStruct{ipart}{idir}.markers, 'BAD__END__')
                
                if ~isempty(end_idx) && ~strcmp(cfg.markerEnd, 'end')
                    MuseStruct{ipart}{idir}.markers.BAD__END__.clock(end+1) = ...
                        MuseStruct{ipart}{idir}.markers.(cfg.markerEnd).clock(end_idx)  +  seconds(cfg.time_from_end);
                    
                    MuseStruct{ipart}{idir}.markers.BAD__END__.synctime(end+1) = ...
                        MuseStruct{ipart}{idir}.markers.(cfg.markerEnd).synctime(end_idx)  +  cfg.time_from_end;
                else % if no cfg.markerEnd event, or if cfg.markerEnd = 'end', put BAD__END__ at the end of the file
                    MuseStruct{ipart}{idir}.markers.BAD__END__.clock(end+1)     = ...
                        MuseStruct{ipart}{idir}.endtime;
                    MuseStruct{ipart}{idir}.markers.BAD__END__.synctime(end+1)  = ...
                        seconds(MuseStruct{ipart}{idir}.endtime - MuseStruct{ipart}{idir}.starttime);
                end
                
            else
                
                MuseStruct{ipart}{idir}.markers.BAD__END__.clock = datetime.empty;
                MuseStruct{ipart}{idir}.markers.BAD__END__.synctime = [];
                
                if ~isempty(end_idx)&& ~strcmp(cfg.markerEnd, 'end')
                    MuseStruct{ipart}{idir}.markers.BAD__END__.clock(1) = ...
                        MuseStruct{ipart}{idir}.markers.(cfg.markerEnd).clock(end_idx)  +  seconds(cfg.time_from_end);
                    
                    MuseStruct{ipart}{idir}.markers.BAD__END__.synctime(1) = ...
                        MuseStruct{ipart}{idir}.markers.(cfg.markerEnd).synctime(end_idx)  +  cfg.time_from_end;
                else % if no cfg.markerEnd event, or if cfg.markerEnd = 'end', put BAD__END__ at the end of the file
                    MuseStruct{ipart}{idir}.markers.BAD__END__.clock(1)     = ...
                        MuseStruct{ipart}{idir}.endtime;
                    MuseStruct{ipart}{idir}.markers.BAD__END__.synctime(1)  = ...
                        seconds(MuseStruct{ipart}{idir}.endtime - MuseStruct{ipart}{idir}.starttime);
                end
                
            end
        end%isample
    end %idir
end %ipart

%% sort BAD markers in ascending order to avoid bug in Spyking Circus (06.2020 : will be corrected in the next Spyking Circus release)
for ipart = 1:size(MuseStruct,2)
    for idir = 1:size(MuseStruct{ipart},2)
        
        if ~isfield(MuseStruct{ipart}{idir}.markers, 'BAD__START__')
            continue
        end
        
        if ~isfield(MuseStruct{ipart}{idir}.markers.BAD__START__, 'clock')
            continue
        end
        
        MuseStruct{ipart}{idir}.markers.BAD__START__.clock     = sort(MuseStruct{ipart}{idir}.markers.BAD__START__.clock);
        MuseStruct{ipart}{idir}.markers.BAD__START__.synctime  = sort(MuseStruct{ipart}{idir}.markers.BAD__START__.synctime);
        MuseStruct{ipart}{idir}.markers.BAD__END__.clock       = sort(MuseStruct{ipart}{idir}.markers.BAD__END__.clock);
        MuseStruct{ipart}{idir}.markers.BAD__END__.synctime    = sort(MuseStruct{ipart}{idir}.markers.BAD__END__.synctime);
        
    end
end

