class Chef
  class Log
    # Intercept any output from minitest
    def self.puts(*a)
      if a.empty?
        self.output "\n"
      else 
        a.each do |m| 
          self.output "#{m}\n"
        end
      end
    end

    def self.print(*a)
      a.each do |m| 
        self.output m
      end
    end

    # Pass messages to chef::Log's standard output stream
    # Additionally log to STDOUT if not already doing so
    def self.output(message)  
      self << message
      if !self.logging_to_stdout?
        ios = IO.new STDOUT.fileno
        ios.write message
        ios.close
      end
    end

    # look deep into the bowels of Chef::Log to see if it is
    # logging to stdout or not
    # There _must_ be a better way of doing this :-/
    def self.logging_to_stdout?
      logdev = self.logger.instance_variable_get(:@logdev).instance_variable_get(:@dev)
      logdev == STDOUT
    end
  end
end
