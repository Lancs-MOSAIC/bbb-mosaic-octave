function convert_yesterday
% CONVERT_YESTERDAY  Convert yesterday's .ozo file to MOSAIC ASCII

data_dir=getenv('OZONE_DATA_DIR');
if isempty(data_dir)
  data_dir='/home/ozone/data';
end

fprintf('looking in %s for data\n',data_dir);

% Find yesterday's file

dn_yest=now-1;
in_fname=sprintf('%s_s???.ozo',datestr(dn_yest,'yyyymmdd'));
in_fname=[data_dir filesep in_fname];

d=dir(in_fname);
if isempty(d)
  error('Cannot find data file %s',in_fname);
end

if length(d) > 1
  error('More than one data file found!');
end

in_fname=[data_dir filesep d.name];

% Load file

D=readozo(in_fname);

% Convert to MOSAIC format

dv=datevec(dn_yest);
doy=floor(dn_yest-datenum([dv(1) 1 1 0 0 0]))+1; % day of year
out_fname=sprintf('%02d%03d00.%s',mod(dv(1),100),doy,d.name(10:13));
out_fname=[data_dir filesep out_fname];

fprintf('writing MOSAIC ASCII to %s\n',out_fname);

ozo_to_mosaic(D,out_fname,false);
