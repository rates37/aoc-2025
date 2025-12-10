% Problem is essentially solving a linear system modulo 2
% Solving A x = b
% -> A is the shape (m,n) where m is the number of lights, n is number of
% buttons
% -> x is a (n, 1) vector of 1s and 0s to say whether the button is pressed
% -> b is the target state of lights
% So for example [.##.] (3) (1,3) (2)
% -> b = [0;1;1;0];
% Use modified gaussian ellimination 
function total = day10part1(filename)
    % computes answer to day10 AoC puzzle part 1
    %
    % Usage:
    %   total = day10part1('input.txt');

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
        [R, pivocol, inconsistent] = row_red_ech_form([A b]);

        if inconsistent
            error("System is inconsistent");
        end

        [m, n] = size(A);

        % Particular solution:
        x0 = zeros(1,n);
        for i = 1:length(pivocol)
            c = pivocol(i);
            rhs = R(i, n+1);

            val = rhs;
            for j = c+1:n
                if R(i,j) == 1
                    val = xor(val, x0(j));
                end
            end
            x0(c) = val;
        end
        
        freecols = setdiff(1:n, pivocol);
        k = numel(freecols);
        basis = zeros(k,n);
        for idx = 1:k
            fc = freecols(idx);
            v = zeros(1,n);
            v(fc) = 1;
            for i = 1:length(pivocol)
                pc = pivocol(i);
                if R(i,fc) == 1
                    v(pc) = 1;
                end
            end
            basis(idx,:) = v;
        end

        % try all combinations of free variables:
        best = inf;
        for mask = 0 : (2^k - 1)
            x = x0;
            bits = bitget(mask, 1:k);
            for j = 1:k
                if bits(j)
                    x = xor(x, basis(j, :));
                end
            end
            best = min(best, sum(x)); % Store best so far
        end
        total = total + best;
    end
    fclose(fid);
    fprintf("Part 1: %d\n", total);
end

function [A, b] = parse_line(line)
    pattern = regexp(line, '\[([.#]+)\]', 'tokens', 'once');
    buttons = regexp(line, '\(([^)]*)\)', 'tokens');


    desired_lights = pattern{1};
    b = double(desired_lights == '#').'; % Convert desired lights to boolean array
    nButtons = length(buttons);
    nLights = length(b);

    A = zeros(nLights, nButtons); % Initialize A matrix with zeros of shape (m,n)

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



% Computes row reduced echelon form of matrix M
function [R, pivocol, inconsistent] = row_red_ech_form(M)
    [m,n] = size(M);
    R = M;
    pivocol = [];
    row = 1;

    for col = 1:n-1 % since the final col is the RHS in augmented matrix
        pivo = find(R(row:m, col), 1) + row - 1;
        if isempty(pivo) 
            continue;
        end

        % swap rows:
        if pivo ~= row
            tmp = R(row, :);
            R(row,:) = R(pivo,:);
            R(pivo,:) = tmp;
        end

        pivocol(end+1) = col;

        % eliminate other rows:
        for r = 1:m 
            if r ~= row && R(r,col) == 1
                R(r,:) = xor(R(r,:), R(row,:));
            end
        end

        row = row + 1;
        if row > m
            break
        end
    end

    % check for inconsistency: (completely unnecessary if puzzle input is
    % formatted correctly)
    inconsistent = false;
    for ii = 1:m
        if all(R(ii,1:end-1)==0) && R(ii,end) == 1
            inconsistent = true;
            return
        end
    end
end