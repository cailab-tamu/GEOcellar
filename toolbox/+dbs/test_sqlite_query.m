db = sqlite('geo.db');

% Query
seriesData = fetch(db, 'SELECT * FROM series');
sampleData = fetch(db, 'SELECT * FROM samples');
disp(seriesData)
disp(sampleData)


query = sprintf("PRAGMA table_info(%s)", "samples");
schemaResult = fetch(db, query);

close(db)