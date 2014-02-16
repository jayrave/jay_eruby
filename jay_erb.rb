module JERuby
  require 'json'
  require 'ostruct'

  module_function

  @line_parser = /(?<pre_ruby>.*)<\*(?<ruby>.*)\*>(?<post_ruby>.*)/
  @ruby_tag = /<\*(?<ruby>.*)\*>/
  @buffer = ''
  @loop_count = 0

  def json_to_hash(data_file)
    JSON.parse File.read data_file
  end

  def generate_html(erb_file, data_file)
    @template_data = json_to_hash data_file
    run_file_through_engine erb_file
  end

  def run_file_through_engine(erb_file)
    output = File.open 'jay_output', 'w'
    file = File.read erb_file
     file.each_line do |line|
      case contains_ruby?(line)
      when 'no'
        out = line
      when 'yes, normal'
        out = run_line_through_engine(line, false)
      when 'yes, loop'
        out = run_line_through_engine(line, true)
      end
      output.puts out
    end
    puts output
  end   

  def contains_ruby?(line)
    m = line.match @ruby_tag
    if m.nil?
      return 'no'
    else
      if m[:ruby].include? 'EACH'
        return 'yes, loop'
      else
        return 'yes, normal'
      end
    end
  end

  def run_line_through_engine(line, contains_loop)
    add_to_loop_count if contains_loop
    line_match = line.match @line_parser    
      
      ruby_output = get_data line_match[:ruby]
      "#{line_match[:pre_ruby]} #{ruby_output} #{line_match[:post_ruby]}" 
    end
  end

  def 

  def get_data(ruby)
    keys = ruby.split"."
    keys = keys.map do |key| 
      k = key.gsub ' ', ''
      "['#{k}']"
    end
    ans = keys.join('')
    eval "@template_data#{ans}"
  end

  def write_to_file?
    return true if @loop_count == 0
    return false
  end

  def add_to_loop_count
    @loop_count = @loop_count + 1
  end

end

JERuby.generate_html 'asdf', 'data.json'