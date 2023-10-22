% Histogram Equalization
clc
clear
close all

imagePath = 'dog_image.jpg';
histogramFilePath = 'histogram_equalized.txt';


% Open the txt file for writing
histogramfileID = fopen(histogramFilePath, 'w');

% Check if the file was opened successfully
if histogramfileID == -1
    error('Unable to open the histogram file for writing.');
end

originalImage = imread(imagePath);

grayImage = rgb2gray(originalImage);

figure
subplot(2, 3, 1)
imshow(grayImage)
title({'Original Grayscale Image', ''});
subplot(2, 3, 4)
histogram(grayImage)
title({'Histogram of Original Grayscale Image',''});

hgram = ones(1, 1) * prod(size(grayImage)) / 1;
J = histeq(grayImage, hgram);

subplot(2, 3, 2)
imshow(J)
title({'Image after histogram equalization', 'with built-in function'});
subplot(2, 3, 5)
histogram(J)
title({'Histogram of Image after histogram equalization', 'with built-in function'});

% Histogram Equalization without built-in histeq function:
[row, col] = size(grayImage);
no_of_pixels = row * col;
H = uint8(zeros(row,col));

freq = zeros(256,1);
pdf = zeros(256,1);
cdf = zeros(256,1);
cum = zeros(256,1);
output = zeros(256,1);

% Calculating Probability
for i = 1:row          
    for j = 1:col
        value = grayImage(i, j);
        freq(value + 1) = freq(value + 1) + 1;
        pdf(value + 1) = freq(value + 1) / no_of_pixels;
    end  
end  

sum=0;
no_bins=255;

% Calculating Cumulative Probability
for i = 1:size(pdf)

   sum = sum + freq(i);

   cum(i) = sum;

   cdf(i) = cum(i) /no_of_pixels;

   output(i) = round(cdf(i) * no_bins);


end

for i = 1:row
    for j = 1:col
            H(i,j) = output(grayImage(i,j) + 1);
    end
end

subplot(2, 3, 3)
imshow(H)
title({'Image after histogram equalization', 'without built-in function'});
subplot(2, 3, 6)
histogram(H)
title({'Histogram of Image after histogram equalization', 'without built-in function'});



% Write histogram values to the file as binary strings
for i = 1:256
    fprintf(histogramfileID, '%s\n', dec2bin(H(i), 14));
end



