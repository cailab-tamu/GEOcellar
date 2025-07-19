query = 'scRNAseq OR scRNA-seq OR single cell RNA-seq OR single-cell transcriptomics AND ''10x Genomics'' AND "Homo+sapiens"[Organism]';
query = strrep(query, ' ', '+');  % Replace spaces for URL encoding

% Define E-utilities search URL
baseURL = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi';
db = 'gds';
retmax = 1000;  % Max number of results to retrieve
url = sprintf('%s?db=%s&term=%s&retmax=%d&retmode=json', baseURL, db, query, retmax);

% Fetch data from NCBI
response = webread(url);

% Decode JSON
% data = jsondecode(response);
data = response;
% Extract GSE IDs
gse_ids = data.esearchresult.idlist;

% Display results
fprintf('Found %d GSE IDs related to scRNA-seq:\n', length(gse_ids));
% disp(gse_ids)

% Optionally write to a text file
fid = fopen('scRNAseq_GSE_list.txt', 'w');
for i = 1:length(gse_ids)
    fprintf(fid, 'GSE%s\n', gse_ids{i});
end
fclose(fid);


for kx = 1:length(gse_ids)

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
    

    
    for k = 1:length(sample_accessions)
        acc = sample_accessions(k);
        outmatfile = sprintf('%s%s%s%scleandata.mat', accession, filesep, acc, filesep);
        if ~exist(outmatfile, "file")
            done = false;
            try
                sce = sc_readgeoaccess(acc);
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
                if ~exist(accession, "dir"), mkdir(accession); end
                if ~exist(acc, "dir"), mkdir(acc); end
                pause(1);
                save(outmatfile, 'sce', '-v7.3');
            end
        end
    end
    

end


%arrayfun(@(x) fprintf('\\theta_{%d,%d} = %.3f\n', ...
%    x.ControlQubits, x.TargetQubits, x.Angles), ...
%    samples)

