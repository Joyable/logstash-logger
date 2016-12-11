require 'net/http'
require 'net/https'

module LogStashLogger
  module Device

    class HTTP < Base
      DEFAULT_HOST = '0.0.0.0'

      attr_reader :host, :port

      def initialize(opts)
        super
        @port = opts[:port] || fail(ArgumentError, "Port is required")
        @host = opts[:host] || DEFAULT_HOST
        @http = Net::HTTP.new(@host, @port)
        @http.use_ssl = opts[:use_ssl] || opts[:ssl_enable]
        @ending = false

        @queue = Queue.new

        @log_thread = Thread.new do
          loop do
            message, time = @queue.deq
            request = Net::HTTP::Post.new('/', {'Content-Type': 'application/json'})

            # Try to match the fields provided by aptible's logdrain
            request.body = {
              '@timestamp': time.iso8601(3),
              app: 'joyable-rails',
              layer: 'app',
              log: message,
              service: 'joyable-rails-web', # TODO
              source: 'app',
              stream: 'stdout',
              time: time.iso8601(9),
              type: 'json'
            }.to_json
            @http.request(request)

            if @ending && @queue.empty?
              break
            end
          end
        end

        # Finish sending queued log message before closing rake / console
        at_exit do
          unless @queue.empty?
            puts "Waiting for log queue to empty..."
            @ending = true
            @log_thread.join
          end
        end
      end

      def write_one(message)
        @queue.enq [message, Time.current.utc]
      end
    end
  end
end

