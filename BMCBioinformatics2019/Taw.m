%"""
%Toy Analysis Workflow (TAW)
%Taw was designed to illustrate how BioTracs works. A more complete
%analysis workflow exists in the BioTracs-Atlas application
%* License: BIOASTER License - 07/08/2019
%* Created by: Bioinformatics team, Omics Hub, BIOASTER Technology Research Institute (http://www.bioaster.org), 2017
%* See: biotracs.core.mvc.model.Workflow, biotracs.atlas.model.GenericMLWorkflow
%"""

classdef Taw < biotracs.core.mvc.model.Workflow
    
    properties(SetAccess = protected)
    end
    
    methods
        
        % Constructor
        function this = Taw( )
            this@biotracs.core.mvc.model.Workflow();
            this.doBuildWorkflow();
        end
       
    end
    
    methods(Access = protected)
        
        function this =  doBuildWorkflow( this )
            [ dataSetImporter ]                             = this.doAddDataFileImporter( 'DataImporter' );
            [ dataSetParser, dataSetParserDemux ]           = this.doAddDataParser( 'DataParser' );
            [ dataFilter ]                                  = this.doAddDataFilter( 'DataFilter' );         

            % full pca, pls
            [ pcaLearner, pcaViewExporter ]                 = this.doAddPcaLearner( 'PcaLearner' );
            
            [ plsLearner, plsViewExporter ]                 = this.doAddPlsLearner( 'PlsLearner' );
            [ plsLearnerResultExporter ]                    = this.doAddDataFileExporter( 'PlsLearnerResultExporter' );
            
            [ plsPredictor, plsPredictorViewExporter ]      = this.doAddPlsPredictor( 'PlsPredictor' );
            [ plsPredictorResultExporter ]                  = this.doAddDataFileExporter( 'PlsPredictorResultExporter' );
            
            
            % differential analysis
            [ diff, diffViewExporter, ]                     = this.doAddDiffProcess();
            [ diffTableExporter ]                           = this.doAddDataFileExporter( 'DiffTableExporter' );

            % partial differential analysis
            [ pdiff ]                                       = this.doAddPartialDiffProcess();
            [ pdiffMatrixExporter ]                         = this.doAddDataFileExporter( 'PartialDiffMatrixExporter' );
            

            % Connect i/o ports
            %--------------------------------------------------------------
            
            %-> import data set
            dataSetImporter.getOutputPort('DataFileSet')	.connectTo( dataSetParser.getInputPort('DataFile') );
            dataSetParser.getOutputPort('ResourceSet')      .connectTo( dataSetParserDemux.getInputPort('ResourceSet') );                 
            dataSetParserDemux.getOutputPort('Resource')	.connectTo( dataFilter.getInputPort('DataMatrix') );          

            %-> full pca
            dataFilter.getOutputPort('DataMatrix')          .connectTo( pcaLearner.getInputPort('TrainingSet') ); 
            pcaLearner.getOutputPort('Result')              .connectTo( pcaViewExporter.getInputPort('Resource') );
            
            %-> full pls
            dataFilter.getOutputPort('DataMatrix')          .connectTo( plsLearner.getInputPort('TrainingSet') );
            plsLearner.getOutputPort('Result')              .connectTo( plsViewExporter.getInputPort('Resource') );
            plsLearner.getOutputPort('Result')              .connectTo( plsLearnerResultExporter.getInputPort('Resource') );
            
            %-> pls prediction
            dataFilter.getOutputPort('DataMatrix')          .connectTo( plsPredictor.getInputPort('TestSet') );
            plsLearner.getOutputPort('Result')              .connectTo( plsPredictor.getInputPort('PredictiveModel') );
            plsPredictor.getOutputPort('Result')            .connectTo( plsPredictorViewExporter.getInputPort('Resource') );
            plsPredictor.getOutputPort('Result')            .connectTo( plsPredictorResultExporter.getInputPort('Resource') );
            
            %Differential & Partial differential analysis
            %--------------------------------------------------------------
            
            %-> diff
            dataFilter.getOutputPort('DataMatrix')          .connectTo( diff.getInputPort('DataSet') );
            diff.getOutputPort('Result')                    .connectTo( diffViewExporter.getInputPort('Resource') );
            diff.getOutputPort('Result')                    .connectTo( diffTableExporter.getInputPort('Resource') );

            %-> pdiff
            plsLearner.getOutputPort('Result')              .connectTo( pdiff.getInputPort('LearningResult') );
            pdiff.getOutputPort('Result')                   .connectTo( pdiffMatrixExporter.getInputPort('Resource') );
        end

        function [ dataFileImporter ] = doAddDataFileImporter( this, iName )
            dataFileImporter = biotracs.core.adapter.model.FileImporter();
            dataFileImporter.getConfig()...
                .updateParamValue('FileExtensionFilter', '.xlsx,.csv,.mat');
            this.addNode( dataFileImporter, iName );
        end

        function [ dataFilter ] = doAddDataFilter( this, iName )
            dataFilter = biotracs.dataproc.model.DataFilter();
            dataFilter.getConfig()...
                .updateParamValue('MinStandardDeviation', 1e-9);
            this.addNode( dataFilter, iName );
        end
        
        function [ dataSetParser, dataSetParserDemux ] = doAddDataParser( this, iName )
            dataSetParser = biotracs.parser.model.TableParser();
            dataSetParser.getConfig()...
                .updateParamValue('TableClass', 'biotracs.data.model.DataSet');
            dataSetParserDemux = biotracs.core.adapter.model.Demux();
            dataSetParserDemux.resizeOutput(1);
            this.addNode(dataSetParser, iName);
        end

        function [ fileExporter ] = doAddDataFileExporter( this, iName, iExt )
            if nargin == 2
                iExt = '.csv';
            end
            fileExporter = biotracs.core.adapter.model.FileExporter();
            fileExporter.getConfig()...
                .updateParamValue('FileExtension', iExt);
            this.addNode( fileExporter, iName );
        end
        
        function [ pcaLearner, pcaViewExporter ] = doAddPcaLearner( this, iName )
            pcaLearner = biotracs.atlas.model.PCALearner();
            this.addNode(pcaLearner, iName);
            pcaViewExporter = biotracs.core.adapter.model.ViewExporter();
            this.addNode(pcaViewExporter, [iName,'ViewExporter']);
        end
        
        function [ plsLearner, plsViewExporter ] = doAddPlsLearner( this, iName )
            plsLearner = biotracs.atlas.model.PLSLearner();
            this.addNode(plsLearner, iName);
            plsViewExporter = biotracs.core.adapter.model.ViewExporter();
            this.addNode(plsViewExporter, [iName,'ViewExporter']);
        end
        
        function [ plsPredictor, plsViewExporter ] = doAddPlsPredictor( this, iName )
            plsPredictor = biotracs.atlas.model.PLSPredictor();
            this.addNode(plsPredictor, iName);
            plsViewExporter = biotracs.core.adapter.model.ViewExporter();
            this.addNode(plsViewExporter, [iName,'ViewExporter']);
        end
        
        function [ diffProcess, diffViewExporter, diffDemux ] = doAddDiffProcess( this )
            diffProcess = biotracs.atlas.model.DiffProcess();
            this.addNode(diffProcess, 'DiffProcess');
            diffViewExporter = biotracs.core.adapter.model.ViewExporter();
            this.addNode(diffViewExporter, 'DiffProcessViewExporter');
            
            diffDemux = biotracs.core.adapter.model.Demux();
            diffDemux.resizeOutputWith( diffProcess.getOutputPortData('Result') );
            this.addNode(diffDemux, 'DiffProcessDemux');
        end
        
        function [ pdiffProcess, pdiffViewExporter ] = doAddPartialDiffProcess( this )
            pdiffProcess = biotracs.atlas.model.PartialDiffProcess();
            this.addNode(pdiffProcess, 'PartialDiffProcess');
            pdiffViewExporter = biotracs.core.adapter.model.ViewExporter();
            this.addNode(pdiffViewExporter, 'PartialDiffProcessViewExporter');
        end

    end
    
end