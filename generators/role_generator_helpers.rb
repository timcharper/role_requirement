module RoleGeneratorHelpers
  def insert_content_after(filename, regexp, content_for_insertion, options = {})
    content = File.read(filename)
    options[:unless] ||= lambda {false }
    # already have the function?  Don't generate it twice
    unless options[:unless].call(content)
      # find the line that has the model declaration
      lines = content.split("\n")
      found_line = nil
      
      0.upto(lines.length-1) {|line_number| 
        found_line = line_number if regexp.match(lines[line_number])
      }
      if found_line
        # insert the rest of these lines after the found line
        lines.insert(found_line+1, content_for_insertion)
        content = lines * "\n"
        
        File.open(filename, "w") {|f| f.puts content }
        return true
      end
    else
      return false
    end
  end
  
  
end