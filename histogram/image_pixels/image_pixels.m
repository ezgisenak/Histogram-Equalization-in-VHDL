clc;
clear;

% Step 1: Read the image
imagePath = 'dog_image.jpg';
originalImage = imread(imagePath);

% Step 2: Convert to grayscale
grayImage = rgb2gray(originalImage);

% Step 3: Ensure pixel values are 8-bit
grayImage8bit = uint8(grayImage);

% Step 4: Create a txt file and write pixel values to it
outputFilePath = 'pixel_values.txt';

histogramFilePath = 'histogram.txt';

% Open the txt file for writing
fileID = fopen(outputFilePath, 'w');

histogramfileID = fopen(histogramFilePath, 'w');

% Check if the file was opened successfully
if fileID == -1
    error('Unable to open the file for writing.');
end

if histogramfileID == -1
    error('Unable to open the histogram file for writing.');
end
 
% Get the size of the grayscale image
 [rows, cols] = size(grayImage8bit);
 
% Loop through the image and write pixel values to the file as binary strings
 for row = 1:rows
     for col = 1:cols
         % Get the pixel value at the current row and column
         pixel_value = grayImage8bit(row, col);
 
         % Convert the pixel value to a binary string
         binaryString = dec2bin(pixel_value, 8);
 
         % Write the binary string to the file
         fprintf(fileID, '%s\n', binaryString);
     end
 end

% Initialize variables
L = 256; % Number of bins for the histogram

custom_histogram = zeros(1, L);
 
% Calculate the histogram
for row = 1:size(grayImage8bit, 1)
    for col = 1:size(grayImage8bit, 2)
        pixel_value = uint32(grayImage8bit(row, col));
        custom_histogram(pixel_value + 1) = custom_histogram(pixel_value + 1) + 1;
    end
end

% Write histogram values to the file as binary strings
for i = 1:L
    fprintf(histogramfileID, '%s\n', dec2bin(custom_histogram(i), 14));
end


% Plot the histogram
figure;
bar(0:L - 1, custom_histogram);
title('Grayscale Image Histogram');
xlabel('Pixel Value');
ylabel('Frequency');

% Display the histogram values
disp('Pixel Value | Frequency');
disp('------------------------');
for i = 0:L - 1
    fprintf('%5d       | %8d\n', i, custom_histogram(i + 1));
end

title('Custom Histogram');

% Display the built-in histogram using the 'histogram' function
figure;
histogram(grayImage8bit, L) % matlab histogram
title('Built-in Grayscale Image Histogram');

xlabel('Pixel Value');
ylabel('Frequency');

% Close the file
fclose(fileID);

% Display a message indicating the process is complete
disp('Pixel values have been saved to pixel_values.bin as binary strings.');
