
function [pulse_compressed, unfocused_SAR, multi_looked] = ...
    unfocusedSAR3(rawIn, N_coherent, M_incoherent)

%%This version removes the time domain shift of the chirp, which resulted
%%in misalignment of the picks

%%rawIn is the raw data, and attributes is the structure containing the 11
%%attributes. These can be most easily acquired from the get_pri_range
%%function.

%%N_coherent and M_incoherent are parameters controlling the number of
%%coherent and incoherent sums, respectively. Both are optional. If
%%unspecified, N_coherent defaults to 70. If unspecified, M_incoherent is set to a default value
%%(currently 4*N).

%%% initial radar parameters %%%
f_sample = 22; % MHz
[nsamples, n_traces] = size(rawIn); % number of samples in a trace
tmax = nsamples/f_sample; %time of last sample relative to pulse, us
bandwidth = 10; % MHz, note this is 15 MHz for IIS
chirp_length = 4; % us
window_length = 4; % us




%%% Create blackman filter %%%
fast_time = linspace(0,tmax,nsamples); %us 
ref_chirp_imag = -sin(2*pi*fast_time.*(-bandwidth/2+bandwidth/2/chirp_length.*fast_time)); %unwindowed chirp
ref_chirp_real = cos(2*pi*fast_time.*(-bandwidth/2+bandwidth/2/chirp_length.*fast_time));
b_window = ones(1,nsamples)*0.0; % initialize window
black = blackman(floor(window_length*f_sample)); % returns blackman filter
b_window(1:window_length*f_sample) = black; % sets beginning of window to filter coefficients
black_ref_real = ref_chirp_real.*b_window; % apply window to reference chirp
black_ref_imag = ref_chirp_imag.*b_window;  
deChirpTime = complex(black_ref_real,black_ref_imag).'; 
%deChirpTime = circshift(deChirpTime,-chirp_length*f_sample/2,1); %center chirp to t = 0

fftSize = 2^(ceil(log2(size(rawIn, 1) + length(black)))); 
assert(fftSize == 2048, 'fftSize = %d, expected 2048', fftSize)

%%% perform pulse compression %%%
pulse_compressed = zeros(fftSize, size(rawIn, 2)); %initialize pulse_compressed traces
for n = 1:n_traces % for each trace
    %convolve raw traces with windowed reference chirp
    pulse_compressed(:,n) = ifft(fft(rawIn(:,n), fftSize) .* ...
                                 conj(fft(deChirpTime, fftSize)), fftSize);
end
%remove zero-padding including partial convolutions at bottom (87 partial
%convolutions between samples 1962 and 2048 in 88 sample chirp case)
pulse_compressed = pulse_compressed(1:size(rawIn,1), :);

%%% perform unfocused SAR %%%
if ~exist('N_coherent','var')
    N = 70; 
else 
    N = N_coherent; %Number of coherent summations
end
disp(['Coherently summing ' num2str(N) ' traces'])
unfocused_SAR = zeros(nsamples, n_traces-N); % initialize SAR data
for i = 1:n_traces-N % for each moving average i
    unfocused_SAR(:,i) = sum(pulse_compressed(:,i:i+N-1), 2);
    % add trace j's contribution to moving average i using traces from
    % pulse compressed trace i to i+N
end

%%% perform incoherent averaging %%%
if ~exist('M_incoherent','var')
    M = 4*N;
else
    M = M_incoherent;
end
disp(['Incoherently averaging ' num2str(M) ' traces'])
multi_looked = zeros(nsamples, n_traces-N-M);
for i = 1:n_traces-N-M % for each moving average i
    multi_looked(:,i) = 1/M*sum(abs(unfocused_SAR(:,i:i+M-1)).^2, 2);
    % add trace j's contribution to moving average i using traces from SAR i up
    % to SAR i+M
end
    
end
