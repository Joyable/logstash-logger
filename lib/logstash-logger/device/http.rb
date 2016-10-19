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

        @queue = Queue.new

        Thread.new do
          loop do
            request = Net::HTTP::Post.new("/", {'Content-Type': 'application/json'})
            request.body = @queue.deq
            binding.pry
            @http.request(request)
          end
        end
      end

      def write_one(message)
        @queue.enq message
      end
    end
  end
end
