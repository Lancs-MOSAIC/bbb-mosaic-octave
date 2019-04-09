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
hdr_version=nan;

% test for header magic
hdr_magic=fread(fid,1,'uint32=>uint32');
if hdr_magic == uint32(sscanf('a9e4b8b4','%lx'))
  hdr_version=fread(fid,1,'uint32=>uint32');
  if hdr_version > 4
    error('Unknown header version %d',hdr_version);
  end
  rec_len=fread(fid,1,'uint32');
else
  % old-style format
  rec_len=8+8+2*4+3*fft_len*4;
  old_format=true;
end

fseek(fid,0,'bof'); % rewind file

% estimate number of records - could be wrong if format changes in file

est_num_recs=floor(d.bytes/rec_len);
fprintf(' estimated %d complete records\n',est_num_recs);

D.st=nan(est_num_recs,1);
D.freq_err=nan(est_num_recs,1);
D.num_int=nan(est_num_recs,2);
D.samp_rate=nan(est_num_recs,1);
D.fft_len=nan(est_num_recs,1);
D.channel=nan(est_num_recs,1);
D.serial=cell(est_num_recs,1);
D.line_freq=nan(est_num_recs,1);
D.vsrt_num=nan(est_num_recs,1);
D.station_name=cell(est_num_recs,1);
D.max_sig=nan(est_num_recs,1);
D.cal_spec=[];
D.sig_spec=[];

prev_hdr_version=hdr_version;

k=1;
while true

  if ~old_format
    
    % Search for start of record, in case the
    % file has been corrupted.
    
    pos=ftell(fid);
    hdr_found=header_search(fid);
    if ~hdr_found
      fprintf(' cannot find another record.\n');
      break;
    end
    fseek(fid,-4,'cof'); % rewind to header start
    pos_new=ftell(fid);
    if pos_new > pos
      fprintf('Skipped %d bytes between records\n',pos_new-pos);
    end  
    
    % Read magic value, version and record length
    
    a=fread(fid,[1 3],'uint32');
    if length(a) ~= 3
      break; % end of file
    end
    hdr_version=a(2);
    rec_len=a(3);
    if hdr_version ~= prev_hdr_version
      fprintf('header version changed: was %d now %d\n',prev_hdr_version, ...
              hdr_version);
      prev_hdr_version=hdr_version;
    end
  end

  % check record is complete
  pos=ftell(fid);
  if ~old_format
    bytes_to_read=rec_len-3*4; % first 3 fields already read
  else
    bytes_to_read=rec_len;
  end
  if d.bytes-pos < bytes_to_read
    fprintf('File ends before current record');
    break;
  end
  
  st=fread(fid,1,'uint64');
  if isempty(st)
    break; % end of file
  end
  D.st(k)=st;
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
    if hdr_version >= 4
      D.max_sig(k)=fread(fid,1,'int32');
    end
  end
  if isempty(D.cal_spec)
    D.cal_spec=nan(fft_len,est_num_recs);
    D.sig_spec=nan(fft_len,2,est_num_recs);
  end
  s=fread(fid,[fft_len 3],'float32');
  s=fftshift(s,1);
  D.cal_spec(:,k)=s(:,1);
  D.sig_spec(:,:,k)=s(:,2:3);

  if ~old_format
    % If not at end of file, check for start of next record.
    % If this is missing then the current record is
    % almost certainly corrupt.
    
    pos=ftell(fid);
    if d.bytes-pos >= 4
      hdr_magic=fread(fid,1,'uint32=>uint32');
      fseek(fid,-4,'cof'); % rewind
      if hdr_magic ~= uint32(sscanf('a9e4b8b4','%lx'))
        fprintf(' next record does not follow current one - ignoring current record\n');
        continue; % don't increment record counter
      end
    end
  end  
  
  k=k+1;

end

% Remove any redundant elements

num_recs=k-1;

fprintf(' read %d records\n',num_recs);

if num_recs < est_num_recs
  fn=fieldnames(D);
  for j=1:length(fn)
    switch fn{j}
      case 'sig_spec'
        D.(fn{j})=D.(fn{j})(:,:,1:num_recs);
      case 'cal_spec'
        D.(fn{j})=D.(fn{j})(:,1:num_recs);
      otherwise
        D.(fn{j})=D.(fn{j})(1:num_recs,:);
    end
  end
end

fclose(fid);

% search a byte at a time for the header magic pattern

function hdr_found=header_search(fid)

magic_patt=[0xb4 0xb8 0xe4 0xa9];
shift_reg=fread(fid,[1 4],'uint8');
if length(shift_reg) ~= 4
  hdr_found=false;
  return;
end

while ~all(shift_reg==magic_patt)
  b=fread(fid,1,'uint8');
  if isempty(b)
    hdr_found=false;
    return;
  end
  shift_reg=[shift_reg(2:4) b];
end

hdr_found=true;
