require "nhttpi"

module AddressableSavon
  module WSDL

    # = AddressableSavon::WSDL::Request
    #
    # Executes WSDL requests.
    class Request

      # Expects an <tt>NHTTPI::Request</tt> to execute a WSDL request
      # and returns the response.
      def self.execute(request)
        new(request).response
      end

      # Expects an <tt>NHTTPI::Request</tt>.
      def initialize(request)
        self.request = request
      end

      # Accessor for the <tt>NHTTPI::Request</tt>.
      attr_accessor :request

      # Executes the request and returns the response.
      def response
        @response ||= with_logging { NHTTPI.get request }
      end

    private

      # Logs the HTTP request and yields to a given +block+.
      def with_logging
        AddressableSavon.log "----"
        AddressableSavon.log "WSDL request: #{request.url}"
        AddressableSavon.log "Using :#{request.auth.type} authentication" if request.auth?
        yield
      end

    end
  end
end
