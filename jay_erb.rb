module JERuby
  require 'json'
  require 'ostruct'

  module_function

  @erb_parser = /(?<pre_ruby>.*)<\*(?<ruby>.*)\*>(?<post_ruby>.*)/
  @ruby_tag = /<\*(?<ruby>.*)\*>/

  def json_to_hash
    JSON.parse File.read @data_file
  end

  def generate_html(erb_file, data_file)
    @data_file = data_file
    @erb_file = erb_file
    @template_data = json_to_hash
    run_file_through_engine 
  end

  def run_file_through_engine
    output = File.open 'jay_output', 'w'
    file = File.read @erb_file
     file.each_line do |line|
      out = contains_ruby?(line) ? run_line_through_engine(line) : line
      output.puts out
    end
    puts output
  end   

  def contains_ruby?(line)
    m = line.match @ruby_tag
    m ? (return true) : (return false)
  end

  def run_line_through_engine(line)
    line_match = line.match @erb_parser
    ruby_output = get_data line_match[:ruby]
    "#{line_match[:pre_ruby]} #{ruby_output} #{line_match[:post_ruby]}" 
  end

  def get_data(ruby)
    keys = ruby.split"."
    keys = keys.map do |key| 
      k = key.gsub ' ', ''
      "['#{k}']"
    end
    ans = keys.join('')
    eval "@template_data#{ans}"
  end

end

JERuby.generate_html 'asdf', 'data.json'