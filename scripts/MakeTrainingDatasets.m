clearvars
%
%   Make Datasets for Classifier
%   Version : alpha 1
%   Author : Simon Kojima
%
%% Preferences

%cd /home/simon/Documents/MATLAB/Classifier
%cd C:\Users\Simon\Documents\MATLAB\Classifier
load ./KFoldEpochData.mat

ChannnelLocationFile = '64ch.ced';

RetainingVariance = 99;
NumSegmentation = 10;

PlotEnable = 0;
SegmentateEnable = 1;

TopoPlotRange = [-10 10];

%% Making Data

k = size(K,2);
for l=1:k
    for n=1:size(K{l},2)
        temp{l}{n} = [];
    end
    for m=1:k
       if l ~= m
          for n=1:size(K{m},2)
            temp{l}{n} = cat(3,temp{l}{n},K{m}{n});
          end
       end
    end
end
Merged = temp;
clear temp;

if SegmentateEnable == 1
    for l=1:k
        fprintf('< %02.0f of %02.0f > ',l,k);
        TimeSegmentation{l} = AdaptiveSegmentation(Merged{l},NumSegmentation);
        save('Segmentation.mat','TimeSegmentation');
    end
end

load ./Segmentation.mat

for l=1:k
    Segmentation{l} = Segmentate(Merged{l},TimeSegmentation{l});
    [Ht,Hnt] = CSP(Segmentation{l}{2},Segmentation{l}{1});
    H{l} = [Ht Hnt];

end

if PlotEnable == 1
   for l=1:k
       figure('Name',['CSP Filter No.' num2str(l)]);
       subplot(1,2,1);
       title('\fontsize{15}CSP Filter for Target');
       topoplot(H{l}(:,1),ChannnelLocationFile,'maplimits',TopoPlotRange,'whitebk','on');
       subplot(1,2,2);
       title('\fontsize{15}CSP Filter for Non-Target');
       topoplot(H{l}(:,2),ChannnelLocationFile,'maplimits',TopoPlotRange,'whitebk','on');
       colorbar('fontsize',15);
   end
end

for l=1:k
   X{l} = []; 
   Y{l} = [];
end

for l=1:k
    for m=1:size(Segmentation{l}{1},3)
        X{l} = [X{l}; reshape(H{l}'*Segmentation{l}{1}(:,:,m),1,size(Segmentation{l}{1},2)*size(H{l},2)) FilteredVariance(H{l},Segmentation{l}{1}(:,:,m))];
        Y{l} = [Y{l};0];
    end
end

for l=1:k
    for m=1:size(Segmentation{l}{2},3)
        X{l} = [X{l}; reshape(H{l}'*Segmentation{l}{2}(:,:,m),1,size(Segmentation{l}{2},2)*size(H{l},2)) FilteredVariance(H{l},Segmentation{l}{2}(:,:,m))];
        Y{l} = [Y{l};1];
    end
end

for l=1:k
    [X{l},Standardize{l}.meanvec,Standardize{l}.stdvec] = Standardization(X{l});
end

%% Applying PCA

for l=1:k
    [pca{l}.U,pca{l}.S,pca{l}.V] = PCA(X{l});
    pca{l}.k = DetDimension(pca{l}.S,RetainingVariance);
    %X{i} = X{i}*pca{i}.U(:,1:pca{i}.k);
end

%% Add an intercept term

for l=1:k
    X{l} = [ones(size(X{l},1),1) X{l}];
end

%% Save Data

TrainingData.X = X;
TrainingData.Y = Y;

TrainedParams.PCA = pca;
TrainedParams.TimeSegmentation = TimeSegmentation;
TrainedParams.Standardize = Standardize;
TrainedParams.H = H;

save('TrainingDatasets.mat','TrainingData');
save('TrainedParams.mat','TrainedParams');