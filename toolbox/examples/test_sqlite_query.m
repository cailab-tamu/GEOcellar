db = sqlite('geo.db');

% Query
seriesData = fetch(db, 'SELECT * FROM series');
sampleData = fetch(db, 'SELECT * FROM samples');
disp(seriesData)
disp(sampleData)
close(db)