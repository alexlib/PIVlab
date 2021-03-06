% Example script how to use PIVlab from the commandline
% You can adjust the settings in "s" and "p", specify a mask and a region of interest
clc; clear all;

trials = [ 1 ];

%% For loop which will go over all the directory and save the u,v velocity to the respective directories

for trial = 1:length(trials)
%% Create list of images inside specified directory

directory= sprintf('C:/Users/Krs_lab/Desktop/Dhiraj_matlab_files'); %directory containing the images you want to analyze
suffix='*.jpg'; %*.bmp or *.tif or *.jpg
direc = dir([directory,filesep,suffix]); filenames={};
[filenames{1:length(direc),1}] = deal(direc.name);
filenames = sortrows(filenames); %sort all image files
%amount = length(filenames);
amount = 2;
disp(directory);

%% Calibration (added by me)
realdist = 50; % Enter the real distance in mm
dist = 1000; % Enter the number of pixel
time = 1; %Enter the real time in ms

% Calibration constants are:
calxy=(realdist/1000)/dist; %m/px %realdist=realdistance in m; dist=distance in px
caluv=calxy/(time/1000);

%% Standard PIV Settings
s = cell(10,2); % To make it more readable, let's create a "settings table"
%Parameter                       %Setting           %Options
s{1,1}= 'Int. area 1';           s{1,2}=64;         % window size of first pass
s{2,1}= 'Step size 1';           s{2,2}=32;         % step of first pass
s{3,1}= 'Subpix. finder';        s{3,2}=1;          % 1 = 3point Gauss, 2 = 2D Gauss
%s{4,1}= 'Mask';                  s{4,2}=[];         % If needed, generate via: imagesc(image); [temp,Mask{1,1},Mask{1,2}]=roipoly;
s{5,1}= 'ROI';                   s{5,2}=[100,100,900,400];         % Region of interest: [x,y,width,height] in pixels, may be left empty
s{6,1}= 'Nr. of passes';         s{6,2}=3;          % 1-4 nr. of passes
s{7,1}= 'Int. area 2';           s{7,2}=32;         % second pass window size
s{8,1}= 'Int. area 3';           s{8,2}=32;         % third pass window size
s{9,1}= 'Int. area 4';           s{9,2}=16;         % fourth pass window size
s{10,1}='Window deformation';    s{10,2}='*linear'; % '*spline' is more accurate, but slower

%% Standard image preprocessing settings
%{
p = cell(8,1);
%Parameter                       %Setting           %Options
p{1,1}= 'ROI';                   p{1,2}=s{5,2};     % same as in PIV settings
p{2,1}= 'CLAHE';                 p{2,2}=1;          % 1 = enable CLAHE (contrast enhancement), 0 = disable
p{3,1}= 'CLAHE size';            p{3,2}=50;         % CLAHE window size
p{4,1}= 'Highpass';              p{4,2}=0;          % 1 = enable highpass, 0 = disable
p{5,1}= 'Highpass size';         p{5,2}=15;         % highpass size
p{6,1}= 'Clipping';              p{6,2}=0;          % 1 = enable clipping, 0 = disable
p{7,1}= 'Wiener';                p{7,2}=0;          % 1 = enable Wiener2 adaptive denaoise filter, 0 = disable
p{8,1}= 'Wiener size';           p{8,2}=3;          % Wiener2 window size
%}

%% PIV analysis loop
if mod(amount,2) == 1 %Uneven number of images?
    disp('Image folder should contain an even number of images.')
    %remove last image from list
    amount=amount-1;
    filenames(size(filenames,1))=[];
end
disp(['Found ' num2str(amount) ' images (' num2str(amount/2) ' image pairs).'])
x=cell(amount/2,1);
y=x;
u=x;
v=x;
typevector=x; %typevector will be 1 for regular vectors, 0 for masked areas
counter=0;

%% PIV analysis loop:
for i=1:2:amount
    counter=counter+1;
    image1=imread(fullfile(directory, filenames{i})); % read images
    image2=imread(fullfile(directory, filenames{i+1}));
    %image1 = PIVlab_preproc (image1,p{1,2},p{2,2},p{3,2},p{4,2},p{5,2},p{6,2},p{7,2},p{8,2}); %preprocess images
    %image2 = PIVlab_preproc (image2,p{1,2},p{2,2},p{3,2},p{4,2},p{5,2},p{6,2},p{7,2},p{8,2});
    [x{counter} y{counter} u{counter} v{counter} typevector{counter}] = piv_FFTmulti (image1,image2,s{1,2},s{2,2},s{3,2},s{4,2},s{5,2},s{6,2},s{7,2},s{8,2},s{9,2},s{10,2});
    clc
    disp([int2str((i+1)/amount*100) ' %']);
    
    % Graphical output (disable to improve speed)
    %{
    imagesc(double(image1)+double(image2));colormap('gray');
    hold on;
    quiver(x{counter},y{counter},u{counter},v{counter},'g','AutoScaleFactor', 1.5);
    hold off;
    axis image;
    title(filenames{i},'interpreter','none')
    set(gca,'xtick',[],'ytick',[])
    drawnow;
    %}

end
%%{
%% PIV postprocessing loop
% Settings
%%{
umin = -10; % minimum allowed u velocity
umax = 10; % maximum allowed u velocity
vmin = -10; % minimum allowed v velocity
vmax = 10; % maximum allowed v velocity
stdthresh=3; % threshold for standard deviation check
epsilon=0.1; % epsilon for normalized median test
thresh=5; % threshold for normalized median test

u_filt=cell(amount/2,1);
v_filt=u_filt;
typevector_filt=u_filt;
for PIVresult=1:size(x,1)
    u_filtered=u{PIVresult,1};
    v_filtered=v{PIVresult,1};
    typevector_filtered=typevector{PIVresult,1};
    %vellimit check
    u_filtered(u_filtered<umin)=NaN;
    u_filtered(u_filtered>umax)=NaN;
    v_filtered(v_filtered<vmin)=NaN;
    v_filtered(v_filtered>vmax)=NaN;
    % stddev check
    meanu=nanmean(nanmean(u_filtered));
    meanv=nanmean(nanmean(v_filtered));
    std2u=nanstd(reshape(u_filtered,size(u_filtered,1)*size(u_filtered,2),1));
    std2v=nanstd(reshape(v_filtered,size(v_filtered,1)*size(v_filtered,2),1));
    minvalu=meanu-stdthresh*std2u;
    maxvalu=meanu+stdthresh*std2u;
    minvalv=meanv-stdthresh*std2v;
    maxvalv=meanv+stdthresh*std2v;
    u_filtered(u_filtered<minvalu)=NaN;
    u_filtered(u_filtered>maxvalu)=NaN;
    v_filtered(v_filtered<minvalv)=NaN;
    v_filtered(v_filtered>maxvalv)=NaN;
    % normalized median check
    %Westerweel & Scarano (2005): Universal Outlier detection for PIV data
    [J,I]=size(u_filtered);
    medianres=zeros(J,I);
    normfluct=zeros(J,I,2);
    b=1;
    for c=1:2
        if c==1; velcomp=u_filtered;else;velcomp=v_filtered;end %#ok<*NOSEM>
        for i=1+b:I-b
            for j=1+b:J-b
                neigh=velcomp(j-b:j+b,i-b:i+b);
                neighcol=neigh(:);
                neighcol2=[neighcol(1:(2*b+1)*b+b);neighcol((2*b+1)*b+b+2:end)];
                med=median(neighcol2);
                fluct=velcomp(j,i)-med;
                res=neighcol2-med;
                medianres=median(abs(res));
                normfluct(j,i,c)=abs(fluct/(medianres+epsilon));
            end
        end
    end
    info1=(sqrt(normfluct(:,:,1).^2+normfluct(:,:,2).^2)>thresh);
    u_filtered(info1==1)=NaN;
    v_filtered(info1==1)=NaN;

    typevector_filtered(isnan(u_filtered))=2;
    typevector_filtered(isnan(v_filtered))=2;
    typevector_filtered(typevector{PIVresult,1}==0)=0; %restores typevector for mask
    
    %Interpolate missing data
    u_filtered=inpaint_nans(u_filtered,4);
    v_filtered=inpaint_nans(v_filtered,4);
    
    %Vorticity calculation (added by me)
    [curlz,cav]= curl(x{PIVresult,1}*calxy,y{PIVresult,1}*calxy,u_filtered*caluv,v_filtered*caluv);
    vort_filt{PIVresult,1}=curlz;
    
    [curlz,cav]= curl(x{PIVresult,1}*calxy,y{PIVresult,1}*calxy,u{PIVresult,1}*caluv,v{PIVresult,1}*caluv);
    vort{PIVresult,1}=curlz;
        
    u_filt{PIVresult,1}=u_filtered;
    v_filt{PIVresult,1}=v_filtered;
    typevector_filt{PIVresult,1}=typevector_filtered;
    
end
% Post processing ends here
%}
%% Saving the data
% Saving in common location
filename = sprintf('C:/Users/Krs_lab/Desktop/Dhiraj_matlab_files/dh/.mat',trials(trial));
save (filename,'x','y','u_filt','v_filt','vort_filt');

% Saving in respective folder
%mkdir (sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output',trials(trial)));
%filename = sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/data.mat',trials(trial));
%save (filename,'x','y','u_filt','v_filt','vort_filt');

%% Getting Images of vorticity, u and v
scale_vector = 20;

% Make new directory to store the images of vorticity and velocity after filtering
%mkdir (sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/vorticity',trials(trial)));
%mkdir (sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/u_vel',trials(trial)));
%mkdir (sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/v_vel',trials(trial)));

%New folder for raw vorticity and velocity
%mkdir (sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/vorticity_raw',trials(trial)));
%mkdir (sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/v_vel_raw',trials(trial)));
%mkdir (sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/u_vel_raw',trials(trial)));
   
for i=1:(amount/2)
   im_vorticity(i) = imagesc((interp2(vort_filt{i},4,'cubic')),[-50 50]);
   colorbar;
   hold on;
   quiver(x{i},y{i},u_filt{i}*scale_vector,v_filt{i}*scale_vector,'linewidth',0.5,'color','k','autoscale', 'off');
   hold off;
   axis off;
   save_name = sprintf('C:/Users/krs_lab/Desktop/Dhiraj_matlab_files/first_result/result_%04d.bmp',i);
   saveas(im_vorticity(i), save_name);
end
%{
for i=1:(amount/2)
   im_u_vel(i) = imagesc((interp2(u_filt{i},4,'cubic')),[-0.5 0.5]);
   colorbar;
   hold on;
   quiver(x{i},y{i},u_filt{i}*scale_vector,v_filt{i}*scale_vector,'linewidth',0.5,'color','k','autoscale', 'off');
   hold off;
   axis off;
   save_name = sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/u_vel/u_filt%04d.bmp',trials(trial),i);
   saveas(im_u_vel(i), save_name);
end

for i=1:(amount/2)
   im_v_vel(i) = imagesc((interp2(v_filt{i},4,'cubic')),[-0.5 0.5]);
   colorbar;
   hold on;
   quiver(x{i},y{i},u_filt{i}*scale_vector,v_filt{i}*scale_vector,'linewidth',0.5,'color','k','autoscale', 'off');
   hold off;
   axis off;
   save_name = sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/v_vel/v_filt%04d.bmp',trials(trial),i);
   saveas(im_v_vel(i), save_name);
end

for i=1:(amount/2)
   im_v_vel_raw(i) = imagesc((interp2(v{i},4,'cubic')),[-0.5 0.5]);
   colorbar;
   hold on;
   quiver(x{i},y{i},u{i}*scale_vector,v{i}*scale_vector,'linewidth',0.5,'color','k','autoscale', 'off');
   hold off;
   axis off;
   save_name = sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/v_vel_raw/v%04d.bmp',trials(trial),i);
   saveas(im_v_vel_raw(i), save_name);
end

for i=1:(amount/2)
   im_u_vel_raw(i) = imagesc((interp2(u{i},4,'cubic')),[-0.5 0.5]);
   colorbar;
   hold on;
   quiver(x{i},y{i},u{i}*scale_vector,v{i}*scale_vector,'linewidth',0.5,'color','k','autoscale', 'off');
   hold off;
   axis off;
   save_name = sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/u_vel_raw/u%04d.bmp',trials(trial),i);
   saveas(im_u_vel_raw(i), save_name);
end

for i=1:(amount/2)
   vorticity_raw(i) = imagesc((interp2(vort{i},6,'linear')),[-50 50]);
   colorbar;
   hold on;
   quiver(x{i},y{i},u{i}*scale_vector,v{i}*scale_vector,'linewidth',0.5,'color','k','autoscale', 'off');
   hold off;
   axis off;
   save_name = sprintf('G:/Vortex Ring Experiments/Polymer_soln_expts/PAMH_5ppm/Global/Ensemble/L100_V100/Trial_%01d/PIV_auto_output/vorticity_raw/vort%04d.bmp',trials(trial),i);
   saveas(vorticity_raw(i), save_name);
end
%}
clearvars -except p s x y u v vort typevector directory filenames u_filt v_filt vort_filt typevector_filt trials
disp('DONE.')
end