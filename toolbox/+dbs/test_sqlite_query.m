import dbs.*

db = sqlite('+dbs\geo.db');

% Query
seriesData = fetch(db, 'SELECT * FROM series');
sampleData = fetch(db, 'SELECT * FROM samples');
disp(seriesData)
disp(sampleData)

%query = sprintf("PRAGMA table_info(%s)", "samples");
%schemaResult = fetch(db, query);
close(db)


% https://github.com/a-ma72/mksqlite
dbid = mksqlite('open', '+dbs\geo.db');
query = sprintf("PRAGMA table_info(%s)", "samples");
query = 'SELECT * FROM series';
schemaResult = mksqlite(dbid, query)
mksqlite(dbid, 'close')

%%

javaaddpath('+dbs\sqlite-jdbc-3.50.3.0.jar');
url = 'jdbc:sqlite:+dbs\geo.db';
conn = database('', '', '', 'org.sqlite.JDBC', url);
data = fetch(conn, 'SELECT * FROM series');

query = sprintf("PRAGMA table_info(%s)", "samples");
data = fetch(conn, query)