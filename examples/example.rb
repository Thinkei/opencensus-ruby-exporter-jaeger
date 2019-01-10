require 'sinatra/base'

class Example < Sinatra::Base
  get '/' do
    'Hello world'
  end

  get "/lengthy" do
    # Configure this Faraday connection with a middleware to trace outgoing
    # requests.
    conn = Faraday.new(url: "http://www.google.com") do |c|
      c.use OpenCensus::Trace::Integrations::FaradayMiddleware
      c.adapter Faraday.default_adapter
    end
    conn.get "/"

    # You may instrument your code to create custom spans for long-running
    # operations.
    OpenCensus::Trace.in_span "long task" do
      sleep rand
    end

    "Done!"
  end
end
