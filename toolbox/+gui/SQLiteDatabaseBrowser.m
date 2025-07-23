function SQLiteDatabaseBrowser()
    % SQLite Database Browser using MATLAB Database Toolbox
    % Main function to create and run the database browser GUI
    
    % Create main figure
    fig = uifigure('Name', 'SQLite Database Browser', ...
                   'Position', [100, 100, 900, 600], ...
                   'Resize', 'on');
    movegui(fig, "center");
    % Initialize global variables
    conn = [];  % Database connection
    
    % Create UI components
    createUI();
    
    function createUI()
        % Create main grid layout
        mainGrid = uigridlayout(fig, [4, 1]);
        mainGrid.RowHeight = {50, 200, 50, '1x'};
        
        % Top panel - Connection controls
        topPanel = uipanel(mainGrid);
        topGrid = uigridlayout(topPanel, [1, 4]);
        topGrid.ColumnWidth = {150, '1x', 100, 100};
        
        uilabel(topGrid, 'Text', 'Database File:');
        dbPathEdit = uieditfield(topGrid, 'Value', 'Select database file...');
        browseBtn = uibutton(topGrid, 'Text', 'Browse', ...
                            'ButtonPushedFcn', @browseDatabase);
        connectBtn = uibutton(topGrid, 'Text', 'Connect', ...
                             'ButtonPushedFcn', @connectDatabase);
        
        % Tables panel
        tablesPanel = uipanel(mainGrid, 'Title', 'Tables and Schema');
        tablesGrid = uigridlayout(tablesPanel, [1, 2]);
        tablesGrid.ColumnWidth = {'1x', '2x'};
        
        % Tables list
        tablesListBox = uilistbox(tablesGrid, 'Items', {}, ...
                                 'ValueChangedFcn', @tableSelected);
        
        % Table info area
        tableInfoArea = uitextarea(tablesGrid, 'Value', 'Select a table to view schema', ...
                                  'Editable', 'off');
        
        % Query panel
        queryPanel = uipanel(mainGrid);
        queryGrid = uigridlayout(queryPanel, [1, 3]);
        queryGrid.ColumnWidth = {'1x', 100, 100};
        
        queryEdit = uieditfield(queryGrid, 'Value', 'SELECT * FROM ');
        executeBtn = uibutton(queryGrid, 'Text', 'Execute', ...
                             'ButtonPushedFcn', @executeQuery);
        clearBtn = uibutton(queryGrid, 'Text', 'Clear', ...
                           'ButtonPushedFcn', @clearQuery);
        
        % Results panel
        resultsPanel = uipanel(mainGrid, 'Title', 'Query Results');
        resultsGrid = uigridlayout(resultsPanel, [1, 1]);
        
        resultsTable = uitable(resultsGrid, 'Data', {}, ...
                              'ColumnName', {});
        
        % Status bar (using a label at the bottom)
        statusLabel = uilabel(fig, 'Text', 'Ready', ...
                             'Position', [10, 5, 980, 20], ...
                             'BackgroundColor', [0.94, 0.94, 0.94]);
        
        % Callback functions
        function browseDatabase(~, ~)
            [file, path] = uigetfile('*.db;*.sqlite;*.sqlite3', 'Select SQLite Database');
            if file ~= 0
                dbPathEdit.Value = fullfile(path, file);
                updateStatus('Database file selected');
            end
        end
        
        function connectDatabase(~, ~)
            try
                % Close existing connection if any
                if ~isempty(conn) && isopen(conn)
                    close(conn);
                end
                
                dbFile = dbPathEdit.Value;
                if ~isfile(dbFile)
                    uialert(fig, 'Database file does not exist!', 'Error');
                    return;
                end
                
                % Create SQLite connection
                conn = sqlite(dbFile, 'readonly');
                
                % Test connection
                if isopen(conn)
                    updateStatus('Connected to database successfully');
                    loadTables();
                else
                    uialert(fig, 'Failed to connect to database', 'Connection Error');
                end
                
            catch ME
                uialert(fig, ['Connection failed: ' ME.message], 'Error');
                updateStatus('Connection failed');
            end
        end
        
        function loadTables(~, ~)
            try
                if isempty(conn) || ~isopen(conn)
                    return;
                end
                
                % Get list of tables
                query = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name";
                result = fetch(conn, query);
                
                if ~isempty(result)
                    tableNames = result.name;
                    tablesListBox.Items = tableNames;
                    updateStatus(sprintf('Found %d tables', length(tableNames)));
                else
                    tablesListBox.Items = {};
                    updateStatus('No tables found');
                end
                
            catch ME
                uialert(fig, ['Failed to load tables: ' ME.message], 'Error');
            end
        end
        
        function tableSelected(~, ~)
            %try
                if isempty(conn) || ~isopen(conn)
                    return;
                end
                
                selectedTable = tablesListBox.Value;
                if isempty(selectedTable)
                    return;
                end
                
                % Get table schema
%                query = sprintf("PRAGMA table_info(%s)", selectedTable);
                                
%                schemaResult = fetch(conn, query)


query = sprintf("SELECT * FROM pragma_table_info('%s')", selectedTable);
schemaResult = fetch(conn, query);
                
                %curs = exec(conn, query);
                %schemaResult = fetch(curs);

                if ~isempty(schemaResult)
                    schemaText = sprintf('Table: %s\n\nColumns:\n', selectedTable);
                    for i = 1:height(schemaResult)
                        schemaText = [schemaText, sprintf('%s (%s)%s\n', ...
                                     schemaResult.name{i}, ...
                                     schemaResult.type{i}, ...
                                     schemaResult.pk(i) > 0, ' [PRIMARY KEY]', '')];
                    end
                    
                    % Get row count
                    countQuery = sprintf("SELECT COUNT(*) as count FROM %s", selectedTable);
                    countResult = fetch(conn, countQuery);
                    if ~isempty(countResult)
                        schemaText = [schemaText, sprintf('\nRow count: %d', countResult.count)];
                    end
                    
                    tableInfoArea.Value = schemaText;
                    
                    % Update query field with basic SELECT
                    queryEdit.Value = sprintf('SELECT * FROM %s LIMIT 100', selectedTable);
                end
                
            %catch ME
            %    uialert(fig, ['Failed to get table info: ' ME.message], 'Error');
            %end
        end
        
        function executeQuery(~, ~)
            try
                if isempty(conn) || ~isopen(conn)
                    uialert(fig, 'Not connected to database', 'Error');
                    return;
                end
                
                query = strtrim(queryEdit.Value);
                if isempty(query)
                    uialert(fig, 'Please enter a query', 'Error');
                    return;
                end
                
                updateStatus('Executing query...');
                
                % Execute query
                result = fetch(conn, query);
                
                if ~isempty(result)
                    % Convert result to cell array for display
                    columnNames = result.Properties.VariableNames;
                    data = table2cell(result);
                    
                    % Handle different data types for display
                    for i = 1:size(data, 1)
                        for j = 1:size(data, 2)
                            if isnumeric(data{i,j}) && isscalar(data{i,j})
                                % Keep numeric values as is
                            elseif iscategorical(data{i,j})
                                data{i,j} = char(data{i,j});
                            elseif islogical(data{i,j})
                                data{i,j} = data{i,j};
                            else
                                data{i,j} = string(data{i,j});
                            end
                        end
                    end
                    
                    resultsTable.Data = data;
                    resultsTable.ColumnName = columnNames;
                    
                    updateStatus(sprintf('Query executed successfully. %d rows returned.', height(result)));
                else
                    resultsTable.Data = {};
                    resultsTable.ColumnName = {};
                    updateStatus('Query executed successfully. No results returned.');
                end
                
            catch ME
                uialert(fig, ['Query execution failed: ' ME.message], 'Error');
                updateStatus('Query execution failed');
            end
        end
        
        function clearQuery(~, ~)
            queryEdit.Value = '';
            resultsTable.Data = {};
            resultsTable.ColumnName = {};
            updateStatus('Query cleared');
        end
        
        function updateStatus(message)
            statusLabel.Text = sprintf('%s - %s', datestr(now, 'HH:MM:SS'), message);
        end
    end

    % Cleanup function when figure is closed
    fig.CloseRequestFcn = @closeApp;
    function closeApp(~, ~)
        try
            if ~isempty(conn) && isopen(conn)
                close(conn);
            end
        catch
            % Ignore errors during cleanup
        end
        delete(fig);
    end
end

% Helper function to create a sample database for testing
function createSampleDatabase()
    % Create a sample SQLite database for testing the browser
    dbFile = 'sample_database.db';
    
    % Remove existing file if it exists
    if isfile(dbFile)
        delete(dbFile);
    end
    
    % Create connection
    conn = sqlite(dbFile);
    
    % Create sample tables
    exec(conn, ['CREATE TABLE employees (' ...
                'id INTEGER PRIMARY KEY, ' ...
                'name TEXT NOT NULL, ' ...
                'department TEXT, ' ...
                'salary REAL, ' ...
                'hire_date DATE)']);
    
    exec(conn, ['CREATE TABLE departments (' ...
                'id INTEGER PRIMARY KEY, ' ...
                'name TEXT NOT NULL, ' ...
                'budget REAL)']);
    
    % Insert sample data
    exec(conn, "INSERT INTO departments VALUES (1, 'Engineering', 500000)");
    exec(conn, "INSERT INTO departments VALUES (2, 'Marketing', 200000)");
    exec(conn, "INSERT INTO departments VALUES (3, 'Sales', 300000)");
    
    exec(conn, "INSERT INTO employees VALUES (1, 'John Doe', 'Engineering', 75000, '2023-01-15')");
    exec(conn, "INSERT INTO employees VALUES (2, 'Jane Smith', 'Marketing', 65000, '2023-03-20')");
    exec(conn, "INSERT INTO employees VALUES (3, 'Bob Johnson', 'Sales', 70000, '2023-02-10')");
    exec(conn, "INSERT INTO employees VALUES (4, 'Alice Brown', 'Engineering', 80000, '2022-11-05')");
    
    close(conn);
    
    fprintf('Sample database created: %s\n', dbFile);
end