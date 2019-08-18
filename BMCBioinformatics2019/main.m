%"""
%Main file to the Toy Analysis Workflow (TAW)
%"""

% Clean environment
clc; clear; close all force;
restoredefaultpath();

% Load Biotracs and Biotracs-Atlas packages
% The package directory is the location of "biotracs-m" and
% "biotracs-m-atlas" libraries
pkgDir = fullfile(pwd, '../../../Dev'); 
addpath('../../')
autoload( ...
    'PkgPaths', { pkgDir }, ...
    'Dependencies', {...
    'biotracs-m-atlas', ...
    }, ...
    'Variables',  struct(...
    ) ...
    );

% Set deterministic simulation
s1 = RandStream.create('mrg32k3a','Seed', 0);
s0 = RandStream.setGlobalStream(s1);

% Working directory
wdir = fullfile( biotracs.core.env.Env.workingDir, 'Taw' );

dataType = 'metabo'; %'iris', 'wdbc' or 'metabo'

if strcmp(dataType, 'iris')
    % --- Fisher's Iris flower dataset
    % Load and prepare Fisher's Iris flower dataset
    % See: https://en.wikipedia.org/wiki/Iris_flower_data_set
    % The data set consists of 50 samples from each of three species of Iris
    % (Iris setosa, Iris virginica and Iris versicolor).
    % Four features were measured from each sample: the length and the width of
    % the sepals and petals, in centimeters.    
    wdir = fullfile( wdir, 'iris' );
    load fisheriris;
    species = strcat('Group:', species);
    dataSet = biotracs.data.model.DataSet( meas, {'SepalLength', 'SepalWidth', 'PetalLength', 'PetalWidth'}, species );
    dataFilePath = fullfile(wdir, 'dataset.csv');
    dataSet.setRowNamePatterns({'Group'});
    dataXYSet = dataSet.createXYDataSet();  % create dummy boolean outputs to caracterize each species
    dataXYSet.export( dataFilePath );       % export prepared data
elseif strcmp(dataType, 'wdbc')
    % --- Diabete dataset
    % Breast Cancer Wisconsin data
    % Source: http://networkrepository.com/breast-cancer-wisconsin-wdbc.php
    % Ryan A. Rossi and Nesreen K. Ahmed, 2015, The Network Data Repository
    % with Interactive Graph Analytics and Visualization    
    wdir = fullfile( wdir, 'wdbc' );
    dataSet = biotracs.data.model.DataSet.import('./data/wdbc.txt');
    dataSet.setRowNames( strcat('Group:',dataSet.rowNames) );
    dataFilePath = fullfile(wdir, 'dataset.csv');
    dataSet.setRowNamePatterns({'Group'});
    dataXYSet = dataSet.createXYDataSet();  % create dummy boolean outputs to caracterize each species
    dataXYSet.export( dataFilePath );       % export prepared data
else
    % --- Metabolite dataset
    % Metabo dataset
    wdir = fullfile( wdir, 'metabo' );
    dataSet = biotracs.data.model.DataSet.import('./data/metabo.xlsx');
    dataSet.setRowNames( strcat('Group:',dataSet.rowNames) );
    dataFilePath = fullfile(wdir, 'dataset.csv');
    dataSet.setRowNamePatterns({'Group'});
    dataXYSet = dataSet.createXYDataSet();  % create dummy boolean outputs to caracterize each species
    dataXYSet.export( dataFilePath );       % export prepared data
end

%% --- Workflow
% Initialize workflow
taw = Taw();
taw.getConfig()...
    .updateParamValue('WorkingDirectory', wdir);
taw.getNode('DataImporter')...
    .addInputFilePath(dataFilePath);

% Configure workflow
% Use of writeParamValues() accessor
taw.writeParamValues(...
    'PcaLearner:NbComponents', 10, ...
    'PcaLearnerViewExporter:ViewNames', {'ScorePlot','ScorePlot'}, ...
    'PcaLearnerViewExporter:ViewLabels', {'2DPlot','3DPlot'}, ...
    'PcaLearnerViewExporter:ViewParameters', {...
        {'NbComponents', 2, 'GroupList', {'Group'}, 'LabelFormat', {'Group:([^_]*)'}},...
        {'NbComponents', 3, 'GroupList', {'Group'}, 'LabelFormat', {'Group:([^_]*)'}}...
    }, ...
    ...
    'PlsLearner:NbComponents', 10, ...
    'PlsLearner:kFoldCrossValidation', Inf, ...
    'PlsLearnerViewExporter:ViewNames', {'ScorePlot','ScorePlot'}, ...
    'PlsLearnerViewExporter:ViewLabels', {'2DPlot','3DPlot'}, ...
    'PlsLearnerViewExporter:ViewParameters', {...
        {'NbComponents', 2, 'GroupList', {'Group'}, 'LabelFormat', {'Group:([^_]*)'}},...
        {'NbComponents', 3, 'GroupList', {'Group'}, 'LabelFormat', {'Group:([^_]*)'}}...
    }, ...
    'PlsPredictor:ReplicatePatterns', {'Group'}, ...
    'PlsPredictorViewExporter:ViewNames', {'YPredictionPlot', 'YPredictionScoreHeatMap', 'YPredictionScoreHeatMap'}, ...
    'PlsPredictorViewExporter:ViewLabels', {'YPredictionPlot', 'YPredictionScoreHeatMap', 'YPredictionScoreAverageHeatMap'}, ...
    'PlsPredictorViewExporter:ViewParameters', {...
        {'GroupList', {'Group'}, 'LabelFormat', {'Group:([^_]*)'}}, ...
        {'LabelFormat', {'Group:([^_]*)'}}, ...
        {'LabelFormat', {'Group:([^_]*)'}, 'ShowAverage', true} ...
    }, ...
    ...
    'PlsLearnerResultExporter:NameFilter', 'CrossValidationVariableRanking|(^RegCoef$)|VarExplained|Scores|ClassSeparator|Stats', ...
    ...
    'DiffProcess:GroupPatterns', {'Group'}, ...
    'DiffProcess:PValueThreshold', 0.05, ...
    'DiffProcess:FoldChangeThreshold', 1, ...
    'DiffProcessViewExporter:ViewNames', {'VolcanoPlot', 'VolcanoPlot'}, ...
    'DiffProcessViewExporter:ViewLabels', {'fc=1', 'fc=1.5'}, ...
    'DiffProcessViewExporter:ViewParameters', {...
        {'PValueThreshold', 0.05, 'FoldChangeThreshold', 1, 'LabelFormat', 'none'},...
        {'PValueThreshold', 0.05, 'FoldChangeThreshold', 1.5, 'LabelFormat', 'none'}...
    }, ...
    ...
    'PartialDiffProcess:NbComponents', 3, ...
    'PartialDiffProcess:PValue', 0.05, ...
    'PartialDiffProcess:GroupPatterns', {'Group'} ...
    ...
);

% Run the workflow
taw.run();

% Restore random generator seed
RandStream.setGlobalStream(s0);