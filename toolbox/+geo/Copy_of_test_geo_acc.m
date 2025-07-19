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
disp(gse_ids)

% Optionally write to a text file
fid = fopen('scRNAseq_GSE_list.txt', 'w');
for i = 1:length(gse_ids)
    fprintf(fid, 'GSE%s\n', gse_ids{i});
end
fclose(fid);


% uid = '200153673';
uid = gse_ids{end-2};
url = ['https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=gds&id=' uid '&retmode=json'];
data = webread(url);
% data = jsondecode(response);

docsum = data.result.(matlab.lang.makeValidName(uid));
accession = docsum.accession;

fprintf('UID %s corresponds to GEO accession: %s\n', uid, accession);


%{
    base_esearch = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi';
    base_esummary = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi';
    summary_url = sprintf('%s?db=gds&id=%s', base_esummary, uid);
    pause(3);
    xml = webread(summary_url);
%}

tag =  matlab.lang.makeValidName(data.result.uids{1});
samples = data.result.(tag).samples;
sample_accessions = string({samples.accession});
sample_titles = string({samples.title});
speciestag = data.result.(tag).taxon;

for k = 1:length(sample_accessions)
    acc = sample_accessions(k);
    sce = sc_readgeoaccess(acc);
    sce = sce.embedcells('tsne3d', true, true, 3);
    sce = sce.clustercells([], [], true);
    sce = sce.assigncelltype(speciestag, false);
    sce = sce.estimatecellcycle;
    sce = sce.estimatepotency(speciestag);
    sce.metadata = sce.metadata + newline + sample_titles(k);
end


%arrayfun(@(x) fprintf('\\theta_{%d,%d} = %.3f\n', ...
%    x.ControlQubits, x.TargetQubits, x.Angles), ...
%    samples)

