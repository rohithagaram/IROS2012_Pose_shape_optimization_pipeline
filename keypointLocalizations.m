function [wkps, keypoints_collection,bbox_collection, new_seq_frm_id] = keypointLocalizations(seq, frm, id,img_en)

info = importdata("infofile.txt");
indices = [];
new_seq_frm_id = [];
for i=1:size(seq,2)
    index = find(info(:,2) == seq(i) & info(:,3) == frm(i) & info(:,4) == id(i));
    indices = [indices; index];
    new_seq_frm_id = [new_seq_frm_id; info(index,2) info(index,3) info(index,4)];
end

kp = importdata("result_KP.txt");
data = [];
for i=1:size(indices,1)
    data = [data; kp(indices(i),:)];
end
tracklets_data = tracklets(seq, frm, id);
wkps = []; % Confidence value for that keypoint from the keypoint localization network
keypoints_collection = [];
bbox_collection = [];
keypoints_prev = reshape(data(1,:), [3 36]);
for i=1:size(data,1)
    %right_count = 0;
    %left_count = 0;
    keypoints = reshape(data(i,:), [3 36]); 
    %keypoints_prev_int =  keypoints ;
    keypoints(1,:) = keypoints(1,:) * abs(tracklets_data(i,4) - tracklets_data(i,6))/64;
    x= keypoints(1,:);
    keypoints(2,:) = keypoints(2,:) * abs(tracklets_data(i,5) - tracklets_data(i,7))/64;
    y = keypoints(2,:);
    keypoints(1:2,:) = keypoints(1:2,:) + [tracklets_data(i,4); tracklets_data(i,5)];
    %{
    x_1 = x* 256 /  abs(tracklets_data(i,4) - tracklets_data(i,6));
    y_1= y* 256 / abs(tracklets_data(i,5) - tracklets_data(i,7));
    for k=1:size(x_1,2)
        if(x_1(1,k)) < 128
            left_count = left_count + 1 ;
        else
            right_count = right_count + 1 ;
        end
    end
    if right_count < 11 || left_count < 11
        keypoints_next = reshape(data(i+1,:), [3 36]); 
        keypoint_1(1,:) = (keypoints_next(1,:) + keypoints_prev(1,:))/2 ;
        keypoint_1(2,:) = (keypoints_next(2,:) + keypoints_prev(2,:))/2 ;
        keypoints(1,:) = keypoint_1(1,:) * abs(tracklets_data(i,4) - tracklets_data(i,6))/64;
        x= keypoints(1,:);
        keypoints(2,:) = keypoint_1(2,:) * abs(tracklets_data(i,5) - tracklets_data(i,7))/64;
        y = keypoints(2,:);
        keypoints(1:2,:) = keypoints(1:2,:) + [tracklets_data(i,4); tracklets_data(i,5)];
    end
    keypoints_prev = keypoints_prev_int;
    %}
    keypoints_collection = [keypoints_collection; keypoints(1:2,:)];
    wkps = [wkps, keypoints(3,:)'];
    bbox_collection = [bbox_collection,[tracklets_data(i,4),tracklets_data(i,5),tracklets_data(i,6),tracklets_data(i,7)]'];
    
    if img_en == 1  
        img = "left_colour_imgs/" + string(seq(i)) + "_" + string(frm(i)) + ".png";
        right_count = 0;
        left_count = 0;
        figure; 
        img_read_array = imread(img);
        I2 = imcrop(img_read_array,[tracklets_data(i,4), tracklets_data(i,5), tracklets_data(i,6)-tracklets_data(i,4),tracklets_data(i,7)-tracklets_data(i,5)]);
        x_2 = x* 256 /  abs(tracklets_data(i,4) - tracklets_data(i,6));
        y_2 = y* 256 / abs(tracklets_data(i,5) - tracklets_data(i,7));
        for k=1:size(x_2,2)
            if(x_2(1,k)) < 128
                left_count = left_count + 1 ;
            else
                right_count = right_count + 1 ;
            end
        end
        J = imresize(I2, [256,256]);
        text_str = cell(2,1);
        conf_val = [left_count,right_count]; 
        for ii=1:2
            if ii == 1 
                text_str{ii} = ['Left kypntcnt: ' num2str(conf_val(ii),'%0.2f')];
            else
                text_str{ii} = ['Right kypntcnt: ' num2str(conf_val(ii),'%0.2f')];
            end
        end
        position = [0 0;150 0]; 
        box_color = {'red','yellow'};
        RGB = insertText(J,position,text_str,'FontSize',10,'BoxColor',box_color,'BoxOpacity',0.4,'TextColor','white');       
        imshow(RGB); 
        hold on;
        a = [1:36]';  
        b = num2str(a); c = cellstr(b); % strings to label 
        dx = 0.001; dy = 0.01; % displacement  so the text does not overlay the data points 
        text(x_2+dx, y_2+dy, c,colo='green',fontsize=15); 
        title("Key Point plot"); 
        F = getframe;
		save_file_name = sprintf("keypoints/%d_%d_%d.png", seq(i), frm(i), id(i));
		imwrite(F.cdata, save_file_name);
		close(figure);
		close all;

    end
end

end