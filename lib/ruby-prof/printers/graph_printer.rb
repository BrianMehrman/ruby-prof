# encoding: utf-8

module RubyProf
  # Generates graph[link:files/examples/graph_txt.html] profile reports as text.
  # To use the graph printer:
  #
  #   result = RubyProf.profile do
  #     [code to profile]
  #   end
  #
  #   printer = RubyProf::GraphPrinter.new(result)
  #   printer.print(STDOUT, {})
  #
  # The constructor takes two arguments. See the README

  class GraphPrinter < AbstractPrinter
    PERCENTAGE_WIDTH = 8
    TIME_WIDTH = 10
    CALL_WIDTH = 17

    private

    def print_header(thread)
      @output << "Thread ID: #{thread.id}\n"
      @output << "Total Time: #{thread.top_method.total_time}\n"
      @output << "Sort by: #{sort_method}\n"
      @output << "\n"

      # 1 is for % sign
      @output << sprintf("%#{PERCENTAGE_WIDTH}s", "%total")
      @output << sprintf("%#{PERCENTAGE_WIDTH}s", "%self")
      @output << sprintf("%#{TIME_WIDTH}s", "total")
      @output << sprintf("%#{TIME_WIDTH}s", "self")
      @output << sprintf("%#{TIME_WIDTH}s", "wait")
      @output << sprintf("%#{TIME_WIDTH}s", "child")
      @output << sprintf("%#{CALL_WIDTH}s", "calls")
      @output << "    Name"
      @output << "\n"
    end

    def print_methods(thread)
      total_time = thread.top_method.total_time
      # Sort methods from longest to shortest total time
      methods = thread.methods.sort_by(&sort_method)

      # Print each method in total time order
      methods.reverse_each do |method|
        total_percentage = (method.total_time/total_time) * 100
        self_percentage = (method.self_time/total_time) * 100

        next if total_percentage < min_percent

        @output << "-" * 80 << "\n"

        print_parents(thread, method)

        # 1 is for % sign
        @output << sprintf("%#{PERCENTAGE_WIDTH-1}.2f\%", total_percentage)
        @output << sprintf("%#{PERCENTAGE_WIDTH-1}.2f\%", self_percentage)
        @output << sprintf("%#{TIME_WIDTH}.2f", method.total_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", method.self_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", method.wait_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", method.children_time)
        @output << sprintf("%#{CALL_WIDTH}i", method.called)
        @output << sprintf("     %s",  method.recursive? ? "*" : " ")
        @output << sprintf("%s", method_name(method))
        if print_file
          @output << sprintf("  %s:%s", method.source_file, method.line)
        end
        @output << "\n"

        print_children(method)
      end
    end

    def print_parents(thread, method)
      method.aggregate_parents.sort_by(&:total_time).each do |caller|
        next unless caller.parent
        @output << " " * 2 * PERCENTAGE_WIDTH
        @output << sprintf("%#{TIME_WIDTH}.2f", caller.total_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", caller.self_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", caller.wait_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", caller.children_time)

        call_called = "#{caller.called}/#{method.called}"
        @output << sprintf("%#{CALL_WIDTH}s", call_called)
        @output << sprintf("      %s", caller.parent.target.full_name)
        @output << "\n"
      end
    end

    def print_children(method)
      method.aggregate_children.sort_by(&:total_time).reverse.each do |child|
        # Get children method

        @output << " " * 2 * PERCENTAGE_WIDTH

        @output << sprintf("%#{TIME_WIDTH}.2f", child.total_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", child.self_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", child.wait_time)
        @output << sprintf("%#{TIME_WIDTH}.2f", child.children_time)

        call_called = "#{child.called}/#{child.target.called}"
        @output << sprintf("%#{CALL_WIDTH}s", call_called)
        @output << sprintf("      %s", child.target.full_name)
        @output << "\n"
      end
    end

    def print_footer(thread)
      @output << "\n"
      @output << "* in front of method name means it is recursively called\n"
    end
  end
end