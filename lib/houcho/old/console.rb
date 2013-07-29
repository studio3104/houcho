module Houcho
  module Console
    module_function

    def puts_details(e, indentsize = 0, cnt = 1)
      case e
      when Array
        e.sort.each.with_index(1) do |v, i|
          (indentsize-1).times {print '   '}
          print i != e.size ? '├─ ' : '└─ '
          puts v
        end
        puts ''
      when Hash
        e.each do |k,v|
          if indentsize != 0
            (indentsize).times {print '   '}
          end
          title = k.color(0,255,0)
          title = '[' + k.color(219,112,147) + ']' if indentsize == 0
          puts title
          puts_details(v, indentsize+1, cnt+1)
        end
      end
    end
  end
end
