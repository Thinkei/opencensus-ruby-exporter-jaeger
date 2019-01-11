require 'logger'

module Logging
  def default_logger
    Logging.logger
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
    @logger.level = ENV['LOG_LEVEL'] || Logger::INFO
    at_exit do
      @logger.close
    end
    @logger
  end

  def self.included(base)
    class << base
      def logger
        Logging.logger
      end
    end
  end
end
