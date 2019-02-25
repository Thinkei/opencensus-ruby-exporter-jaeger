require 'opencensus'

module OpenCensus
  module Trace
    module Integrations
      ##
      # # Rack integration
      #
      # This is a middleware for Rack applications:
      #
      # * It wraps all incoming requests in a root span
      # * It exports the captured spans at the end of the request.
      #
      # Example:
      #
      #     require "opencensus/trace/integrations/rack_middleware"
      #
      #     use OpenCensus::Trace::Integrations::RackMiddleware
      #
      class EnhancedRackMiddleware
        ##
        # List of trace context formatters we use to parse the parent span
        # context.
        #
        # @private
        #
        AUTODETECTABLE_FORMATTERS = [
          Formatters::CloudTrace.new,
          Formatters::TraceContext.new
        ].freeze

        UUID_PATTERN = %r{/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(/|$)}.freeze
        ID_PATTERN = %r{/[0-9]+(/|$)}.freeze
        FILE_PATTERN = /[a-z0-9]{5,}\.(png|js|css)/.freeze
        RANDOM_PATTERN = /[a-z0-9]{16,}/.freeze

        ##
        # Create the Rack middleware.
        #
        # @param [#call] app Next item on the middleware stack
        # @param [#export] exporter The exported used to export captured spans
        #     at the end of the request. Optional: If omitted, uses the exporter
        #     in the current config.
        #
        def initialize(app, exporter: nil)
          @app = app
          @exporter = exporter || OpenCensus::Trace.config.exporter
        end

        ##
        # Run the Rack middleware.
        #
        # @param [Hash] env The rack environment
        # @return [Array] The rack response. An array with 3 elements: the HTTP
        #     response code, a Hash of the response headers, and the response
        #     body which must respond to `each`.
        #
        def call(env)
          formatter = AUTODETECTABLE_FORMATTERS.detect do |f|
            env.key? f.rack_header_name
          end
          if formatter
            context = formatter.deserialize env[formatter.rack_header_name]
          end

          Trace.start_request_trace \
            trace_context: context,
            same_process_as_parent: false do |span_context|
            begin
              Trace.in_span get_path(env) do |span|
                start_request span, env
                @app.call(env).tap do |response|
                  finish_request span, response
                end
              end
            ensure
              @exporter.export span_context.build_contained_spans
            end
          end
        end

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

        def get_host(env)
          env['HTTP_HOST'] || env['SERVER_NAME']
        end

        def start_request(span, env)
          span.kind = SpanBuilder::SERVER
          span.put_attribute 'http.host', get_host(env)
          span.put_attribute 'http.path', get_path(env)
          span.put_attribute 'http.method', env['REQUEST_METHOD'].to_s.upcase
          if env['HTTP_USER_AGENT']
            span.put_attribute 'http.user_agent', env['HTTP_USER_AGENT']
          end
        end

        def finish_request(span, response)
          if response.is_a?(::Array) && response.size == 3
            http_status = response[0]
            span.set_http_status http_status
            span.put_attribute 'http.status_code', http_status
          end
        end
      end
    end
  end
end
