module J

  require 'json'
  module_function
  @line_parser = /(?<pre_ruby>.*)<\*(?<ruby>.*)\*>(?<post_ruby>.*)/
  @ruby_tag = /<\*.*\*>/
  @data = []
  
  def generate_html(erb_file, data_file)
    @data[0] = JSON.parse File.read data_file
    lines = File.readlines erb_file
    output = to_html lines
    File.open('jay_output', 'w') { |f| f.write output.join }
  end

  def to_html(in_lines)
    max_relevant_index = @data.size - 1
    out_lines = []
    local_loop_count = 0
    buffer = []
    in_lines.each do |line|      
      if local_loop_count > 0
        if end_of_loop? line
          local_loop_count = local_loop_count - 1;
        elsif contains_loop? line
          local_loop_count = local_loop_count + 1;
        end
        buffer.push line

        if local_loop_count == 0
          buffer.delete_at -1
          first_line = buffer.delete_at 0
          first_line = first_line.split ' '
          new_key = first_line.delete_at -1
          iterable_hash_key = key_string first_line.delete_at -1
          iterable_hash = find_best_match_value iterable_hash_key, max_relevant_index
          iterable_hash.each do |new_value|
            @data[max_relevant_index + 1] = {}
            @data.last[new_key] = new_value
            out_lines.push to_html buffer
          end

          @data.delete_at -1
        end
      elsif contains_ruby? line
        if contains_loop? line
          local_loop_count = local_loop_count + 1
          buffer.push @line_match[:ruby]
        else
          out_lines.push handle_ruby_line 
        end
      else
        out_lines.push line 
      end
    end
    out_lines
  end

  def handle_ruby_line
    value = find_best_match_value
    return "#{@line_match[:pre_ruby]}#{value}#{@line_match[:post_ruby]}\n"
  end

  def find_best_match_value(key = key_string, max_relevant_index = -1)
    local_data = @data.slice 0..max_relevant_index
    local_data.reverse_each do |hash|
      begin
        value = eval "hash#{key}"
        next if value.nil?
        return value
      rescue NoMethodError 
        next
      end
    end
  end

  def key_string(input = @line_match[:ruby])
    keys = input.split'.'
    keys = keys.map do |k| 
      k.gsub!(/\s/, '')
      k = "['#{k}']"
    end
    keys.join
  end

  def contains_loop?(line)
    @line_match = line.match @line_parser
    return true if @line_match[:ruby].include? 'EACH'
    return false
  end

  def end_of_loop?(line)
    @line_match = line.match @line_parser 
    return true if @line_match[:ruby].include? 'ENDEACH'
    return false
  end

  def contains_ruby?(line)
    match = line.match @ruby_tag
    return true if match
    return false 
  end

end

J.generate_html 'asdf', 'data.json'