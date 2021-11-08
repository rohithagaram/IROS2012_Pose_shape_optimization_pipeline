seqID = 5;
start_frm = 0;
end_frm = 240;
carID = 31;
numFrames = end_frm - start_frm + 1;
seq = seqID .* ones(1, numFrames);
frm = start_frm:1:end_frm;
id = carID .* ones(1, numFrames);
numObs = 36;
numPts = 36;
numVecs = 42;
K = [721.53,0,609.55;0,721.53,172.85;0,0,1];
avgCarLength = 3.8600;
avgCarWidth = 1.6362;
avgCarHeight = 1.5208;
[~,~,~, new_seq_frm_id] = keypointLocalizations(seq, frm, id,1);
seq = new_seq_frm_id(:,1)';
frm = new_seq_frm_id(:,2)';
id = new_seq_frm_id(:,3)';
numViews = length(frm);
B = mobili(seq, frm, id);
carCenters = B(:,4:6);
[wireframe, ~] = approxAlignWireframe(seq, frm, id);
[~, def_vectors, rotation_collection, translation_collection, lambdas_collection] = shapeOptimizer(seq, frm, id);
%last_dv = def_vectors(42*29-41 : 42*29, :);
%def_vectors = [def_vectors; repmat(last_dv, 132 - 70 + 1, 1)];
%lambdas_collection = lambdas_collection(1:29,:);
observation_wts = keypointWeightsShape(seq, frm, id);
[~, keypoints_collection] = keypointLocalizations(seq, frm, id,0);

fileID = fopen("ceres/ceres_input_multiViewAdjuster.txt","w");
fprintf(fileID, "%d %d %d %d\n", [numViews, numPts, numObs, numVecs]);
fprintf(fileID, "%f %f %f\n", [avgCarHeight, avgCarWidth, avgCarLength]);
fprintf(fileID, "%f %f %f %f %f %f %f %f %f\n", reshape(K',[1 9]));
for i=1:numViews
    fprintf(fileID, "%f %f %f\n", [carCenters(i,1), carCenters(i,2), carCenters(i,3)]);
end
for i=1:numViews
    fprintf(fileID, "%f %f\n", keypoints_collection(2*i-1:2*i,:));
end
for i=1:numViews
    fprintf(fileID, "%f\n", observation_wts(:,i));
end
for i=1:numViews
    fprintf(fileID, "%f %f %f\n", wireframe(3*i-2:3*i,:));
end
for i=1:numViews
    for j=1:42
        for k=1:3:108
            fprintf(fileID, "%f %f %f ", def_vectors(42*(i-1) + j, k : k+2)); 
        end
        fprintf(fileID, "\n");
    end
end

lambdas = mean(lambdas_collection);
% lambdas=[0.0208000000000000,0.00970000000000000,0.00720000000000000,0.00570000000000000,0.00470000000000000,0.00330000000000000,0.00210000000000000,0.00160000000000000,0.00100000000000000,0.000900000000000000,0.000800000000000000,0.000800000000000000,0.000700000000000000,0.000600000000000000,0.000500000000000000,0.000500000000000000,0.000400000000000000,0.000400000000000000,0.000400000000000000,0.000300000000000000,0.000300000000000000,0.000300000000000000,0.000300000000000000,0.000300000000000000,0.000200000000000000,0.000200000000000000,0.000200000000000000,0.000200000000000000,0.000200000000000000,0.000200000000000000,0.000200000000000000,0.000100000000000000,0.000100000000000000,0.000100000000000000,0.000100000000000000,0.000100000000000000,0.000100000000000000,0.000100000000000000,0.000100000000000000,0.000100000000000000,0.000100000000000000,0.000100000000000000];
fprintf(fileID, "%f ", lambdas);
fprintf(fileID, "\n");
for i=1:numViews
    fprintf(fileID, "%f\n", rotation_collection(:,i));
end
for i=1:numViews
    fprintf(fileID, "%f\n", translation_collection(:,i));
end
fclose(fileID);
cd ceres ;
system(" multiViewAdjuster");
cd ../ ;

multi_opt_wireframe = importdata("ceres/ceres_output_multiViewAdjuster.txt");
% system("rm transLog.txt");
f = fopen("transLog.txt","w");
f1 = fopen("angleLog.txt","w");
for i=1:length(frm)
    image = "left_colour_imgs/" + string(seq(i)) + "_" + string(frm(i)) + ".png";
    wireframe = multi_opt_wireframe(36*i-35:36*i,:)';
    new_car_centers = mean(wireframe');
%     f = fopen("transLog.txt","a");
    fprintf(f, "%f %f %f\n", new_car_centers);
%     fclose(f);
    proj_wf = K * wireframe;
    wf_img = proj_wf(1:2,:) ./ proj_wf(3,:);
    img = figure;
    visualizeWireframe2D(image, wf_img);
    saveas(img, sprintf("multiViewResult/%d_%d_%d.png", seq(i), frm(i), id(i)));
    close(img);
    pause(0.1);
end
fclose(f);


cd multiViewResult
cmd = "ffmpeg -framerate 5 -start_number "+string(start_frm)+" -i "+string(seqID)+"_%d_"+string(carID)+".png"+" -c:v libx264 -r 30  -vf "+'"pad=ceil(iw/2)*2:ceil(ih/2)*2"'+" -pix_fmt yuv420p  " + string(seqID) + "_" + string(start_frm) + "_" + string(end_frm) + "_" + string(carID) + ".mp4";
system(cmd);
cd ..
final_rot = importdata("rotLog.txt");
final_pose = importdata("transLog.txt");
f = fopen(string(seqID) + "_" + string(start_frm) + "_" + string(end_frm) + "_" + string(carID) + ".txt","w");
for i=1:size(final_rot, 1)
    fprintf(f, "%f %f %f %f %f %f %f %f %f %f %f %f\n", final_rot(i,:), final_pose(i,:));
end
fclose(f);