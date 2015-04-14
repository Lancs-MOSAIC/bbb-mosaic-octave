function ozo_to_mosaic(D,outfile)
% OZO_TO_MOSAIC  Convert binary .ozo files to MOSAIC ASCII format

Tsys=100; % nominal system temperature (K) for scaling spectrum

num_chans=length(unique(D.channel));
if mod(length(D.st),num_chans) ~= 0
  error('Number of records not divisible by number of channels');
end
num_timestamps=length(D.st)/num_chans;

[ofid,msg]=fopen(outfile,'w');
if ofid==-1
  error('Cannot open output file %s: %s',outfile,msg);
end

% Channels may appear in random order, but for each timestamp, records
% for all channels should be contiguous.

for k=1:num_timestamps

  j=(k-1)*num_chans;
  if ~all(D.st(j+(1:num_chans)) == D.st(j+1))
    error('Channels do not have matching timestamps');
  end

  % indices of channels, in order
  [dummy,idx]=sort(D.channel(j+(1:num_chans)));

  %idx=idx(1);

  S=D.sig_spec(:,:,j+idx);
  oz_spec(k,:)=Tsys*calc_ozone_spec(squeeze(mean(S,3)),false);
  if size(oz_spec,2) ~= 256
    error('Spectrum is not 256 points in length');
  end

  cal_pow=max(D.cal_spec(:,j+idx));
  freq_step=D.samp_rate(j+1)/D.fft_len(j+1);
  freq_start=D.line_freq(j+1)-128*freq_step;
  total_pow=sum(S(:));
  chan_pow=squeeze(sum(sum(S,1),2));
  cal_freq=1320e6+D.freq_err(j+idx);
  

  write_mosaic(ofid,D.st(j+1),freq_step,freq_start,cal_freq, ...
               cal_pow,chan_pow,total_pow,D.station_name{j+1}, ...
               D.vsrt_num(j+1),oz_spec(k,:));

end

fclose(ofid);

figure
plot(mean(oz_spec))

function write_mosaic(fid,st,freq_step,freq_start,cal_freq, ...
               cal_pow,chan_pow,total_pow,station_name,station_num,oz_spec)

format_ver='a';
num_chans=length(cal_freq);
sat_flag=zeros(1,num_chans);
y_factor=nan(1,num_chans);

dn=datenum([1970 1 1 0 0 0])+st/86400;
dv=datevec(dn);
doy=floor(dn-datenum([dv(1) 1 1 0 0 0]))+1; % day of year

fprintf(fid,'%04d:%03d:%02d:%02d:%02d ',dv(1),doy,dv(4),dv(5),dv(6));
fprintf(fid,'%s %d %9.4f %9.7f ',format_ver,num_chans,freq_start/1e6, ...
        freq_step/1e6);
for k=1:num_chans
  fprintf(fid,'%d %9.4f %9.5f %.5f %.2f ',sat_flag(k),cal_freq(k)/1e6,cal_pow(k), ...
          10*log10(chan_pow(k)),y_factor(k));
end

fprintf(fid,'%9.5f %s spect%03d ',10*log10(total_pow),station_name,station_num);

% scale spectrum by peak magnitude

peak=max(abs(oz_spec));
oz_spec=oz_spec/peak;

fprintf(fid, '%9.5f s ',peak);

% convert spectrum to base64 representation

oz_spec=round(oz_spec*2000+2000);
oz_spec(oz_spec < 0)=0;
oz_spec(oz_spec > 4095)=4095;

base64=['A':'Z' 'a':'z' '0':'9' '+' '/'];

hi=base64(floor(oz_spec/64)+1);
lo=base64(mod(oz_spec,64)+1);
str=[hi; lo];

fprintf(fid,'%s',str(:));

fprintf(fid,'\n');

