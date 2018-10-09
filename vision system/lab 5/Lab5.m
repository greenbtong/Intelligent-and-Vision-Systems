close all;

%% Reading image
i1 = 'red_square_static.jpg';
i2 = 'GingerBreadMan_first.jpg';
i3 = 'GingerBreadMan_second.jpg';
i4 = 'red_square_video.mp4';

im1 = imread(i1);
im2 = imread(i2); % change name to process other images
im3 = imread(i3); % change name to process other images
%imshow(im);

%% corner (1)
maxCor = 1;

bin_im1 = rgb2gray(im1);
c1 = corner(bin_im1, maxCor);

bin_im2 = rgb2gray(im2);
c2 = corner(bin_im2, maxCor);

% %visualize ( need to compare these two )
% subplot(2,1,1);
% imshow(bin_im2);
% hold on 
% plot(c2(:,1),c2(:,2),'r*');
% title("Gingerbread Man (1 corner)")
% hold off
% 
% subplot(2,1,2);
% imshow(bin_im1);
% hold on 
% plot(c1(:,1),c1(:,2),'r*');
% title("Box (1 corners)")
% hold off

%% optical flow of gignerbreadman (2)
bin_im3 = rgb2gray(im3);
c3 = corner(bin_im3, maxCor);


% % Create optical flow object.
% opticFlow = opticalFlowLK('NoiseThreshold',0.009);
% 
% % Estimate and display the optical flow of objects in the video.
% for i = 1 : 2
%     if i ==1 
%         frameGray = bin_im2;
%         frameRGB = im2;
%     else 
%         frameGray = bin_im3;
%         frameRGB = im3;
%     end
%     flow = estimateFlow(opticFlow,frameGray); 
% 
%     imshow(frameRGB) 
%     hold on
%     plot(flow,'DecimationFactor',[5 5],'ScaleFactor',10)
%     hold off 
% end

%% Optical flow (3)
vidReader = VideoReader(i4);
opticFlow = opticalFlowLK('NoiseThreshold',0.009);

frameRGB = readFrame(vidReader);
frameGray = rgb2gray(frameRGB);

cs = corner(frameGray);
corner_x = min(cs(:,1));
corner_y = min(cs(:,2));
corners = [min(cs(:,1)) min(cs(:,2))];
flow = estimateFlow(opticFlow,frameGray);
track = corners;

while hasFrame(vidReader)

    frameRGB = readFrame(vidReader);
    frameGray = rgb2gray(frameRGB);
    
    cs = corner(frameGray);
    diff = corners - cs;    
    dist = [];
    for j = 1 : size(diff,1)
        dist = [dist, sqrt(diff(j,1)^2 + diff(j,2)^2) ];
    end
    flow = estimateFlow(opticFlow,frameGray);
    [m,x] = min(dist);
    corners = [cs(x,1) + flow.Vx(round(cs(x,1)), round(cs(x,1))) cs(x,2) + flow.Vy(round(cs(x,2)), round(cs(x,2)))];
    track = [track; corners];
end
%% Visualize last frame and path (3)
load red_square_gt

imshow(frameRGB)
hold on
scatter(track(:,1),track(:,2),'r.')
scatter(gt_track_spatial(:,1), gt_track_spatial(:,2), 'b.')
legend('expermiental', 'actual');
hold off

%% Error between mine and actual track (3)
ERROR = track - gt_track_spatial;
eS = ERROR.^2;
eT = [];
for i = 1: size(eS,1)
    eT = [eT; eS(i,1)+eS(i,2)];
end
figure, plot(eT);
title('Square Error')
xlabel('Track')
ylabel('Square Error')

%% Tracking single object (4)
clear all;
vidReader = VideoReader('visionface.avi');
opticFlow = opticalFlowLK('NoiseThreshold',0.009);

frameRGB = readFrame(vidReader);
frame_num = 1;
colourRegion = frameRGB(132:132 + 80, 279:279+60, :);
frameGray = rgb2gray(frameRGB);

r = (colourRegion(:,:,1));
g = (colourRegion(:,:,2));
b = (colourRegion(:,:,3));

% corners (interesting points)
% cr = corner(r);
% cb = corner(b);
% cg = corner(g);

%Get histValues for each channel
[yr, xr] = imhist(r);
[yg, xg] = imhist(g);
[yb, xb] = imhist(b);

%Plot them together in one plot
%figure, plot(xr, yr, 'Red', xg, yg, 'Green', xb, yb, 'Blue');

% % plot and normalize
fr = yr/sum(yr);
figure, bar(xr, fr, 'r');
%xlim([0 256])
title('Histogram of the red colour')
fg = yg/sum(yg);
figure, bar(xg,fg, 'g');
%xlim([0 256])
title('Histogram of the green colour')
fb = yb/sum(yb);
figure, bar(xb,fb, 'b');
%xlim([0 256])
title('Histogram of the blue colour')

%% get first interesting_points (second frame and third)
flow = estimateFlow(opticFlow,frameGray);
frameRGB = readFrame(vidReader);
frame_num = frame_num+1;
frameGray = rgb2gray(frameRGB);
bbox = [266, 121, 83, 93];

flow = estimateFlow(opticFlow,frameGray);
[row, col] = find(flow.Vx ~= 0);
interesting_points = [col, row];

%% test 1 in the box
test1 = test_one(interesting_points, bbox);

%% test 2 color thresh hold
test2 = test_two(test1, frameRGB, fr, fg, fb);

%% test 3 cant have objects close to each other
flow_points = test_three(test2);

%% first track
% create tracks variable
tracks_structure = struct;
tracks_structure.position_x = [0];
tracks_structure.position_y = [0];
tracks = repmat(tracks_structure, 0, 1);
% add first points as tracks
for i = 1 : size(flow_points, 1)
new_track.position_x = flow_points(i, 1);
new_track.position_y = flow_points(i, 2);
tracks(end + 1) = new_track;
end

 imshow(frameRGB)
 hold on
% rectangle('Position', tbox, 'EdgeColor','g')
 rectangle('Position', bbox, 'EdgeColor','r')
% %scatter(266+83, 121+93,'b*') %bottom right
% %scatter(interesting_points(:,1),interesting_points(:,2),'b.')
% %scatter(test1(:,1),test1(:,2),'b.')
% %scatter(test2(:,1),test2(:,2), 'r.')
scatter(flow_points(:,1),flow_points(:,2),'g.')
 hold off
%% next (o - y) repeat from here on out
% stuff = bbox;
% while hasFrame(vidReader)
% frameRGB = readFrame(vidReader);
% frame_num = frame_num+1;
% frameGray = rgb2gray(frameRGB);
% flow = estimateFlow(opticFlow,frameGray);
% 
% [row, col] = find(flow.Vx ~= 0);
% d_interesting_points = [col, row];
% 
% %% test the interesting points
% test1 = test_one(d_interesting_points, bbox);
% test2 = test_two(test1, frameRGB, fr, fg, fb);
% detected_interesting_points = test_three(test2);
% %%
% size(detected_interesting_points)
% size(flow_points)
% %% build cost matrix between current positions and new flow points
% cost = zeros(size(flow_points, 1), ...
%     size(detected_interesting_points, 1));
% for i = 1:size(flow_points, 1)
%     for j = 1 : size(detected_interesting_points, 1)
%         cost(i, j) = norm(flow_points(i, :) - detected_interesting_points(j, :));
%     end
% end
% %% compute assigments between currents positions and new flow points
% costOfNonAssignment = 10;
% [assignments, unassignedTracks, unassignedDetections] = ...
%     assignDetectionsToTracks(cost, costOfNonAssignment);
% 
% %% update assignmented tracks
% new_points = flow_points;
% for i = 1 : size(assignments, 1)
% track_id = assignments(i, 1);
% interesting_point_id = assignments(i, 2);
% new_points(track_id, 1) = detected_interesting_points(interesting_point_id, 1) + flow.Vx(round(detected_interesting_points(interesting_point_id, 2)), round(detected_interesting_points(interesting_point_id, 1)));
% new_points(track_id, 2) = detected_interesting_points(interesting_point_id, 2) + flow.Vy(round(detected_interesting_points(interesting_point_id, 2)), round(detected_interesting_points(interesting_point_id, 1)));
% end
%   
% for i = 1 : numel(tracks)
% tracks(i).position_x(end + 1) = new_points(i, 1);
% tracks(i).position_y(end + 1) = new_points(i, 2);
% end
% %% filter tracks which have not been assigned
% tracks(unassignedTracks) = [];
% 
% %% add new tracks from unassigned flow points
% if (mod(frame_num, 5) == 0)
%     % add new points
%     for i = 1 : numel(unassignedDetections)
%         interesting_point_id = unassignedDetections(i);
%         new_track.position_x = detected_interesting_points(interesting_point_id, 1);
%         new_track.position_y = detected_interesting_points(interesting_point_id, 2);
%         tracks(end + 1) = new_track;
%     end
% end
% 
% %%
% other = [];
% for i = 1 : size(tracks, 2)
%     other = [other; round(tracks(i).position_x(size(tracks(1).position_x,2))) round(tracks(i).position_y(size(tracks(1).position_x,2)))];
% end
% test2 = test_two(other, frameRGB, fr, fg, fb);
% maybe = test_three(test2);
% %median(maybe)
% % tracks(1).position_x(size(tracks(1).position_x,2))
% % median(tracks.position_x)
% % flow_points
% %bbox
% 
% %% shift bbox
% bbox =ShiftBbox(bbox, median(maybe));
% stuff = [stuff; bbox];
% end
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 



%%
%%stuff
%%
% imshow(frameRGB)
% hold on
% rectangle('Position', tbox, 'EdgeColor','g')
% rectangle('Position', bbox, 'EdgeColor','r')
% %scatter(266+83, 121+93,'b*') %bottom right
% %scatter(interesting_points(:,1),interesting_points(:,2),'b.')
% %scatter(test1(:,1),test1(:,2),'b.')
% %scatter(test2(:,1),test2(:,2), 'r.')
% %scatter(test3(:,1),test3(:,2),'g.')
% hold off

%% test 1 in the box
%test1 = test_one(interesting_points, bbox);
%tracks
% test2 = test_two(tracks, frameRGB, fr, fg, fb);
% flow_points = test_three(test2);


%% testing
% clear all
% 
% vidReader = VideoReader('visionface.avi');
% opticFlow = opticalFlowLK('NoiseThreshold',0.009);
% 
% while hasFrame(vidReader)
% frameRGB = readFrame(vidReader);
% colourRegion = frameRGB(132:132 + 80, 279:279+60, :);
% r =(colourRegion(:,:,1));
% g = (colourRegion(:,:,2));
% b = (colourRegion(:,:,3));
% cr = corner(r);
% cb = corner(b);
% cg = corner(g);
% % imshow(colourRegion);
% % hold on
% % scatter(cr(:,1), cr(:,2), 'r.')
% % scatter(cg(:,1), cg(:,2), 'g.')
% % scatter(cb(:,1), cb(:,2), 'b.')
% % hold off
% 
% end

% [yRed, x1] = imhist(r);
% figure, bar(x1,yRed)
% xlim([0 256])

%% histogram attempts
% Im_grey = rgb2gray(colourRegion);
% figure, sd=imhist(Im_grey);
% xlabel('Number of bins (256 by default for a greyscale image)')
% ylabel('Histogram counts')

% %histRGB(colourRegion)
% %figure, histogram(r(:),218,'EdgeColor','r', 'Normalization', 'pdf')
%figure, xr = histogram(r(:),256,'EdgeColor','k','FaceColor','r');
% figure, xg = histogram(g(:),124,'EdgeColor','k', 'FaceColor','g', 'Normalization', 'probability');
%figure, xb = histogram(b(:),124,'EdgeColor','k', 'FaceColor','b' , 'Normalization', 'probability');

% [fr,xr] = hist(r(:),numel(r));
% fr = fr/trapz(xr,fr);
% %figure, bar(xr,fr, 8, 'r')
% [fg,xg] = hist(g(:),numel(g));
% fg = fg/trapz(xg,fg);
% %figure, bar(xg,fg, 8, 'g')
% [fb,xb] = hist(b(:),numel(b));
% fb = fb/trapz(xb,fb);
% %figure, bar(xb,fb, 8, 'b')

%% test 1 in the box
% test1 = [];
% for i = 1 :size(interesting_points,1)
%     if (interesting_points(i,2) >= bbox(2) && interesting_points(i,2) <= bbox(2)+bbox(4))
%         if (interesting_points(i,1) >= bbox(1) && interesting_points(i,1) <= bbox(1)+bbox(3))
%             test1 = [test1; interesting_points(i,:)];
%         end
%     end
% end
%% test 2 color thresh hold
% colour_threshold = 1.0e-08;
% test2 = [];
% for i = 1: size(test1,1)
%     if (fr(frameRGB(test1(i,2),test1(i,1),1) + 1) * fg(frameRGB(test1(i,2),test1(i,1),2) + 1) * fb(frameRGB(test1(i,2),test1(i,1),3) + 1) > colour_threshold)
%         test2 = [test2; test1(i,:)];
%     end
% end
%% test 3 cant have objects close to each other
% proximity_threshold = 3;
% keep = [];
% test3 = test2;
% for i = size(test3,1): -1: 1
%     for j = i: -1: 1
%         if i > j
%             diff = test3(i,:) - test3(j,:);
%             dist = sqrt(diff(1)^2 + diff(2)^2);
%             if dist < proximity_threshold
%                 test3(j,:) = [];
%                 break
%             end
%         end
%     end
% end


