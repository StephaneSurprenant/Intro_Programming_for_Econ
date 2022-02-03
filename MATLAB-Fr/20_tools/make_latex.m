function table = make_latex(S, varargin)

% This function allows to make a latex table out of a cell array from 
% Matlab, as well as allows to write this table directly into a .tex 
% document and modify several aspects of the table.
%
% INPUTS: S: cell array for core of the table;
% OUTPUTS: table.core: cell array for core of the table;
%               .header: cell array for header of the table;
%               .bottom: cell array for the bottom of the table;
%               .table: character containing the .tex code;
%
% Name-Pair values:
% row: (cell array) names of the rows;
% col: (cell array) names of the columns;
% annotate: (numeric) matrix containing values between 0 length(sym) to add
%            symbols to the core of a table;
% sym: (cell array) contains a list of symbols to be used;
% label: (character) add a label for cross-referencing in Latex;
% multicol: (logical) if you use multicolumn line;
% multicol_line: (cell array) .tex command line for multicolumn option;
% small: (logical) adds \small command to adjust text size;
% title: (character) title of the table;
% notes: (character) notes to the table;
% nan_rep: (logical) converts NaN entries to '-';
% nan_other: (character) converts NaN entries to supplied expression;
% french_dec: (logical) convert '.' decimals for ',' decimals;
% date: (logical) tells if serial date number are present;
% date_cols: (numeric) vector identifying columns containing serial date
%             numbers;
% date_format: (character) passes the format to be used to convert serial
%               dates to strings;
% french_month: (logical) tells if months ('mm-yyyy' format only) are to be
%                spelled out in french (e.g., 01-1977 == janvier-1977);
% dec: (numeric) control the (maximal) length of decimal values;
% save: (logical) control whether to save the table to a .tex file;
% f_name: (character) provide 'path\file_name' to save in latex document.
%
% Author: Stephane Surprenant, UQAM
% Version 1.0: (12/07/2017)
% Version 1.1: (14/07/2017) (Allows saving directly into a .tex document)
% Version 1.2: (16/07/2017) (Now handles NaN conversions)
% Version 1.3: (21/07/2017) (Date options, label, note optional and 
%                            annotations added)
%              (23/07/2017) (Added space to label option to make it work in
%                            latex)
%              (02/08/2017) (Changed superscrit option of 'annotate' from
%                            $INPUT^{symbol}$ to INPUT$^{symbol}$)
%
% Example =================================================================
% options = {'row', {'row1', 'row2'}, ...
%            'col', {'col1', 'col2'}, ...
%            'multicol', false, ...
%            'small', true, ...
%            'title', 'A table example', ...
%            'french_dec', true, ...
%            'annotate', [1,3;0,0], ...
%            'sym', {'example_1', 'lol', 'why_not?'}, ...
%            'notes', 'Here are some notes', ...
%            'save', true, ...
%            'f_name', [pwd, '\example'], ...
%            'dec', 3};
% S = [1.2, 1.3; 2.456, 4];
% Keep_results = make_latex(num2cell(S), options{:});

% Check inputs ============================================================
p = inputParser;

% % if isnumeric(S) == 0
% %    error('S must be a numeric matrix for the core of the table.'); 
% % end

% Default values
[nr, nc] = size(S);
% Annotation
def_annotate = zeros(nr,nc);
def_sym = {'*','**','***'};
% Row and column names
[def_row{1:nr,1}] = deal(' ');
[def_col{1:nc,1}] = deal(' ');
% Label for cross-references in Latex
def_label = '';
% Multicol and french options
def_fr = false;
def_multi = false;
def_multi_line = {''};
% Date options
def_date = false;
def_date_cols = 0;
def_date_format = 'mm-yyyy';
def_french_month = false;
% Nan options
def_nan = true;
def_nan_rep = '-';
% Small text option
def_small = false;
% Decimal precision
def_dec = 3;
% Save
def_save = 'false';
% File name
def_f_name = '';

% Row and column titles
addParameter(p, 'row', def_row, @iscell);
addParameter(p, 'col', def_col, @iscell);
% Annotation
addParameter(p, 'annotate', def_annotate, @isnumeric);
addParameter(p, 'sym', def_sym, @iscell);
% Label option
addParameter(p, 'label', def_label, @ischar);
% Convert to french decimals
addParameter(p, 'french_dec', def_fr, @islogical);
% Multicolumn option (if multicol, multicol .tex command line)
addParameter(p, 'multicol', def_multi, @islogical);
addParameter(p, 'multicol_line', def_multi_line, @iscell);
% Date options
addParameter(p, 'date', def_date, @islogical);
addParameter(p, 'date_cols', def_date_cols, @isnumeric);
addParameter(p, 'date_format', def_date_format, @ischar);
addParameter(p, 'french_month', def_french_month, @islogical);
% Nan replace options
addParameter(p, 'nan_rep', def_nan, @islogical);
addParameter(p, 'nan_other', def_nan_rep, @ischar);
% Title
addParameter(p, 'title', 'TITLE', @ischar);
% Notes
addParameter(p, 'notes', '', @ischar);
% Small text option
addParameter(p, 'small', def_small, @islogical);
% Decimal precision option
addParameter(p, 'dec', def_dec, @isnumeric);
% Save
addParameter(p, 'save', def_save, @islogical);
% File name
addParameter(p, 'f_name', def_f_name, @ischar);

parse(p, varargin{:});
% Get values
row = p.Results.row;
col = p.Results.col;
annotate = p.Results.annotate;
sym = p.Results.sym;
label = p.Results.label;
multicol = p.Results.multicol;
multicol_line = p.Results.multicol_line;
date = p.Results.date;
date_cols = p.Results.date_cols;
date_format = p.Results.date_format;
french_month = p.Results.french_month;
nan_rep = p.Results.nan_rep;
nan_other = p.Results.nan_other;
french_dec = p.Results.french_dec;
title = p.Results.title;
notes = p.Results.notes;
small = p.Results.small;
dec = p.Results.dec;
save = p.Results.save;
f_name = p.Results.f_name;

if dec < 1
   error('Decimal precision must be at least 1.'); 
end

% Make core ===============================================================
% Decimal precision
for i = 1:nr
    for j = 1:nc
        if isnumeric(S{i,j}) == 1
            S_ok{i,j} = num2str(round(S{i,j},dec));
        else
            S_ok{i,j} = S{i,j};
        end 
    end
end
% Convert serial dates to date strings
% Make french dates if french_date == 1
if strcmp('mm-yyyy', date_format) == 1 && french_month == 1
    months = {'janvier ', 'février ', 'mars ', 'avril ', 'mai ', 'juin ', ...
             'juillet ', 'août ', 'septembre ', 'octobre ', ...
             'novembre ', 'décembre '};
    old_months = {'01-', '02-', '03-', '04-', '05-', ...
                 '06-', '07-', '08-', '09-', '10-', ...
                 '11-', '12-'};
end
% Conversion of dates
if date == 1
    for i = 1:nr
        for j = date_cols
            % Make date strings
            temp = datestr(str2num(S_ok{i,j}), date_format);
            temp2 = strsplit(temp, '-');
            if french_month == 1
                % Get month
                m = str2num(temp2{1});
                % Replace
                S_ok{i,j} = strrep(temp, [temp2{1}, '-'], months{m});
            else
                S_ok{i,j} = temp;
            end
        end
    end
end
% Annotation
for i = 1:nr
   for j = 1:nc
       for k = 1:length(sym)
       if annotate(i,j) == k
           % S_ok{i,j} = ['$', S_ok{i,j}, '^{', sym{k}, '}$'];
           S_ok{i,j} = [S_ok{i,j}, '$^{', sym{k}, '}$'];
       end
   end
end
% Core
for i = 1:nr
   table.core{i,1} = strjoin({row{i}, ' &'}); 
   for j = 1:nc-1
       table.core{i,1} = strjoin({table.core{i,1}, ...
                                  S_ok{i,j}, ' &'});
   end
   table.core{i,1} = strjoin({table.core{i,1}, ...
                              S_ok{i,end}, ' \\'});
end
table.core{end,1} = strjoin({table.core{end,1}, ...
                             ' \bottomrule\bottomrule'});
% NaN replace option
if nan_rep == 1
   for i = 1:nr
      table.core{i,1} = strrep(table.core{i,1}, 'NaN', nan_other);
   end
end
% French decimal option
if french_dec == 1
    for i = 1:nr
        table.core{i,1} = strrep(table.core{i,1}, '.', ',');
    end
end

% Make header =============================================================
table.header{1} = '\begin{table}[H]';
table.header{2} = '\begin{center}';
table.header{3} = ['\caption{', title, '}', ' \label{', label, '}'];
% Option for small text
if small == 1
   table.header{3} = strjoin({table.header{3}, ' \small\small'}); 
end
table.header{4} = ['\begin{tabular}{l', repmat('c',1,nc), '}', ...
                   ' \toprule\toprule'];
j = 5;
% Optional multicolumn .tex line command
if multicol == 1
   table.header{j} = multicol_line{1};
   j = 6;
end
% Column titles
table.header{j} = strjoin({'& ', col{1}});
for i = 2:nc
    table.header{j} = strjoin({table.header{j}, ' & ', col{i}});
end
table.header{j} = strjoin({table.header{j}, ' \\ \midrule'});
    
% Make bottom =============================================================
table.bottom{1} = '\end{tabular}';
table.bottom{2} = '\end{center}';
if ~isempty(notes) == 1
    table.bottom{3} = '\begin{footnotesize}';
    table.bottom{4} = '\flushleft';
    table.bottom{5} = ['Notes: ', notes];
    table.bottom{6} = '\end{footnotesize}';
    table.bottom{7} = '\end{table}';
else
    table.bottom{3} = '\end{table}';
end
% Option for small text
if small == 1
    if isempty(notes)
        table.bottom{4} = '\normalsize';
    else
        table.bottom{8} = '\normalsize';
    end
end
    
table.table = char([table.header'; table.core; table.bottom']);
% Accent conversion (if save = true) ======================================
if save == 1
l_case = {'à', 'â', 'è', 'é', 'ê', 'ë', 'î', 'ï', 'û', 'ç'};
u_case = {'À', 'Â', 'È', 'É', 'Ê', 'Ë', 'Î', 'Ï', 'Û', 'Ç'};
all = [u_case, l_case];
replace_u = {'\\`{A}', '\\^{A}', ...
             '\\`{E}', '\\''{E}', '\\^{E}', '\\"{E}', ...
             '\\^{I}', '\\"{I}', ...
             '\\^{U}', '\\c{C}'};
replace_l = {'\\`{a}', '\\^{a}', ...
             '\\`{e}', '\\''{e}', '\\^{e}', '\\"{e}', ...
             '\\^{i}', '\\"{i}', ...
             '\\^{u}', '\\c{c}'};
replace_all = [replace_u, replace_l];

    a = {table.table};
for j = 1:size(a{1},1)
    new_table{j,1} = regexprep(a{1}(j,:), all, replace_all);
end
    table.table = char(new_table);
end
% Save table ==============================================================
if save == 1
    fid = fopen([f_name, '.tex'], 'w');         % create file and write
    for i = 1:size(table.table, 1)
        fprintf(fid, '%s\n', table.table(i,:)); % print each row to a line
    end
    fclose(fid);
end

end
