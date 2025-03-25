function optionsFile = setup_configFiles(optionsFile,cohortNo)

%    IN: cohortNo:  integer, cohort number, see optionsFile for what cohort
%                            corresponds to what number in the
%                            optionsFile.cohort(cohortNo).name struct. This
%                            allows to run the pipeline and its functions for different
%                            cohorts whose expcifications have been set in runOptions.m

%% SETUP config files for Perceptual models
if optionsFile.setupModels == 1

    modelSpace = struct();
    for iTask = 1:numel(optionsFile.cohort(cohortNo).testTask)
        for iModel = 1:numel(optionsFile.model.space)
            modelSpace(iModel,iTask).prc           = optionsFile.model.prc{iModel};
            modelSpace(iModel,iTask).prc_config    = eval(optionsFile.model.prc_config{iModel});
            pr = priorPrep(optionsFile.cohort(cohortNo).testTask(iTask).inputs);

            % Replace placeholders in parameter vectors with their calculated values
            modelSpace(iModel,iTask).prc_config.priormus(modelSpace(iModel,iTask).prc_config.priormus==99991)  = pr.plh.p99991;
            modelSpace(iModel,iTask).prc_config.priorsas(modelSpace(iModel,iTask).prc_config.priorsas==99991)  = pr.plh.p99991;

            modelSpace(iModel,iTask).prc_config.priormus(modelSpace(iModel,iTask).prc_config.priormus==99992)  = pr.plh.p99992;
            modelSpace(iModel,iTask).prc_config.priorsas(modelSpace(iModel,iTask).prc_config.priorsas==99992)  = pr.plh.p99992;

            modelSpace(iModel,iTask).prc_config.priormus(modelSpace(iModel,iTask).prc_config.priormus==99993)  = pr.plh.p99993;
            modelSpace(iModel,iTask).prc_config.priorsas(modelSpace(iModel,iTask).prc_config.priorsas==99993)  = pr.plh.p99993;

            modelSpace(iModel,iTask).prc_config.priormus(modelSpace(iModel,iTask).prc_config.priormus==-99993) = -pr.plh.p99993;
            modelSpace(iModel,iTask).prc_config.priorsas(modelSpace(iModel,iTask).prc_config.priorsas==-99993) = -pr.plh.p99993;

            modelSpace(iModel,iTask).prc_config.priormus(modelSpace(iModel,iTask).prc_config.priormus==99994)  = pr.plh.p99994;
            modelSpace(iModel,iTask).prc_config.priorsas(modelSpace(iModel,iTask).prc_config.priorsas==99994)  = pr.plh.p99994;

            % Get fieldnames. If a name ends on 'mu', that field defines a prior mean.
            % If it ends on 'sa', it defines a prior variance.
            names  = fieldnames(modelSpace(iModel,iTask).prc_config);
            fields = struct2cell(modelSpace(iModel,iTask).prc_config);

            % Loop over names
            for n = 1:length(names)
                if regexp(names{n}, 'mu$')
                    priormus = [];
                    priormus = [priormus, modelSpace(iModel,iTask).prc_config.(names{n})];
                    priormus(priormus==99991)  = pr.plh.p99991;
                    priormus(priormus==99992)  = pr.plh.p99992;
                    priormus(priormus==99993)  = pr.plh.p99993;
                    priormus(priormus==-99993) = -pr.plh.p99993;
                    priormus(priormus==99994)  = pr.plh.p99994;
                    modelSpace(iModel,iTask).prc_config.(names{n}) = priormus;
                    clear priormus;

                elseif regexp(names{n}, 'sa$')
                    priorsas = [];
                    priorsas = [priorsas, modelSpace(iModel,iTask).prc_config.(names{n})];
                    priorsas(priorsas==99991)  = pr.plh.p99991;
                    priorsas(priorsas==99992)  = pr.plh.p99992;
                    priorsas(priorsas==99993)  = pr.plh.p99993;
                    priorsas(priorsas==-99993) = -pr.plh.p99993;
                    priorsas(priorsas==99994)  = pr.plh.p99994;
                    modelSpace(iModel,iTask).prc_config.(names{n}) = priorsas;
                    clear priorsas;
                end
            end

            % find parameter names of mus and sas:
            expnms_mu_prc=[];
            expnms_sa_prc=[];
            n_idx      = 0;
            for k = 1:length(names)
                if regexp(names{k}, 'mu$')
                    for l= 1:length(fields{k})
                        n_idx = n_idx + 1;
                        expnms_mu_prc{1,n_idx} = [names{k},'_',num2str(l)];
                    end
                elseif regexp(names{k}, 'sa$')
                    for l= 1:length(fields{k})
                        n_idx = n_idx + 1;
                        expnms_sa_prc{1,n_idx} = [names{k},'_',num2str(l)];
                    end
                end
            end
            modelSpace(iModel,iTask).expnms_mu_prc=expnms_mu_prc(~cellfun('isempty',expnms_mu_prc));
            modelSpace(iModel,iTask).expnms_sa_prc=expnms_sa_prc(~cellfun('isempty',expnms_sa_prc));
        end
    end
    % SETUP config files for Observational models
    for iModel = 1:numel(optionsFile.model.space)
        modelSpace(iModel).name       = optionsFile.model.space{iModel};
        modelSpace(iModel).obs        = optionsFile.model.obs{1};
        modelSpace(iModel).obs_config = eval(optionsFile.model.obs_config{1});

        % Get fieldnames. If a name ends on 'mu', that field defines a prior mean.
        % If it ends on 'sa', it defines a prior variance.
        names  = fieldnames(modelSpace(iModel).obs_config);
        fields = struct2cell(modelSpace(iModel).obs_config);
        % find parameter names of mus and sas:
        expnms_mu_obs=[];
        expnms_sa_obs=[];
        n_idx      = 0;
        for k = 1:length(names)
            if regexp(names{k}, 'mu$')
                for l= 1:length(fields{k})
                    n_idx = n_idx + 1;
                    expnms_mu_obs{1,n_idx} = [names{k},'_',num2str(l)];
                end
            elseif regexp(names{k}, 'sa$')
                for l= 1:length(fields{k})
                    n_idx = n_idx + 1;
                    expnms_sa_obs{1,n_idx} = [names{k},'_',num2str(l)];
                end
            end
        end
        modelSpace(iModel).expnms_mu_obs=expnms_mu_obs(~cellfun('isempty',expnms_mu_obs));
        modelSpace(iModel).expnms_sa_obs=expnms_sa_obs(~cellfun('isempty',expnms_sa_obs));
    end
    % Find free parameters & convert parameters to native space
    for iModel = 1:numel(optionsFile.model.space)

        % Perceptual model
        prc_idx = modelSpace(iModel).prc_config.priorsas;
        prc_idx(isnan(prc_idx)) = 0;
        modelSpace(iModel).prc_idx = find(prc_idx);
        % find names of free parameters:
        modelSpace(iModel).free_expnms_mu_prc=modelSpace(iModel).expnms_mu_prc(modelSpace(iModel).prc_idx);
        modelSpace(iModel).free_expnms_sa_prc=modelSpace(iModel).expnms_sa_prc(modelSpace(iModel).prc_idx);
        c.c_prc = (modelSpace(iModel).prc_config);
        % transform values into natural space for the simulations
        modelSpace(iModel).prc_mus_vect_nat = c.c_prc.transp_prc_fun(c, c.c_prc.priormus);
        modelSpace(iModel).prc_sas_vect_nat = c.c_prc.transp_prc_fun(c, c.c_prc.priorsas);

        % Observational model
        obs_idx = modelSpace(iModel).obs_config.priorsas;
        obs_idx(isnan(obs_idx)) = 0;
        modelSpace(iModel).obs_idx = find(obs_idx);
        % find names of free parameters:
        modelSpace(iModel).free_expnms_mu_obs=modelSpace(iModel).expnms_mu_obs(modelSpace(iModel).obs_idx);
        modelSpace(iModel).free_expnms_sa_obs=modelSpace(iModel).expnms_sa_obs(modelSpace(iModel).obs_idx);
        c.c_obs = (modelSpace(iModel).obs_config);
        % transform values into natural space for the simulations
        modelSpace(iModel).obs_vect_nat = c.c_obs.transp_obs_fun(c, c.c_obs.priormus);
    end

    optionsFile.modelSpace = modelSpace;

    % colors for plotting
    optionsFile.col.wh   = [1 1 1];
    optionsFile.col.gry  = [0.5 0.5 0.5];
    optionsFile.col.tnub = [186 85 211]/255;  %186,85,211 purple %blue 0 110 182
    optionsFile.col.tnuy = [255 166 22]/255;
    optionsFile.col.grn  = [0 0.6 0];

    optionsFile.doOptions = 0;

end

%% NOTE: THIS IS A COPY from hgf function tapas_fitModel:
% --------------------------------------------------------------------------------------------------
    function pr = priorPrep(options)

        % Initialize data structure to be returned
        pr = struct;

        % Store responses and inputs
        pr.u  = options;

        % Calculate placeholder values for configuration files

        % First input
        % Usually a good choice for the prior mean of mu_1
        pr.plh.p99991 = pr.u(1,1);

        % Variance of first 20 inputs
        % Usually a good choice for the prior variance of mu_1
        if length(pr.u(:,1)) > 20
            pr.plh.p99992 = var(pr.u(1:20,1),1);
        else
            pr.plh.p99992 = var(pr.u(:,1),1);
        end

        % Log-variance of first 20 inputs
        % Usually a good choice for the prior means of log(sa_1) and alpha
        if length(pr.u(:,1)) > 20
            pr.plh.p99993 = log(var(pr.u(1:20,1),1));
        else
            pr.plh.p99993 = log(var(pr.u(:,1),1));
        end

        % Log-variance of first 20 inputs minus two
        % Usually a good choice for the prior mean of omega_1
        if length(pr.u(:,1)) > 20
            pr.plh.p99994 = log(var(pr.u(1:20,1),1))-2;
        else
            pr.plh.p99994 = log(var(pr.u(:,1),1))-2;
        end

    end % function priorPrep
% --------------------------------------------------------------------------------------------------

%% SAVE options file
save([optionsFile.paths.projDir,'optionsFile.mat'],'optionsFile');

end