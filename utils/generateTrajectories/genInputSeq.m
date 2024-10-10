function [probStr,savepath] = gen_trajectory
%% genInptSeq
% - set all relevant paths, global variables
% - specify what analysis steps should be executed when running "runAnalysis"
% - make directories and folderstructure for data if needed
%
%  SYNTAX:          runAnalysis
%
%  OUTPUT:
%
% Original: 23/2/2024; Nicholas Burton
% -------------------------------------------------------------------------
%
% Copyright (C) 2024 - need to fill in details
%
% This file is released under the terms of the GNU General Public Licence
% (GPL), version 3. You can redistribute it and/or modify it under the
% terms of the GPL (either version 3 or, at your option, any later version).
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details:
% <http://www.gnu.org/licenses/>
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
% _________________________________________________________________________
% =========================================================================


%CURRENTLY ONLY WORKS ONE AT A TIME


%% what steps to do?
genInputSeq.doTrainingTask_RL     = 0;
genInputSeq.doTrainingTask_LL     = 0;
genInputSeq.doTestTaskA           = 0;
genInputSeq.doTestTaskB           = 1;

%% TrainingTask1_RL - Create binary input sequence 
if genInputSeq.doTrainingTask_RL == 1;
    
    currTask = 'TrainingTask_RL';

    pPhase1  = 0.8; %A1  probability of "1" in curr phase
    lPhase1  = 140;  %A1 n trials of curr phase
    pPhase2  = 0.2; %A2
    lPhase2  = 140; %A2
    
    % Outcomes
    phase1  = ones(1,lPhase1);
    iIncIdx = randperm(lPhase1,floor((1-pPhase1)*lPhase1)); 
    phase1(1,iIncIdx) = 0;
    
    phase2  = ones(1,lPhase2);
    iIncIdx = randperm(lPhase2,floor((1-pPhase2)*lPhase2));
    phase2(1,iIncIdx) = 0;
    
    % Create input trajectory
    u = [phase1,phase2];
    probStr = [pPhase1*ones(1,lPhase1),pPhase2*ones(1,lPhase2)];
    
    %Create second row for left lever sequence
    k = zeros(1,length(u))
    for i = 1:length(k)
        if u(1,i) == 0
            k(1,i) = 1;
        end
    end
end

%% TrainingTask2_LL - Create binary input sequence for trainingTask
if genInputSeq.doTrainingTask_LL == 1

    currTask = 'TrainingTask_LL'

    pPhase1  = 0.2; %A1  probability of "1" in curr phase
    lPhase1  = 140;  %A1 n trials of curr phase
    pPhase2  = 0.8; %A2
    lPhase2  = 140; %A2
    
    % TrainingTask_ - Outcomes
    phase1  = ones(1,lPhase1);
    iIncIdx = randperm(lPhase1,floor((1-pPhase1)*lPhase1)); %floor rounds the number to prevent errors 
    phase1(1,iIncIdx) = 0;
    
    phase2  = ones(1,lPhase2);
    iIncIdx = randperm(lPhase2,floor((1-pPhase2)*lPhase2));
    phase2(1,iIncIdx) = 0;
    
    % TrainingTask - create input trajectory
    u = [phase1,phase2];
    % TrainingTask - underlying probability structure
    probStr = [pPhase1*ones(1,lPhase1),pPhase2*ones(1,lPhase2)];
    
    %Create second row for left lever sequence
    k = zeros(1,length(u))
    for i = 1:length(k)
        if u(1,i) == 0
            k(1,i) = 1;
        end
    end
end    

%% TestTaskA - Create test task binary input sequence 
if genInputSeq.doTestTaskA == 1

    currTask = 'TestTaskA';

    % 280 trials total,
    pPhase1  = 0.8; %A1  probability of "1" in curr phase
    lPhase1  = 40;  %A1 n trials of curr phase
    pPhase2  = 0.3; %B1
    lPhase2  = 20; %B1
    pPhase3  = 0.7; %B2
    lPhase3  = 20;%B2
    pPhase4  = 0.2; %A2
    lPhase4  = 40; %A2
    pPhase5  = 0.7; %B3
    lPhase5  = 20; %B3
    pPhase6  = 0.3; %B4
    lPhase6  = 20; %B4
    pPhase7  = 0.8; %A3
    lPhase7  = 40; %A3
    pPhase8  = 0.3; %B5
    lPhase8  = 20; %B5
    pPhase9  = 0.7; %B6
    lPhase9  = 20; %B6
    pPhase10 = 0.2; %A4 
    lPhase10 = 40; %A4
    
    % TestTask_1 outcomes
    phase1  = ones(1,lPhase1);
    iIncIdx = randperm(lPhase1,floor((1-pPhase1)*lPhase1)); %floor rounds the number to prevent errors 
    phase1(1,iIncIdx) = 0;
    
    phase2  = ones(1,lPhase2);
    iIncIdx = randperm(lPhase2,floor((1-pPhase2)*lPhase2));
    phase2(1,iIncIdx) = 0;
    
    phase3  = ones(1,lPhase3);
    iIncIdx = randperm(lPhase3,floor((1-pPhase3)*lPhase3));
    phase3(1,iIncIdx) = 0;
    
    phase4  = ones(1,lPhase4);
    iIncIdx = randperm(lPhase4,floor((1-pPhase4)*lPhase4));
    phase4(1,iIncIdx) = 0;
    
    phase5  = ones(1,lPhase5);
    iIncIdx = randperm(lPhase5,floor((1-pPhase5)*lPhase5));
    phase5(1,iIncIdx) = 0;
    
    phase6  = ones(1,lPhase6);
    iIncIdx = randperm(lPhase6,floor((1-pPhase6)*lPhase6));
    phase6(1,iIncIdx) = 0;
    
    phase7  = ones(1,lPhase7);
    iIncIdx = randperm(lPhase7,floor((1-pPhase7)*lPhase7));
    phase7(1,iIncIdx) = 0;
    
    phase8  = ones(1,lPhase8);
    iIncIdx = randperm(lPhase8,floor((1-pPhase8)*lPhase8));
    phase8(1,iIncIdx) = 0;
    
    phase9  = ones(1,lPhase9);
    iIncIdx = randperm(lPhase9,floor((1-pPhase9)*lPhase9));
    phase9(1,iIncIdx) = 0;
    
    phase10  = ones(1,lPhase10);
    iIncIdx = randperm(lPhase10,floor((1-pPhase10)*lPhase10));
    phase10(1,iIncIdx) = 0;
    
    
    % TestTask_1 create input trajectory
    u = [phase1,phase2,phase3,phase4,phase5,phase6,phase7,phase8,phase9,phase10];
    
    %TestTask_1 underlying probability structure
    probStr = [pPhase1*ones(1,lPhase1),pPhase2*ones(1,lPhase2),pPhase3*ones(1,lPhase3),pPhase4*ones(1,lPhase4),pPhase5*ones(1,lPhase5),...
         pPhase6*ones(1,lPhase6),pPhase7*ones(1,lPhase7),pPhase8*ones(1,lPhase8),pPhase9*ones(1,lPhase9),pPhase10*ones(1,lPhase10)];
            
    %Create second row for left lever sequence
    k = zeros(1,length(u))
    for i = 1:length(k)
        if u(1,i) == 0
            k(1,i) = 1;
        end
    end

end


%% TestTaskB_2 - setup phases 7_BABA Aphases are 40trials long
if genInputSeq.doTestTaskB == 1

    currTask = 'TestTaskB';

    pPhase1  = 0.3; %B1
    lPhase1  = 20; %B1
    pPhase2  = 0.7; %B2
    lPhase2  = 20;%B2
    pPhase3  = 0.2; %A2
    lPhase3  = 40; %A2
    pPhase4  = 0.7; %B3
    lPhase4  = 20; %B3
    pPhase5  = 0.3; %B4
    lPhase5  = 20; %B4
    pPhase6  = 0.8; %A3
    lPhase6  = 40; %A3
    pPhase7  = 0.3; %B5
    lPhase7  = 20; %B5
    pPhase8  = 0.7; %B6
    lPhase8  = 20; %B6
    pPhase9 = 0.2; %A4 
    lPhase9 = 40; %A4
    pPhase10  = 0.7; %B7
    lPhase10  = 20; %B7
    pPhase11  = 0.3; %B8
    lPhase11  = 20; %B8
    
    % TestTask_2 outcomes 
    phase1  = ones(1,lPhase1);
    iIncIdx = randperm(lPhase1,floor((1-pPhase1)*lPhase1)); %floor rounds the number to prevent errors 
    phase1(1,iIncIdx) = 0;
    
    phase2  = ones(1,lPhase2);
    iIncIdx = randperm(lPhase2,floor((1-pPhase2)*lPhase2));
    phase2(1,iIncIdx) = 0;
    
    phase3  = ones(1,lPhase3);
    iIncIdx = randperm(lPhase3,floor((1-pPhase3)*lPhase3));
    phase3(1,iIncIdx) = 0;
    
    phase4  = ones(1,lPhase4);
    iIncIdx = randperm(lPhase4,floor((1-pPhase4)*lPhase4));
    phase4(1,iIncIdx) = 0;
    
    phase5  = ones(1,lPhase5);
    iIncIdx = randperm(lPhase5,floor((1-pPhase5)*lPhase5));
    phase5(1,iIncIdx) = 0;
    
    phase6  = ones(1,lPhase6);
    iIncIdx = randperm(lPhase6,floor((1-pPhase6)*lPhase6));
    phase6(1,iIncIdx) = 0;
    
    phase7  = ones(1,lPhase7);
    iIncIdx = randperm(lPhase7,floor((1-pPhase7)*lPhase7));
    phase7(1,iIncIdx) = 0;
    
    phase8  = ones(1,lPhase8);
    iIncIdx = randperm(lPhase8,floor((1-pPhase8)*lPhase8));
    phase8(1,iIncIdx) = 0;
    
    phase9  = ones(1,lPhase9);
    iIncIdx = randperm(lPhase9,floor((1-pPhase9)*lPhase9));
    phase9(1,iIncIdx) = 0;
    
    phase10  = ones(1,lPhase10);
    iIncIdx = randperm(lPhase10,floor((1-pPhase10)*lPhase10));
    phase10(1,iIncIdx) = 0;
    
    phase11  = ones(1,lPhase11);
    iIncIdx = randperm(lPhase11,floor((1-pPhase11)*lPhase11));
    phase11(1,iIncIdx) = 0;
    
    % TestTask_2 - create input trajectory
    u = [phase1,phase2,phase3,phase4,phase5,phase6,phase7,phase8,phase9,phase10,phase11];
    %TeskTask_2 -  underlying probability structure
    probStr = [pPhase1*ones(1,lPhase1),pPhase2*ones(1,lPhase2),pPhase3*ones(1,lPhase3),pPhase4*ones(1,lPhase4),pPhase5*ones(1,lPhase5),...
         pPhase6*ones(1,lPhase6),pPhase7*ones(1,lPhase7),pPhase8*ones(1,lPhase8),pPhase9*ones(1,lPhase9),pPhase10*ones(1,lPhase10),...
         pPhase11*ones(1,lPhase11)];
    
    %Create second row for left lever sequence
    k = zeros(1,length(u))
    for i = 1:length(k)
        if u(1,i) == 0
            k(1,i) = 1;
        end
    end
end

%% PLOTTING
savePath = 'C:\Users\c3200098\Desktop\projects\IDMIM\utils\generateTrajectories\inputSequences';

figure;
fig = plot(u, '.', 'MarkerSize', 20); ylim([-0.1, 1.1]);
hold on;
stairs(probStr, '-.', 'Color', 'r', 'LineWidth', 2);
legend({'RewardingLeverSide', 'Prob(Reward)'});
title(currTask, 'FontWeight', 'bold', 'FontSize', 12);
figdir = fullfile([savePath,filesep, currTask, '_TrajPlot']);
save([figdir,'.fig'])
print([figdir,'.png'], '-dpng')

%Save binary input sequences as seperate .txt files for each lever
writematrix(u, [savePath,filesep, currTask, '_RightLeverList.txt'],"Delimiter",',')
writematrix(k, [savePath,filesep, currTask, '_LeftLeverList.txt'],"Delimiter",',')