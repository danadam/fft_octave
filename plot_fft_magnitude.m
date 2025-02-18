#!/usr/bin/env octave
pkg load signal

% Based on https://holometer.fnal.gov/GH_FFT.pdf
%   Spectrum and spectral density estimation by the Discrete Fourier transform
%   (DFT), including a comprehensive list of window functions and some new
%   ﬂat-top windows.
% by G. Heinzel, A. Rüdiger and R. Schilling,

% >>>> User configuration

input_file = "audio.wav";
output_file = "spectrum.png";
fft_size = 2 * 1024;
width = 1000;
height = 500;
use_log_frequency_scale = true;

% >>>> Load an audio file

[X, Fs] = audioread(input_file);
if (columns(X) > 1)
    printf("The %s file has %d channels, using the first one.\n", input_file, columns(X));
    X = X(:,1);
endif

fft_size2 = fft_size / 2;
freqs = Fs * (0 : fft_size2) / fft_size;

% >>>> Select a window and overlap

win_coef = hanning(fft_size, "periodic");
win_overlap = 0.5;

% >>>> Calculate coefficients for scaling the FFT magnitude

win_s1 = sum(win_coef);
win_s2 = sum(win_coef .^ 2);
enbw = Fs * win_s2 / win_s1^2;

% >>>> Calculate FFT for each window, sum and scale

iter_cnt = 0;
start_pos = 1;
pos_offset = floor(fft_size * (1 - win_overlap));
mag2 = zeros(fft_size2 + 1, 1);
while (start_pos + fft_size - 1 <= length(X))
    iter_cnt += 1;
    windowed = X(start_pos:start_pos + fft_size - 1) .* win_coef;
    Y_all = fft(windowed);
    Y = Y_all(1 : fft_size2 + 1);
    Y = 2 * abs(Y).^2 / win_s1^2;

    mag2 += Y;
    start_pos += pos_offset;
endwhile
mag2 = mag2 / iter_cnt;
% The first and last components (DC and Nyquist frequency) are "special" in
% terms of scaling but we don't bother with them and just set to 0.
mag2(1) = 0;
mag2(end) = 0;
printf("data size = %d, window size = %d, did %d iterations\n", length(X), fft_size, iter_cnt);

% >>>> Convert to the desired units

% Convert from power spectrum in V_rms^2 to linear spectrum in V_peak
Y = sqrt(mag2) * sqrt(2);

% >>>> Plot the result

graphics_toolkit("qt");
warning("off", "Octave:negative-data-log-axis");

figure(1, "position", [9999, 9999, width, height]);

if (use_log_frequency_scale)
    semilogx(freqs, 20 * log10(Y));
    xlim([10 Fs/2]);
    set(gca, "xticklabel", {"10", "100", "1000", "10000"});
else
    plot(freqs, 20 * log10(Y));
    xlim([0 Fs/2]);
    set(gca, "xminortick", "on");
endif

grid on
title(["FFT " num2str(fft_size)]);
ylim([-130 0]);
xlabel("Hz");
ylabel("dBFS");

% >>>> Save the plot to the PNG file

print(output_file, "-dpng", ["-S" num2str(width) "," num2str(height)]);

pause(1)
waitfor(gcf);

