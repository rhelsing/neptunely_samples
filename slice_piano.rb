#!/usr/bin/env ruby
require 'json'

# Sample slicer
# Slices input file into individual samples based on configurable parameters.
# Assumes recording was done on a click track with one note per 4 beats,
# cycling through notes low-to-high within each velocity layer.
#
# Usage:
#   ruby slice_piano.rb <input_file> <bpm> <velocity_layers> <notes> [octave_start] [octave_end]
#
# Parameters:
#   input_file       - source audio file (mp3, wav, etc.)
#   bpm              - tempo of recording (determines segment length: 4 beats)
#   velocity_layers  - number of velocity layers (evenly divides 0-127)
#   notes            - space-separated note names in quotes (use 's' for sharp, e.g., 'ds' for D#)
#   octave_start     - starting octave (default: 0)
#   octave_end       - ending octave (default: 6)
#
# Output:
#   Creates folder named after input file (without extension)
#   Files named: <note><octave>_v<low>-<high>.mp3
#   Each sample has 0.05s attack, fade out starting at 3/4 through
#   Generates index.json with notes array and velocityRanges array
#
# Examples:
#
#   1. Piano with minor-third sampling (A, C, D#, F#), octaves 0-6, 3 velocities, 50 BPM:
#
#      ruby slice_piano.rb piano_felt.mp3 50 3 'a c ds fs' 0 6
#
#      Result: 84 samples (4 notes × 7 octaves × 3 velocities)
#      Segment length: 4.8s (60/50 × 4 beats)
#      Velocity ranges: v0-42, v43-84, v85-127
#      Files: piano_felt/a0_v0-42.mp3, piano_felt/c0_v0-42.mp3, ...
#
#   2. Full chromatic sampling (A-G), octaves 2-5, 5 velocities, 30 BPM:
#
#      ruby slice_piano.rb strings.mp3 30 5 'a b c d e f g' 2 5
#
#      Result: 140 samples (7 notes × 4 octaves × 5 velocities)
#      Segment length: 8.0s (60/30 × 4 beats)
#      Velocity ranges: v0-25, v26-50, v51-76, v77-101, v102-127
#      Files: strings/a2_v0-25.mp3, strings/b2_v0-25.mp3, ...
#
#   3. Single velocity layer, whole-tone sampling, octaves 3-6, 60 BPM:
#
#      ruby slice_piano.rb bells.wav 60 1 'c d e fs gs as' 3 6
#
#      Result: 24 samples (6 notes × 4 octaves × 1 velocity)
#      Segment length: 4.0s (60/60 × 4 beats)
#      Velocity range: v0-127
#      Files: bells/c3_v0-127.mp3, bells/d3_v0-127.mp3, ...

if ARGV.size < 4
  puts "Usage: ruby slice_piano.rb <input_file> <bpm> <velocity_layers> <notes> [octave_start] [octave_end]"
  puts ""
  puts "  input_file:      audio file to slice"
  puts "  bpm:             tempo (determines segment length: 4 beats)"
  puts "  velocity_layers: number of velocity layers"
  puts "  notes:           space-separated notes in quotes, e.g., 'a c ds fs'"
  puts "  octave_start:    starting octave (default: 0)"
  puts "  octave_end:      ending octave (default: 6)"
  puts ""
  puts "Example: ruby slice_piano.rb piano_felt.mp3 50 3 'a c ds fs' 0 6"
  exit 1
end

INPUT_FILE = ARGV[0]
BPM = ARGV[1].to_f
VELOCITY_LAYERS = ARGV[2].to_i
NOTES = ARGV[3].split
OCTAVE_START = (ARGV[4] || 0).to_i
OCTAVE_END = (ARGV[5] || 6).to_i

OUTPUT_DIR = File.basename(INPUT_FILE, ".*")
SEGMENT_DURATION = (60.0 / BPM) * 4  # 4 beats per segment
ATTACK_TIME = 0.05
FADE_START = SEGMENT_DURATION * 0.75  # 3/4 through
FADE_DURATION = SEGMENT_DURATION * 0.25  # remaining 1/4

OCTAVES = (OCTAVE_START..OCTAVE_END).to_a

# Generate even velocity ranges based on layer count
def velocity_ranges(layers)
  step = 128.0 / layers
  layers.times.map do |i|
    low = (i * step).round
    high = ((i + 1) * step - 1).round
    high = 127 if i == layers - 1  # ensure last range ends at 127
    "v#{low}-#{high}"
  end
end

VELOCITY_RANGES = velocity_ranges(VELOCITY_LAYERS)

# Create output directory
Dir.mkdir(OUTPUT_DIR) unless Dir.exist?(OUTPUT_DIR)

TOTAL_SAMPLES = NOTES.size * OCTAVES.size * VELOCITY_RANGES.size
segment_index = 0

VELOCITY_RANGES.each do |velocity|
  OCTAVES.each do |octave|
    NOTES.each do |note|
      start_time = segment_index * SEGMENT_DURATION
      output_file = "#{OUTPUT_DIR}/#{note}#{octave}_#{velocity}.mp3"

      # ffmpeg command with fade in (attack) and fade out
      cmd = [
        "ffmpeg", "-y",
        "-ss", start_time.to_s,
        "-i", INPUT_FILE,
        "-t", SEGMENT_DURATION.to_s,
        "-af", "afade=t=in:st=0:d=#{ATTACK_TIME},afade=t=out:st=#{FADE_START}:d=#{FADE_DURATION}",
        "-q:a", "2",
        output_file
      ]

      puts "Extracting #{output_file} (segment #{segment_index + 1}/#{TOTAL_SAMPLES}, start: #{start_time.round(3)}s)"
      system(*cmd, out: File::NULL, err: File::NULL)

      segment_index += 1
    end
  end
end

puts "\nDone! Extracted #{segment_index} samples to #{OUTPUT_DIR}/"

# Generate index.json
# Notes sorted by note name, then octave (matching big_piano format)
all_notes = NOTES.flat_map { |note| OCTAVES.map { |oct| "#{note}#{oct}" } }
# Velocity ranges without "v" prefix
json_velocity_ranges = VELOCITY_RANGES.map { |v| v.sub("v", "") }

index = {
  notes: all_notes,
  velocityRanges: json_velocity_ranges
}

File.write("#{OUTPUT_DIR}/index.json", JSON.pretty_generate(index))
puts "Generated #{OUTPUT_DIR}/index.json"
