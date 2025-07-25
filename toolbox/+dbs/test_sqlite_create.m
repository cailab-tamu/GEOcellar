% Connect/create SQLite database
db = sqlite('geo.db', 'create');

% Create 'series' table
sql_series = [...
    'CREATE TABLE IF NOT EXISTS series (' ...
    'accession TEXT PRIMARY KEY, ' ...
    'title TEXT, ' ...
    'summary TEXT, ' ...
    'organism TEXT, ' ...
    'experiment_type TEXT, ' ...
    'submission_date TEXT)'];
exec(db, sql_series);

% Create 'samples' table
sql_samples = [...
    'CREATE TABLE IF NOT EXISTS samples (' ...
    'gsm_accession TEXT PRIMARY KEY, ' ...
    'gse_accession TEXT, ' ...
    'title TEXT, ' ...
    'organism TEXT, ' ...
    'characteristics TEXT, ' ...
    'source_name TEXT, ' ...
    'FOREIGN KEY (gse_accession) REFERENCES series(accession))'];
exec(db, sql_samples);