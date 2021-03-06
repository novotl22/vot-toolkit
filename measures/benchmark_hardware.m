function [filename] = benchmark_hardware()

filename = fullfile(get_global_variable('directory'), 'results', 'performance.txt');

if exist(filename, 'file')
    print_debug('Skipping hardware performance benchmark');
    return;
end;

print_text('Performing hardware performance benchmark');

print_indent(1);

performance = struct('reading', NaN, ...
    'convolution_native', NaN, 'convolution_matlab', NaN, ...
    'nonlinear_native', NaN);

repetitions = 20;

temporary_dir = tempdir;

image_file = fullfile(temporary_dir, 'image.jpg');

print_debug('Performing IO image reading benchmark');

I = rand(600, 600);
imwrite(I, image_file);

tic;

for i = 1:repetitions
    imread(image_file);
end;

performance.reading = toc / repetitions;

delete(image_file);

print_debug('Performing native convolution filter benchmark');

I = rand(600, 600);
K = rand(30, 30);

tic;

for i = 1:repetitions
    benchmark_native('convolution', I, K);
end;

performance.convolution_native = toc / repetitions;

print_debug('Performing Matlab convolution filter benchmark');

I = rand(600, 600);
K = rand(30, 30);

tic;

for i = 1:repetitions
    conv2(I, K);
end;

performance.convolution_matlab = toc / repetitions;

print_debug('Performing native nonlinear max filter benchmark');

I = rand(600, 600);

tic;

for i = 1:repetitions
    benchmark_native('maxfilter', I, 20, 20);
end;

performance.nonlinear_native = toc / repetitions;

writestruct(filename, performance);

print_indent(-1);
