require 'logger'

module Logging
  def default_logger
    Logging.logger
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.included base
    class << base
      def logger
        Logging.logger
      end
    end
  end
end
