function [grayscale_sequence] = sequence_grayscale(sequence)

cache_directory = fullfile(get_global_variable('directory'), 'cache', 'grayscale', sequence.name);

mkpath(cache_directory);

cache_groundtruth = fullfile(cache_directory, 'groundtruth.txt');

sequence_groundtruth = fullfile(sequence.directory, 'groundtruth.txt');

if file_newer_than(cache_groundtruth, sequence_groundtruth)
    grayscale_sequence = create_sequence(cache_directory, 'name', sequence.name);
    grayscale_sequence.labels.names = sequence.labels.names;
    grayscale_sequence.labels.data = sequence.labels.data;
    return;
end;

print_debug('Generating cached grayscale sequence ''%s''...', sequence.name);

for i = 1:sequence.length
    
    color_image = imread(get_image(sequence, i));
    
    gray_image = repmat(rgb2gray(color_image), [1 1 3]);
    
    imwrite(gray_image, fullfile(cache_directory, sprintf('%08d.jpg', i)));
    
end;

write_trajectory(cache_groundtruth, sequence.groundtruth);

grayscale_sequence = create_sequence(cache_directory, 'name', sequence.name);

grayscale_sequence.labels.names = sequence.labels.names;
grayscale_sequence.labels.data = sequence.labels.data;

