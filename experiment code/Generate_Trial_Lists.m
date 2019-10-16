% Trial list generation script for the "Duration Gamma fMRI" Experiment

%% Initialize

% Experiment parameters
stimulus_types = {'face','house'};
stimulus_durations_sec = [9 15];
stimulus_soa_sec = 34.5;
trials_per_cond = 20;
num_face_images = 80;
num_house_images = 50;
num_blocks = 8;
num_practice_trials = 2;
% targets_per_cond = 5;

% Stimulus codes - these are cumulative, e.g. short/house/non-target = 1+20+0
duration_codes = [1 2];
type_codes = [10 20];
target_code = 100;

%% Generate trial list
nDur = length(stimulus_durations_sec);
nTyp = length(stimulus_types);
nSoa = length(stimulus_soa_sec);
nTrials = nDur*nTyp*(trials_per_cond);

% Create all condition combinations
duration = zeros(nTrials,1);
type = cell(nTrials,1);
target_latency = zeros(nTrials,1);
onset_code = zeros(nTrials,1);
soa = zeros(nTrials,1);
image_index = zeros(nTrials,1);

n = 0;
nf = 0;
nh = 0;
for i=1:nDur
    for k=1:nTyp
        for l = 1:(trials_per_cond) 
            % for each condition combination, repeat to get the number
            % of target and non-target trials we want
            n = n + 1;
            target_latency(n) = 0;
%             if l <= targets_per_cond % if this is one of the target trials
%                 target(n) = 1;
%             else
%                 target(n) = 0;
%             end
            duration(n) = stimulus_durations_sec(i);
            type{n} = stimulus_types{k};
            onset_code(n) = duration_codes(i) + type_codes(k);
            soa(n) = stimulus_soa_sec(mod(n-1,nSoa)+1);
            if strcmp(stimulus_types{k},'face')
                nf = nf + 1;
                image_index(n) = mod(nf-1,num_face_images)+1;
            else
                nh = nh + 1;
                image_index(n) = mod(nh-1,num_house_images)+1;
            end
        end
    end
end

% Put all of these lists into a single table
trial_codes = table(onset_code,duration,type,target_latency,image_index,soa);

% Randomize trials
trial_codes = trial_codes(randperm(nTrials),:);
% Randomize ISIs again just to make sure there are no dependencies between condition and ISI
trial_codes.soa = trial_codes.soa(randperm(nTrials));

% Divide into blocks
block_codes = cell(num_blocks,1);
trials_per_block = nTrials / num_blocks;
all_trial_codes = trial_codes;
% This loop divides trials into blocks even if they can't be divided
% equally:
n = 0;
for b=1:num_blocks
    block_codes{b} = trial_codes(floor(n+1):floor(n+trials_per_block),:);
    n = n + trials_per_block;
end

% Add target trials
block_codes{1}([4],:).target_latency = block_codes{1}([4],:).duration + [4];
block_codes{2}([1 3 5],:).target_latency = block_codes{2}([1 3 5],:).duration + [10;8;6];
block_codes{3}([1 9],:).target_latency = block_codes{3}([1 9],:).duration + [2;10];
block_codes{4}([8 10],:).target_latency = block_codes{4}([8 10],:).duration + [8;4];
block_codes{5}([6 8],:).target_latency = block_codes{5}([6 8],:).duration + [4;12];
block_codes{6}([2 4],:).target_latency = block_codes{6}([2 4],:).duration + [6;2];
block_codes{7}([2 4],:).target_latency = block_codes{7}([2 4],:).duration + [6;2];
block_codes{8}([3 6],:).target_latency = block_codes{8}([3 6],:).duration + [6;4];

idx = find(block_codes{1}.duration == stimulus_durations_sec(2) & block_codes{1}.target_latency == 0);
block_codes{1}(idx(3),:).target_latency = 12;
idx = find(block_codes{3}.duration == stimulus_durations_sec(1) & block_codes{3}.target_latency == 0);
block_codes{3}(idx(2),:).target_latency = 6;
idx = find(block_codes{4}.duration == stimulus_durations_sec(2) & block_codes{4}.target_latency == 0);
block_codes{4}(idx(3),:).target_latency = 10;
idx = find(block_codes{7}.duration == stimulus_durations_sec(2) & block_codes{7}.target_latency == 0);
block_codes{7}(idx(1),:).target_latency = 8;

%% Generate practice block
% Sample a random group of trials - repeat until we like what we get
practice_codes = trial_codes(randperm(nTrials,num_practice_trials),:);
practice_codes(1,:).target_latency = 22;
practice_codes(2,:).target_latency = 8;
disp(practice_codes);

%% Save
save('exp_codes','block_codes','practice_codes');
