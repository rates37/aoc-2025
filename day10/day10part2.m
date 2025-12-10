
% Problem is a linear programming optimisation problem
% We want to minimise ones.T * x
% Subject to:
%    A x = b
%    xi >= 0
%    x \in Z^n

function total = day10part2(filename)
    % computes answer to day10 AoC puzzle part 2
    %
    % Usage:
    %   total = day10part2('input.txt');

    fid = fopen(filename, 'r');
    if fid < 0
        error('Cannot open file: %s', filename);
    end

    total = 0;

    while true
        % Read in a line from file:
        line = fgetl(fid);
        if ~ischar(line) 
            break;
        end

        line = strtrim(line);
        if isempty(line)
            continue
        end

        % Parse the line values:
        [A, b] = parse_line(line);
        [~, nButtons] = size(A);

        % Set up the linear programming problem
        f = ones(nButtons, 1); % Objective function coefficients
        
        % constraints:
        Aeq = A;
        beq = b;
        lowerBound = zeros(nButtons, 1);
        upperBound = []; % there's no upper bound, since trying to minimise
        
        intcon = 1:nButtons; % indices of integer variables
        options = optimoptions('intlinprog', 'Display', 'off');

        % Solve the linear programming problem
        [~, fval, exitflag] = intlinprog(f,intcon,[],[],Aeq,beq,lowerBound,upperBound,options);
        if exitflag <= 0 
            error("No sols found. Input must be invalid");
        end

        total = total + sum(fval);
    end

    fclose(fid);
    fprintf("Part 2: %d\n", total);
end




function [A, b] = parse_line(line)
    pattern = regexp(line, '\{([^}]*)\}', 'tokens', 'once');
    buttons = regexp(line, '\(([^)]*)\)', 'tokens');

    parts = strsplit(pattern{1}, ',');
    b = str2double(parts(:));
    nLights = length(b);
    nButtons = length(buttons);
    A = zeros(nLights, nButtons);


    % Populate the A matrix:
    for j = 1:nButtons
        contents = buttons{j}{1};
        if isempty(contents)
            idx = [];
        else 
            parts = strsplit(contents, ',');
            idx = cellfun(@str2double, parts);
        end
        for ii = idx
            A(ii+1, j) = 1; % yucky 1 indexing
        end
    end
end
