require 'logger'

module Opencensus
  module Logging
    def logger
      Logging.logger
    end

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.included
      class << base
        def logger
          Logging.logger
        end
      end
    end
  end
end
