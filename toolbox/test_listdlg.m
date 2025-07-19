% SCRIPT_FIGURE_WITH_LISTDLG
% This script creates a figure with a button. When the button is clicked,
% a list dialog box (listdlg) will pop up, allowing the user to select
% one or more items from a list.

% Create a new figure
fig = figure('Name', 'My List Selection Figure', ...
    'Position', [100, 100, 400, 300], ...
    'WindowStyle','modal',);

movegui(fig,"center");

% Create a push button
btn = uicontrol('Parent', fig, ...
                'Style', 'pushbutton', ...
                'String', 'Select from List', ...
                'Position', [150, 130, 100, 40], ...
                'Callback', @buttonCallback);

% --- Nested function for the button's callback ---
    function buttonCallback(~, ~)
        % This function is executed when the button is clicked.
        
        % Define the list of items for the dialog
        list_items = {'Option A', 'Option B', 'Option C', 'Option D', 'Option E'};
        
        % Define dialog box title and prompt
        dlg_title = 'Make Your Selection';
        prompt_string = 'Please select one or more options:';
        
        % Pop up the list dialog
        % 'SelectionMode', 'multiple' allows multiple selections. Use 'single' for only one.
        [selection_indices, ok] = listdlg('PromptString', prompt_string, ...
                                          'SelectionMode', 'multiple', ...
                                          'ListString', list_items, ...
                                          'Name', dlg_title);
        
        % Process the user's selection
        if ok % User clicked 'OK'
            if ~isempty(selection_indices)
                disp('You selected the following items:');
                for i = 1:length(selection_indices)
                    fprintf('- %s\n', list_items{selection_indices(i)});
                end
            else
                disp('You clicked OK, but no items were selected.');
            end
        else % User clicked 'Cancel' or closed the dialog
            disp('List dialog was cancelled.');
        end
    end