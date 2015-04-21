function rtgraph(fname,num_channels)
% RTGRAPH  Realtime graph of ozone spectrometer data

magic_val=sscanf('a9e4b8b4','%x'); % record marker "magic" value
max_hdr_version=4;

fid=fopen(fname,'r');
if fid==-1
  error('Cannot open %s',fname);
end

% read and check magic, version, record length

x=fread(fid,[1 3],'uint32');
hdr_version=x(2);
rec_len=x(3);

if x(1) ~= magic_val
  error('%s is not a valid data file',fname);
end

if hdr_version > max_hdr_version
  error('%s: header version %d not known',fname,hdr_version);
end

prev_file_len=0;

while true

  % get file length
  while true
    fseek(fid,0,'eof');
    file_len=ftell(fid);
    if file_len-prev_file_len >= num_channels*rec_len
      fprintf('\n'); fflush(stdout);
      break;
    end
    fprintf('.'); fflush(stdout);
    pause(5);
  end
  
  prev_file_len=file_len;  

  num_recs=floor(file_len/rec_len);

  % seek to last set of complete records
  fseek(fid,rec_len*num_channels*(floor(num_recs/num_channels)-1),'bof');

  % read and check magic, version, record length
  x=fread(fid,[1 3],'uint32');
  if ~all(x==[magic_val hdr_version rec_len])
    error('Error reading %s: maybe header version changes in file?');
  end

  fseek(fid,-3*4,'cof');

  % read records
  
  for k=1:num_channels
    D(k)=read_record(fid,hdr_version);
  end

  % do something interesting
  
  f=(0:D(1).fft_len-1)-D(1).fft_len/2;
  f=f*D(1).samp_rate/D(1).fft_len;
  dn=datenum([1970 1 1 0 0 0])+D(1).st/86400;

  ch=[D.channel];
  for k=1:num_channels
    j=find(ch==(k-1));
    if length(j)~=1
      error('Missing or duplicate channels');
    end
    figure(k)
    subplot(2,1,1);
    plot(f/1e3,10*log10(D(j).cal_spec));
    %xlabel('Frequency offset (kHz)');
    ylabel('Power (dB)');
    title(sprintf('Channel %d %s',k-1,datestr(dn,'yyyy-mm-dd HH:MM:SS')));
    subplot(2,1,2);
    plot(f/1e3,10*log10(D(j).sig_spec));
    xlabel('Frequency offset (kHz)');
    ylabel('Power (dB)');
    tstr=['Signal spectra'];
    if isfield(D(j),'max_sig')
      tstr=[tstr sprintf(' (max. amplitude = %d)',D(j).max_sig)];
    end
    title(tstr);
  end

end

fclose(fid);

function D=read_record(fid,hdr_version)

fseek(fid,3*4,'cof'); % skip magic, version, length

D.st=fread(fid,1,'uint64');
D.freq_err=fread(fid,1,'double');
D.num_int=fread(fid,[1 2],'int32');
D.samp_rate=fread(fid,1,'uint32');
D.fft_len=fread(fid,1,'uint32');
fft_len=D.fft_len;
if hdr_version >= 2
  D.channel=fread(fid,1,'int32');
  D.serial=fread(fid,[1 16],'char=>char');
end
if hdr_version >= 3
  D.line_freq=fread(fid,1,'double');
  D.vsrt_num=fread(fid,1,'int32');
  D.station_name=fread(fid,[1 16],'char=>char');
end
if hdr_version >= 4
  D.max_sig=fread(fid,1,'int32');
end
s=fread(fid,[fft_len 3],'float32');
s=fftshift(s,1);
D.cal_spec=s(:,1);
D.sig_spec=s(:,2:3);

