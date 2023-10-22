% 4-bit message
message = [0 1 1 0]; 
codeword = hamming74_encode(message);
disp('Encoded Codeword:');
disp(codeword);

% Simulate a single-bit error in the codeword
error_position = 3; % Change this to simulate errors at different positions
codeword_with_error = codeword;
codeword_with_error(error_position) = ~codeword_with_error(error_position);

decoded_message = hamming74_decode(codeword_with_error);
disp('Decoded Message:');
disp(decoded_message);

% Function to encode a 4-bit message into a Hamming(7,4) codeword
function codeword = hamming74_encode(message)
    % Check if the input message is a 4-bit vector
    if length(message) ~= 4
        error('Input message must be a 4-bit vector.');
    end
    
    % Create the generator matrix for Hamming(7,4)
    G = [1 1 1 0 0 0 0; 1 0 0 1 1 0 0; 0 1 0 1 0 1 0; 1 1 0 1 0 0 1];
    
    % Encode the message
    codeword = mod(message * G, 2);
end

% Function to decode a Hamming(7,4) codeword into a 4-bit message
function message = hamming74_decode(codeword)
    % Check if the input codeword is a 7-bit vector
    if length(codeword) ~= 7
        error('Input codeword must be a 7-bit vector.');
    end
    
    % Create the parity-check matrix for Hamming(7,4)
    H = [1 0 1 0 1 0 1; 0 1 1 0 0 1 1; 0 0 0 1 1 1 1];
    
    % Compute the syndrome
    syndrome = mod(codeword * H', 2);
    
    % Correct errors if syndrome is non-zero
    error_position = 0;
    for i = 1:3
        error_position = error_position + syndrome(i) * 2^(3-i);
    end
    
    if error_position > 0
        % Correct the error
        codeword(error_position) = ~codeword(error_position);
    end
    
    % Extract the original 4-bit message
    message = codeword([3, 5, 6, 7]);
end
