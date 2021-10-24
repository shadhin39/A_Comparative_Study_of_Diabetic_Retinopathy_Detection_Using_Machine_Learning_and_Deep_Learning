scFile=dir('E:\Feature Extraction using Matlab\Modified Base\*.tif');
for i = 1:length(scFile)
    filename = strcat('E:\Feature Extraction using Matlab\Modified Base\',scFile(i).name);
    %[folder, baseFileNameNoExt, extension] = fileparts(filename);
    disp(filename);
    I = imread(filename); 
    green_channel = I(:,:,2);
    grayImage = green_channel;

    mask=imbinarize(grayImage,0.05); %im2bw


        %%
        % BackgroundFilterSize
    bgFilterSize = [78 78]; 

        % Median filtering, to remove noise
    intermediate.SPdenoised = medfilt2(grayImage, [3, 3]); 

        % Histogram equalisation
    intermediate.histeq = adapthisteq(intermediate.SPdenoised);

        % Gaussian smoothing
    intermediate.gaussImage = imgaussfilt( double(intermediate.histeq), 2, 'FilterSize', [3 3]);

        % MedianImage for background estimation (very large median filter)
    intermediate.bgEstimateImage = medfilt2( uint8(intermediate.gaussImage), bgFilterSize);



        % Store this as the background image
    intermediate.shadecorrectedImage = intermediate.gaussImage ./ double(intermediate.bgEstimateImage+1);
    preprocessedImage = intermediate.shadecorrectedImage / (std2(intermediate.shadecorrectedImage)+1);

        % Multiple the preprocessed image with binary mask of input image
    v = preprocessedImage.*mask;




        %%
        % Performs morphological closing operation using linear structuring element to extract blood vessels    
        % A degree range from 0 to 180 degrees (with increment factor '3')is considered, since the line strel is symmetrical.
    vessel = detectVessel(v,'tophatStrelSize', 11);
    tophatImage = vessel - v;


        % Creates a 2D-Gaussian lowpass filter and perform filtering on tophatImage
    gaussWindowSize = [15 15];
    gaussSigma = 1;
    h = fspecial('gaussian', gaussWindowSize, gaussSigma);
    gaussImage = imfilter(tophatImage, h, 'same');



        %% 

    se = strel('disk',5);
    closeBW = imclose(gaussImage,se);

    bin = imbinarize(closeBW,0.1);
    bwCandidates=imfill(bin,'holes');

    
    output=strcat('Newfeatures/Modified_Micro_aneurysm\',scFile(i).name);
    imwrite(bwCandidates,output);

    
     
end    


function [vessel] = detectVessel(img, varargin)

    p = inputParser();

    addParameter(p, 'degreeRange', 0:3:180);
    addParameter(p, 'tophatStrelSize', 11);
    parse(p, varargin{:});
    degrees = p.Results.degreeRange;
    strel_size = p.Results.tophatStrelSize;

    vessel= ones( size(img)) * 9999;
    for deg=degrees
        str_el = strel('line', strel_size, deg);
        c = imclose(img, str_el);
        vessel = min(c, vessel);
    end
end
