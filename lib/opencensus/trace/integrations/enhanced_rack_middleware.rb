require 'opencensus'
require 'opencensus/trace/integrations/rack_middleware'

module OpenCensus
  module Trace
    module Integrations
      class EnhancedRackMiddleware < RackMiddleware
        UUID_PATTERN = /\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(\/|$)/
        ID_PATTERN = /\/[0-9]+(\/|$)/
        FILE_PATTERN = /[a-z0-9]{5,}\.(png|js)/
        RANDOM_PATTERN = /[a-z0-9]{16,}/

        private

        def get_path(env)
          path = "#{env['SCRIPT_NAME']}#{env['PATH_INFO']}"
          path = "/#{path}" unless path.start_with? '/'
          generalize_path(path)
        end

        def generalize_path(path)
          path
            .gsub(UUID_PATTERN, '/:uuid\\1')
            .gsub(ID_PATTERN, '/:id\\1')
            .gsub(FILE_PATTERN, 'some_file.\\1')
            .gsub(RANDOM_PATTERN, 'some_string\\1')
        end
      end
    end
  end
end
