function [index_file, ranks] = ranking_analysis(context, trackers, sequences, experiments, varargin)

if length(trackers) < 2
	error('At least two trackers required for ranking analysis');
end

temporary_index_file = tempname;
template_file = fullfile(get_global_variable('toolkit_path'), 'templates', 'report.html');

labels = {};

ranks = nan(numel(experiments) * 3, numel(trackers));
scores = nan(numel(experiments) * 2, numel(trackers));
experiment_names = cellfun(@(x) x.name, experiments,'UniformOutput',false);
tacker_labels = cellfun(@(x) x.label, trackers, 'UniformOutput', 0);

index_fid = fopen(temporary_index_file, 'w');

combine_weight = 0.5 ;

latex_fid = [];
export_data = 0;

report_filename = sprintf('%sranking.html', context.prefix);

minimal_difference_acc = 0;
minimal_difference_fail = 0;
ar_plot = 0;
permutation_plot = 0;

permutation_args = {}; %'legend', 1, 'width' 4, 'height', 4};
ranking_permutation_args = {'flip', 1};

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'combineweight'
            combine_weight = varargin{i+1}; 
        case 'latexfile'
            latex_fid = varargin{i+1};
        case 'reporttemplate'
            template_file = varargin{i+1}; 
        case 'minimaldifferenceaccuracy'
            minimal_difference_acc = varargin{i+1} ;
        case 'minimaldifferencefailure'
            minimal_difference_fail = varargin{i+1} ;
        case 'arplot'
            ar_plot = varargin{i+1} ;
        case 'labels'
            labels = varargin{i+1} ;
        case 'permutationplot'
            permutation_plot = varargin{i+1} ;
        case 'exportdata'
            export_data = varargin{i+1} ;              
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

for e = 1:numel(experiments)

    experiment = experiments{e};

    print_text('Ranking analysis for experiment %s ...', experiment.name);

    print_indent(1);

    print_text('Loading data ...');

	if isempty(labels)

		[S_all, F_all, available] = ...
		    process_results_sequences(trackers, convert_sequences(sequences, experiment.converter), experiment.name);

		series_labels = cellfun(@(x) x.name, sequences, 'UniformOutput', 0);

	else

		[S_all, F_all, available] = ...
		    process_results_labels(trackers, convert_sequences(sequences, experiment.converter), ...
		    labels, experiment.name);

		series_labels = labels;

	end

    S_all = cellfun(@(x) x(available, :), S_all, 'UniformOutput', 0);
    F_all = cellfun(@(x) x(available, :), F_all, 'UniformOutput', 0);
    
    print_text('Processing ...');

    [accuracy, robustness] = ranking(S_all, F_all, 'alpha', 0.05, ...
        'minimal_difference_acc', minimal_difference_acc,...
        'minimal_difference_fail', minimal_difference_fail) ;
    
    if export_data
        
        save(fullfile(context.data, sprintf('%s_ranks.mat', experiment.name)), 'accuracy', 'robustness');
        
    end;          
    
    print_indent(-1);

    print_text('Writing report ...');

    report_file = generate_ranking_report(context, trackers(available), experiment, accuracy, robustness, ...
         'SeriesLabels', series_labels, 'combineWeight', combine_weight, 'reporttemplate', template_file, ...
         'arplot', ar_plot, 'permutationplot', 0); %permutation_plot);

    fprintf(index_fid, '<h2>Experiment %s</h2>\n', experiment.name);
           
    ranks(e * 3 - 2, available) = accuracy.average_ranks;
    ranks(e * 3 - 1, available) = robustness.average_ranks;
    ranks(e * 3, available) = accuracy.average_ranks * combine_weight + robustness.average_ranks * (1-combine_weight);
    
    scores(e * 2 - 1, available) = mean(accuracy.mu);
    scores(e * 2, available) = mean(robustness.mu);
    
    [~, order] = sort(ranks(e * 3, :), 'ascend');
    print_average_ranks(index_fid, ranks(e * 3, order), tacker_labels(order));
    
    fprintf(index_fid, '<a href="%s" class="more">More information</a>\n', report_file);

end;

ranks(isnan(ranks)) = size(ranks, 2);

fprintf(index_fid, '<h2>Averaged</h2>\n');
mean_ranks = mean(ranks(3:3:end, :), 1);
[~, order] = sort(mean_ranks,'ascend')  ;
print_average_ranks(index_fid, mean_ranks(order), tacker_labels(order));

if permutation_plot

    fprintf(index_fid, '<h2>Ranking permutations</h2>\n');    
            
    h = generate_permutation_plot(trackers, ranks(1:3:end, :), experiment_names, permutation_args{:}, ranking_permutation_args{:});

    insert_figure(context, index_fid, h, 'permutation_accuracy', 'Ranking permutations for accuracy rank');
    
    if export_data
        insert_figure(context, 0, h, 'permutation_accuracy', 'Ranking permutations for accuracy rank', 'format', 'data');
    end;    
    
    h = generate_permutation_plot(trackers, ranks(2:3:end, :), experiment_names, permutation_args{:}, ranking_permutation_args{:});

    insert_figure(context, index_fid, h, 'permutation_robustness', 'Ranking permutations for robustness rank');
            
    if export_data
        insert_figure(context, 0, h, 'permutation_robustness', 'Ranking permutations for robustness rank', 'format', 'data');
    end;      
%     
% %--   
%   
%     h = generate_permutation_plot(trackers, scores(1:2:end, :), experiment_names, permutation_args{:}, 'scope', [0, 1], 'type', 'Accuracy');
% 
%     insert_figure(context, index_fid, h, 'permutation_accuracy_raw', 'Scores permutations for accuracy rank');
%     
%     if export_data
%         insert_figure(context, 0, h, 'permutation_accuracy_raw', 'Scores permutations for accuracy rank', 'format', 'data');
%     end;    
%     
%     h = generate_permutation_plot(trackers, scores(2:2:end, :), experiment_names, permutation_args{:}, 'scope', [0, max(max(scores(2:2:end, :)))+1], 'type', 'Robustness');
% 
%     insert_figure(context, index_fid, h, 'permutation_robustness_raw', 'Scores permutations for robustness rank');
%             
%     if export_data
%         insert_figure(context, 0, h, 'permutation_robustness_raw', 'Scores permutations for robustness rank', 'format', 'data');
%     end; 
% 
% 
% %--
    
    h = generate_permutation_plot(trackers, ranks(3:3:end, :), experiment_names, permutation_args{:}, ranking_permutation_args{:}); 

    insert_figure(context, index_fid, h, 'permutation_combined', 'Ranking permutations for combined rank');
    
    if export_data
        insert_figure(context, 0, h, 'permutation_combined', 'Ranking permutations for combined rank', 'format', 'data');       
    end;      
    
end;


fclose(index_fid);

if ~isempty(latex_fid)

    ranks(end+1, :) = mean_ranks;
    
    ordered_ranks = ranks(:, order);

    fprintf(latex_fid, '\\begin{table}[h!]\\caption{Ranking results}\\label{tab:ranking}\n\\centering');

    ranking_labels = {'$R_A$', '$R_R$', '$R$'};

    prefix = [str2latex(sprintf([' & \\multicolumn{' num2str(length(ranking_labels)) '}{|c|}{ %s } '], experiment_names{:})), ' & '];
    
    column_labels = [ranking_labels(repmat(1:length(ranking_labels), 1, numel(experiments))),  {'$R_{\Sigma}$'}];
        
    celldata = num2cell(ordered_ranks');
    
    for i = 1:size(celldata, 2)
        scores = ordered_ranks(i, :);
        scores(isnan(scores)) = length(trackers);
        [~, indices] = sort(scores, 'ascend');
        
        celldata{indices(1), i} = sprintf('\\first{%.2f}', celldata{indices(1), i});
        celldata{indices(2), i} = sprintf('\\second{%.2f}', celldata{indices(2), i});
        celldata{indices(3), i} = sprintf('\\third{%.2f}', celldata{indices(3), i});
    end;
    
    matrix2latex(celldata, latex_fid, 'columnLabels', column_labels, 'rowLabels', strrep(tacker_labels(order), '_', '\_'), 'format', '%.2f', ...
            'prefix', prefix);

    fprintf(latex_fid, '\\end{table}\n');

end;

index_file = report_filename;

generate_from_template(fullfile(context.root, index_file), template_file, ...
    'body', fileread(temporary_index_file), 'title', 'Ranking report', ...
    'timestamp', datestr(now, 31));

delete(temporary_index_file);

function print_average_ranks(fid, ranks, tacker_labels )

    table = cellfun(@(x) sprintf('%1.3g', x), num2cell(ranks), 'UniformOutput', 0);

    fprintf(fid, '<div class="table">');
    
    matrix2html(table, fid, 'columnLabels', tacker_labels);

    fprintf(fid, '</div>');

