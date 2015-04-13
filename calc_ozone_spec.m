function S=calc_ozone_spec(S,do_plots)
% CALC_OZONE_SPEC  Calculate ozone line spectrum from measured spectra

% background estimates

S_bg=S(:,[2 1]);
n_smooth=11;
%S_bg=conv2(ones(1,n_smooth)/n_smooth,1,S_bg,'same');
S_bg=sgolayfilt(S_bg,2,n_smooth);

if do_plots
  figure
  semilogy(S)
  %hold on
  %semilogy(S_bg,'--')
end

% SNR

S=(S./S_bg)-1;

if do_plots
  figure
  plot(S)
end

% combine up/down-shifted spectra

N=size(S,1);
S=0.5*(S(2:(N/2),1)+S(N/2+2:end,2));

if do_plots
  figure
  plot(S)
end

% linear fit to detrend

%m=(n_smooth-1)/2;
%m=40;
m=0;
%m=0;
x=-(128-m):(128-m);
P=polyfit(x,S(N/4+x).',1);
S0=polyval(P,x).';
S=S(N/4+x)-S0;
if do_plots
  line(N/4+x,S0,'color','r');
end


