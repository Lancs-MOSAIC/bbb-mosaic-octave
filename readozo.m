function D=readozo(fname,fft_len)
% READOZO  Read BBB MOSAIC binary data file (.ozo)

if nargin < 2
  fft_len=1024;
end


d=dir(fname);

fid=fopen(fname,'r');
if fid==-1
  error('cannot open file %s',fname);
end

old_format=false;

% test for header magic
hdr_magic=fread(fid,1,'uint32=>uint32');
if hdr_magic == uint32(sscanf('a9e4b8b4','%lx'))
  hdr_version=fread(fid,1,'uint32=>uint32');
  if hdr_version > 3
    error('Unknown header version %d',hdr_version);
  end
  rec_len=fread(fid,1,'uint32');
else
  % old-style format
  rec_len=8+8+2*4+3*fft_len*4;
  old_format=true;
end

fseek(fid,0,'bof'); % rewind file

num_recs=floor(d.bytes/rec_len);
fprintf(' %d complete records\n',num_recs);

D.st=nan(num_recs,1);
D.freq_err=nan(num_recs,1);
D.num_int=nan(num_recs,2);
D.samp_rate=nan(num_recs,1);
D.fft_len=nan(num_recs,1);
D.channel=nan(num_recs,1);
D.serial=cell(num_recs,1);
D.line_freq=nan(num_recs,1);
D.vsrt_num=nan(num_recs,1);
D.station_name=cell(num_recs,1);
D.cal_spec=[];
D.sig_spec=[];

for k=1:num_recs

  if ~old_format
    fseek(fid,3*4,'cof'); % skip first part of header
  end

  D.st(k)=fread(fid,1,'uint64');
  D.freq_err(k)=fread(fid,1,'double');
  D.num_int(k,:)=fread(fid,[1 2],'int32');
  if ~old_format
    D.samp_rate(k)=fread(fid,1,'uint32');
    D.fft_len(k)=fread(fid,1,'uint32');
    fft_len=D.fft_len(k);
    if hdr_version >= 2
      D.channel(k)=fread(fid,1,'int32');
      D.serial{k}=fread(fid,[1 16],'char=>char');
    end
    if hdr_version >= 3
      D.line_freq(k)=fread(fid,1,'double');
      D.vsrt_num(k)=fread(fid,1,'int32');
      D.station_name{k}=fread(fid,[1 16],'char=>char');
    end
  end
  if isempty(D.cal_spec)
    D.cal_spec=nan(fft_len,num_recs);
    D.sig_spec=nan(fft_len,2,num_recs);
  end
  s=fread(fid,[fft_len 3],'float32');
  s=fftshift(s,1);
  D.cal_spec(:,k)=s(:,1);
  D.sig_spec(:,:,k)=s(:,2:3);

end


fclose(fid);
