#This script implements the projection and transformation algorithm, presented in the Paper "Discovering Instance-Spanning Constraints from Process Execution Logs based on Classification Techniques" by Karolin Winter and Stefanie Rinderle-Ma (https://ieeexplore.ieee.org/document/8089866).
#It takes one *.xes file and an event attribute as input and produces one or several *.arff files. 
#The event attribute is used for dimension reduction, e.g. if there is more than one organizational resource (org:resource) in the log file, then one *.arff file per resource is produced. Otherwise the whole log is transferred into one *.arff file.

#!/usr/bin/ruby

require 'xes'
require 'xml/smart'
require 'set'
require 'rarff'
require 'optparse'

options = {}
OptionParser.new do |opt|
  opt.on('--data path to input data') { |o| options[:data] = o }
  opt.on('--results path to results directory') { |o| options[:results] = o }
end.parse!


if options.empty? || options.length() < 2
  puts "Please provide a path to your input data and a path to your results directory."
  exit
end

result_dir = options[:results]
Dir.mkdir(result_dir) unless File.directory?(result_dir)

if !File.file?(options[:data])
  puts "No file found."
  exit
end

file = File.new(options[:data])

puts "Which event attribute do you want to use for dimension reduction? (recommended: org:resource)"
attribute = false

until attribute do
  chosen_classifier = $stdin.gets.chomp        
  if File.readlines(file).grep(/#{chosen_classifier}/).size <= 0
    puts "Chosen attribute is not contained in the file.\nPlease try another attribute."
  else
    attribute = true
  end
end

file = XML::Smart.open(file)
file.register_namespace 'x', 'http://www.xes-standard.org/'

def convert(type)
  return "STRING"   if type == "string"
  return 'DATE "yyyy-MM-dd\'T\'HH:mm:ss.SSSZ"'     if type == "date"
  return "NUMERIC"  if type == "float"
  return "NUMERIC"  if type == "int"
  return "STRING"   if type == "boolean"
  return type
end

classifiers = Hash.new

file.find("//x:event").each do |e|

  clas = nil
  map = Hash.new("?")
  concepts = Hash.new

  e.children.each do |c|
    key = c.attributes["key"]
    val = c.attributes["value"]
    if key == chosen_classifier
      clas = val
      unless classifiers[val]
        classifiers[val] = Hash.new
        classifiers[val][:concepts] = Hash.new
        classifiers[val][:values] = Array.new
        classifiers[val][:map] = Hash.new("?")
      end
    end
    concepts[key] = c.qname.to_s
    map[key] = val
  end

  if clas 
    classifiers[clas][:concepts].merge!(concepts)
    classifiers[clas][:values] << map
  else
    puts "Warning got event without chosen classifier"
  end
end

classifiers.each do |classifier, hash|

  names = Set.new
  timestamps = Set.new

  concepts = hash[:concepts]
  values = hash[:values]

  values.each do |map|
    map.each do |key, val|
      if key == "concept:name"
        names << "\"#{val}\""
      elsif key == "time:timestamp"
        timestamps << "\"#{val}\""
      end
    end
  end

  relation = Rarff::Relation.new("#{classifier}")

  values.each do |map|
    line = Array.new
    concepts.each do |key, type|
      map[key] == "?" || convert(type) == "NUMERIC" ? line << map[key] : line << "\"#{map[key]}\""
    end
    relation.instances << line
  end

  concepts["concept:name"] = "{{#{names.to_a.join(', ')}}}"
  concepts["time:timestamp"] = "{{#{timestamps.to_a.join(', ')}}}"
  concepts.each do |key, type|
    relation.attributes << Rarff::Attribute.new("\"#{key}\"", convert(type))
  end

  File.write "#{result_dir}/#{classifier}.arff", relation.to_arff
  puts "Your file was saved to #{result_dir}/#{classifier}.arff"
end
