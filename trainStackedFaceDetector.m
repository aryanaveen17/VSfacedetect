function sceneFeatures = trainStackedFaceDetector(imgSet)

trainingPhotosPerPerson = max(5,min([imgSet.Count]));
testSet = select(imgSet,1:trainingPhotosPerPerson);
allIms = [testSet.ImageLocation];

% Setup options; detection tuned to "permissive" state
% After trying many combinations of detection and extraction methods, we
% find that FAST features and SURF extraction works exceptionally well....
% The FAST feature detection is tuned to be fairly "permissible"; that is,
% we specify low values of MinQuality and MinContrast to return a lot of
% matches. We will then match the test image against each training set, and
% consider that we "recognize" the match that minimizes our metric (Sum of
% Absolute Differences, or SAD).

adjustHistograms = false; %Low-cost way to improve performance
fcnHandle = @(x) detectFASTFeatures(x,...
	'MinQuality',0.025,...
	'MinContrast',0.025); %#ok
extractorMethod = 'SURF';%#ok
metric = 'SAD'; %#ok

% Rather than match to individual faces or to "person-averaged faces," we
% create "montages" of each training set. Features are "aggregated" in that
% matches are evaluated to whole training sets, rather than to subsets
% thereof.

inds = reshape(1:numel(allIms),[],nFaces);
scenePoints = cell(nFaces,1);
sceneFeatures = cell(nFaces,1);
targetSize = 100;
thumbSize = [targetSize,targetSize];
for ii = 1:nFaces
	% Create montages of each training set of face images:
	trainingImage = createMontage(allIms(inds(:,ii)),...
		'montageSize',[size(inds,1),1],...
		'thumbSize',thumbSize);
	if adjustHistograms
		trainingImage = histeq(trainingImage);%#ok
	end
	scenePoints{ii} = fcnHandle(trainingImage);
	[sceneFeatures{ii}, scenePoints{ii}] = extractFeatures(trainingImage, scenePoints{ii},...
		'Method',extractorMethod);
end
