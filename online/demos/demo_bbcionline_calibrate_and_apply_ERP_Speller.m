BC= [];
BC.fcn= @bbci_calibrate_ERPSpeller;
BC.settings.nClasses= 6;
BC.file= 'VPibq_11_05_18/calibration_CenterSpellerFixedSequenceVPibq';
BC.read_param= {'fs',100};
BC.marker_fcn= @mrk_defineClasses;
BC.marker_param= {{[31:49], [11:29]; 'target', 'nontarget'}};

% In demos, we just write to the temp folder. Otherwise, the default
% choice would be fine.
BC.save.folder= BBCI.TmpDir;
BC.log.folder= BBCI.TmpDir;

bbci= struct('calibrate', BC);

[bbci, calib]= bbci_calibrate(bbci);
%bbci_save(bbci, calib);


% test consistency of classifier outputs in simulated online mode
bbci.source.acquire_fcn= @bbci_acquire_offline;
bbci.source.acquire_param= {calib.cnt, calib.mrk};

bbci.log.output= 'screen&file';
bbci.log.folder= BBCI.TmpDir;
bbci.log.classifier= 1;

data= bbci_apply_uni(bbci);

log_format= '%fs | M(%u) | %fs | [%f] | %s';
[time, marker_desc, marker_time, cfy, control]= ...
    textread(data.log.filename, log_format, ...
             'delimiter','','commentstyle','shell');

isequal(marker_desc, calib.mrk.desc')

ref_ival= bbci.feature.proc{1}{2};
cfy_ival= bbci.feature.proc{2}{2};
epo= proc_segmentation(calib.cnt, calib.mrk, bbci.feature.ival, ...
                       'clab', bbci.signal.clab);
fv= proc_baseline(epo, ref_ival);
fv= proc_jumpingMeans(fv, cfy_ival);
out= applyClassifier(fv, 'LDA', bbci.classifier.C);

% validate classifier outputs of simulated online and offline processing
max(out(:)- cfy)