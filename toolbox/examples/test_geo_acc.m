isInstalled = exist('scgeatool.m','file') == 2;
if ~isInstalled
    msg = sprintf(['The third‑party toolbox "%s" is not detected on your ' ...
        'MATLAB path. Make sure the folder is added (e.g. using Add‑On ' ...
        'Manager or addpath). Continue without it?'], 'scGEAToolbox');
    choice = questdlg(msg, 'Missing Toolbox', 'Yes', 'No', 'No');
    if strcmp(choice, 'No')
        return;
    end
end

query = '(scRNAseq OR scRNA-seq OR single cell RNA-seq) AND "10x Genomics" AND "Homo+sapiens"[Organism]';
query = strrep(query, ' ', '+');  % Replace spaces for URL encoding

% Define E-utilities search URL
baseURL = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi';
db = 'gds';
retmax = 10000;  % Max number of results to retrieve
url = sprintf('%s?db=%s&term=%s&retmax=%d&retmode=json', baseURL, db, query, retmax);

% Fetch data from NCBI
response = webread(url);

% Decode JSON
% data = jsondecode(response);
data = response;
% Extract GSE IDs
gse_ids = data.esearchresult.idlist;

data.esearchresult.querytranslation

% Display results
fprintf('Found %d GSE IDs related to scRNA-seq:\n', length(gse_ids));
% disp(gse_ids)


% Optionally write to a text file
fid = fopen('scRNAseq_GSE_list.txt', 'w');
for i = 1:length(gse_ids)
    fprintf(fid, 'GSE%s\n', gse_ids{i});
end
fclose(fid);


% for kx = 1:length(gse_ids)
for kx = 1:min([10 length(gse_ids)])
    uid = gse_ids{kx};
    url = ['https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=gds&id=' uid '&retmode=json'];
    data = webread(url);
    pause(5);

    docsum = data.result.(matlab.lang.makeValidName(uid));
    accession = docsum.accession;
    speciestag = pkg.ai_speciesCommonName(docsum.taxon);
    
    % fprintf('UID %s corresponds to GEO accession: %s\n', uid, accession);
    
    samples = docsum.samples;
    sample_accessions = string({samples.accession});
    sample_titles = string({samples.title});

    fprintf('UID: %s | GEO accession: %s | Sample size: %d\n', ...
        uid, accession, length(sample_accessions));
    
    for k = 1:min([3 length(sample_accessions)])
        acc = sample_accessions(k);
        outmatfile = fullfile(accession, acc, 'cleandata.mat');
        % outmatfile = sprintf('%s%s%s%scleandata.mat', accession, filesep, acc, filesep);
        if ~exist(outmatfile, "file")
            done = false;
            try
                sce = sc_readgeoaccess(acc);
                sce = sce.qcfilter;
                sce = sce.embedcells('tsne3d', true, true, 3);
                sce = sce.clustercells([], [], true);
                sce = sce.assigncelltype(speciestag, false);
                sce = sce.estimatecellcycle;
                sce = sce.estimatepotency(speciestag);
                sce.metadata = sce.metadata + newline + sample_titles(k);  
                done = true;
            catch ME
                disp(ME.message);
            end
            if done
                if ~exist(fileparts(outmatfile), "dir"), mkdir(fileparts(outmatfile)); end
                pause(1);
                save(outmatfile, 'sce', '-v7.3');
            end
        end
    end    

end


%arrayfun(@(x) fprintf('\\theta_{%d,%d} = %.3f\n', ...
%    x.ControlQubits, x.TargetQubits, x.Angles), ...
%    samples)

