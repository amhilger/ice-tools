BW = 10e6; %chirp bandwidth, Hz
T = 4e-6; %chirp length, s
K = BW/T; % chirp slope, [1/s^2]
f_c = 150e6; %carrier frequency, Hz
t_c = f_c/K; %time of zero-frequency given carrier frequency, s
f_samp = 22e6; %sampling rate in Hertz
A_max = 0.2551; %maximum abruptness
D_r = 10;% number of samples in first return, typical case

t = -T:1/f_samp:T; %time relative to t_o + t_c, sampled 
s_out = K*T*exp(-1j*2*pi*K*t_c*t) .* sinc(K*T*t);
idx_0 = (length(t)+1)/2;
s_max = 10*log10(s_out(idx_0)); %maximum power
s_agg = 10*log10( sum( s_out(idx_0 - D_r : idx_0 + D_r) ) );
A_nonoise = 10^(0.1*(s_max-s_agg));

%blackman windowing
% black = blackman((length(s_out)-1)/2)';
% s_win = fftshift(ifft(fft(fftshift(black)).*fft(s_out)));

%A_ma


plot_idx = idx_0 - 2*D_r : idx_0 + 2*D_r;
snr = 0:2:32;

num_trials = 1000;
A = zeros(length(snr), num_trials);



close(figure(1))
for i = 1:length(snr)
    for j = 1:num_trials
        s_noise = s_out + wgn(1, length(s_out), s_max - snr(i)).^2;
        
        s_det = real(s_noise).^2 + imag(s_noise).^2;

        P_agg = 10*log10(sum(s_det(idx_0 - D_r : idx_0 + D_r)));
        P_max = 10*log10(s_det(idx_0));
        A(i,j) = 10^(0.1*(P_max - P_agg));

        % subplot(211); plot(t(plot_idx), abs(s_out(plot_idx))); 
        % hold on;      plot(t(plot_idx), abs(s_noise(plot_idx)));
        if j == 1 && mod(i,4) == 3 
            figure(1) 
            plot(t(plot_idx), 10*log10(abs(s_det(plot_idx))) - 100);
            hold on;  
        end
    end
end
figure(1); legend('SNR = 4', 'SNR = 12', 'SNR = 20', 'SNR = 32')
xlabel('time, s'), ylabel('Power, dB')

figure(2); plot(snr, mean(A,2) / mean(A(end,:)) )
xlabel('SNR, dB'); ylabel('Peakiness')

