require "nhttpi/request"
require "addressable_savon/soap/xml"
require "addressable_savon/soap/request"
require "addressable_savon/soap/response"
require "addressable_savon/wsdl/document"
require "addressable_savon/wsse"
require "addressable_savon/delegator"

module AddressableSavon

  # = AddressableSavon::Client
  #
  # The main interface for interacting with SOAP services.
  class Client
    include Delegator

    # Initializes the AddressableSavon::Client for a SOAP service. Accepts a +block+ which is either evaluated
    # in the context of +self+ or being called with +self+ if the block expects an argument.
    #
    # == Examples
    #
    #   # Using a remote WSDL
    #   client = AddressableSavon::Client.new { wsdl.document = "http://example.com/UserService?wsdl" }
    #
    #   # Using a local WSDL
    #   client = AddressableSavon::Client.new { wsdl.document = "../wsdl/user_service.xml" }
    #
    #   # Shortcut for setting the WSDL
    #   client = AddressableSavon::Client.new "http://example.com/UserService?wsdl"
    #
    #   # You can pass a block to use Savon without a WSDL by defining the
    #   # SOAP endpoint and the target namespace manually
    #   client = AddressableSavon::Client.new do
    #     wsdl.endpoint = "http://example.com/UserService"
    #     wsdl.namespace = "http://users.example.com"
    #   end
    def initialize(wsdl_document = nil, &block)
      wsdl.document = wsdl_document if wsdl_document
      process &block if block
      wsdl.request = http
    end

    # Returns the <tt>AddressableSavon::WSDL::Document</tt>.
    def wsdl
      @wsdl ||= WSDL::Document.new
    end

    # Returns the <tt>NHTTPI::Request</tt>.
    def http
      @http ||= NHTTPI::Request.new
    end

    # Returns the <tt>AddressableSavon::WSSE</tt>.
    def wsse
      @wsse ||= WSSE.new
    end

    # Returns the <tt>AddressableSavon::SOAP::XML</tt>. Notice, that this object is only available
    # in a block passed to <tt>AddressableSavon::Client#request</tt>. A new instance of this object
    # is created per SOAP request.
    def soap
      raise ArgumentError, "Expected to be called in a block passed to #request" unless @soap
      @soap
    end

    attr_writer :soap

    # Executes a SOAP request for a given SOAP action. Accepts a +block+ which is either evaluated
    # in the context of +self+ or being called with +self+ if the block expects an argument.
    #
    # == Examples
    #
    #   # Calls a "getUser" SOAP action with the SOAP body of "<userId>123</userId>"
    #   client.request(:get_user) { soap.body = { :user_id => 123 } }
    #
    #   # Namespaces the SOAP input tag with a given namespace: "<wsdl:GetUser>...</wsdl:GetUser>"
    #   client.request(:wsdl, "GetUser") { soap.body = { :user_id => 123 } }
    #
    #   # SOAP input tag with attributes: <getUser xmlns:wsdl="http://example.com">...</getUser>"
    #   client.request(:get_user, "xmlns:wsdl" => "http://example.com")
    def request(*args, &block)
      raise ArgumentError, "Expected to receive at least one argument" if args.empty?

      with_soap do
        preconfigure extract_options(args)
        process &block if block
        soap.wsse = wsse

        response = SOAP::Request.execute(http, soap)
        set_cookie response.http.headers
        response
      end
    end

  private

    # Handels setup and teardown of the +AddressableSavon::SOAP::XML+ instance.
    def with_soap(&block)
      self.soap = SOAP::XML.new
      response = yield
      self.soap = nil
      response
    end

    # Passes a cookie from the last request +headers+ to the next one.
    def set_cookie(headers)
      http.headers["Cookie"] = headers["Set-Cookie"] if headers["Set-Cookie"]
    end

    # Expects an Array of +args+ and returns an Array containing the namespace (might be +nil+),
    # the SOAP input and a Hash of attributes for the input tag (might be empty).
    def extract_options(args)
      attributes = Hash === args.last ? args.pop : {}
      namespace = args.size > 1 ? args.shift.to_sym : nil
      input = args.first

      [namespace, input, attributes]
    end

    # Expects and Array of +options+ and preconfigures the system.
    def preconfigure(options)
      soap.endpoint = wsdl.endpoint
      soap.namespace_identifier = options[0]
      soap.namespace = wsdl.namespace
      soap.element_form_default = wsdl.element_form_default if wsdl.present?
      soap.body = options[2].delete(:body)

      wsdl.type_namespaces.each do |path, uri|
        soap.use_namespace(path, uri)
      end

      wsdl.type_definitions.each do |path, type|
        soap.define_type(path, type)
      end

      set_soap_action options[1]
      set_soap_input *options
    end

    # Expects an +input+ and sets the +SOAPAction+ HTTP headers.
    def set_soap_action(input)
      soap_action = wsdl.soap_action input.to_sym
      #soap_action ||= Gyoku::XMLKey.create(input).to_sym
      #soap_action = :usageAuthRateChargeRequest
      #http.headers["SOAPAction"] = %{"#{soap_action}"}
    end

    # Expects a +namespace+, +input+ and +attributes+ and sets the SOAP input.
    def set_soap_input(namespace, input, attributes)
      new_input = wsdl.soap_input input.to_sym
      #new_input ||= Gyoku::XMLKey.create(input).to_sym      
      soap.input = [namespace, new_input, attributes].compact
    end

  end
end
