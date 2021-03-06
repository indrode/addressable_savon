require "spec_helper"

describe AddressableSavon::Client do
  let(:client) { AddressableSavon::Client.new Endpoint.wsdl }

  describe ".new" do
    context "called with a String" do
      it "sets the WSDL document" do
        wsdl = "http://example.com/UserService?wsdl"
        client = AddressableSavon::Client.new wsdl
        client.wsdl.instance_variable_get("@document").should == wsdl
      end
    end

    context "called with a block expecting one argument" do
      it "yields the client instance" do
        AddressableSavon::Client.new { |client| client.should be_a(AddressableSavon::Client) }
      end
    end

    context "called with a block expecting no arguments" do
      it "lets you access the WSDL object" do
        AddressableSavon::Client.new { wsdl.should be_a(AddressableSavon::WSDL::Document) }
      end

      it "lets you access the HTTP object" do
        AddressableSavon::Client.new { http.should be_an(NHTTPI::Request) }
      end

      it "lets you access the WSSE object" do
        AddressableSavon::Client.new { wsse.should be_a(AddressableSavon::WSSE) }
      end
    end
  end

  describe "#wsdl" do
    it "returns the AddressableSavon::WSDL::Document" do
      client.wsdl.should be_a(AddressableSavon::WSDL::Document)
    end

    it "memoizes the object" do
      client.wsdl.should equal(client.wsdl)
    end
  end

  describe "#http" do
    it "returns the NHTTPI::Request" do
      client.http.should be_an(NHTTPI::Request)
    end

    it "memoizes the object" do
      client.http.should equal(client.http)
    end
  end

  describe "#wsse" do
    it "returns the AddressableSavon::WSSE object" do
      client.wsse.should be_a(AddressableSavon::WSSE)
    end

    it "memoizes the object" do
      client.wsse.should equal(client.wsse)
    end
  end

  describe "#request" do
    before do
      NHTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:authentication)))
      NHTTPI.stubs(:post).returns(new_response)
    end

    context "called without any arguments" do
      it "raises an ArgumentError" do
        message = "Expected to receive at least one argument"
        expect { client.request }.to raise_error(ArgumentError, message)
      end
    end

    context "called with a single argument (Symbol)" do
      it "sets the input tag to result in <getUser>" do
        client.request(:get_user) { soap.input.should == [:getUser, {}] }
      end

      it "sets the target namespace with the default identifier" do
        namespace = 'xmlns:wsdl="http://v1_0.ws.auth.order.example.com/"'
        NHTTPI::Request.any_instance.expects(:body=).with { |value| value.include? namespace }

        client.request :get_user
      end

      it "does not set the target namespace if soap.namespace was set to nil" do
        namespace = 'wsdl="http://v1_0.ws.auth.order.example.com/"'
        NHTTPI::Request.any_instance.expects(:body=).with { |value| !value.include?(namespace) }

        client.request(:get_user) { soap.namespace = nil }
      end
    end

    context "called with a single argument (String)" do
      it "sets the input tag to result in <get_user>" do
        client.request("get_user") { soap.input.should == [:get_user, {}] }
      end
    end

    context "called with a Symbol and a Hash" do
      it "sets the input tag to result in <getUser active='true'>" do
        client.request(:get_user, :active => true) { soap.input.should == [:getUser, { :active => true }] }
      end
    end

    context "called with two Symbols" do
      it "sets the input tag to result in <wsdl:getUser>" do
        client.request(:v1, :get_user) { soap.input.should == [:v1, :getUser, {}] }
      end

      it "sets the target namespace with the given identifier" do
        namespace = 'xmlns:v1="http://v1_0.ws.auth.order.example.com/"'
        NHTTPI::Request.any_instance.expects(:body=).with { |value| value.include? namespace }

        client.request :v1, :get_user
      end

      it "does not set the target namespace if soap.namespace was set to nil" do
        namespace = 'xmlns:v1="http://v1_0.ws.auth.order.example.com/"'
        NHTTPI::Request.any_instance.expects(:body=).with { |value| !value.include?(namespace) }

        client.request(:v1, :get_user) { soap.namespace = nil }
      end
    end

    context "called with two Symbols and a Hash" do
      it "sets the input tag to result in <wsdl:getUser active='true'>" do
        client.request(:wsdl, :get_user, :active => true) { soap.input.should == [:wsdl, :getUser, { :active => true }] }
      end
    end

    context "called with a block expecting one argument" do
      it "yields the client instance" do
        client.request(:authenticate) { |client| client.should be_a(AddressableSavon::Client) }
      end
    end

    context "called with a block expecting no arguments" do
      it "lets you access the SOAP object" do
        client.request(:authenticate) { soap.should be_a(AddressableSavon::SOAP::XML) }
      end

      it "lets you access the HTTP object" do
        client.request(:authenticate) { http.should be_an(NHTTPI::Request) }
      end

      it "lets you access the WSSE object" do
        client.request(:authenticate) { wsse.should be_a(AddressableSavon::WSSE) }
      end

      it "lets you access the WSDL object" do
        client.request(:authenticate) { wsdl.should be_a(AddressableSavon::WSDL::Document) }
      end
    end

    context "called with a block expecting more than one argument" do
      it "raises an ArgumentError" do
        message = "Expected a block with an arity of either 0 or 1"
        expect { client.request(:authenticate) { |one, two| } }.to raise_error(ArgumentError, message)
      end
    end

    context "called with a Hash containing a :body attribute" do
      it "uses the value to set the SOAP body" do
        AddressableSavon::SOAP::XML.any_instance.expects(:body=).with(:user => "me", :pass => "secret")
        client.request(:authenticate, :body => { :user => "me", :pass => "secret" })
      end
    end

    it "by default does not set the Cookie header for the next request" do
      client.http.headers.expects(:[]=).with("Cookie", anything).never
      client.http.headers.stubs(:[]=).with("SOAPAction", '"authenticate"')
      client.http.headers.stubs(:[]=).with("Content-Type", "text/xml;charset=UTF-8")

      client.request :authenticate
    end

    context "with a Set-Cookie response header" do
      before do
        NHTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:authentication)))
        NHTTPI.stubs(:post).returns(new_response(:headers => { "Set-Cookie" => "user:mac" }))
      end

      it "sets the Cookie header for the next request" do
        client.http.headers.expects(:[]=).with("Cookie", "user:mac")
        client.http.headers.stubs(:[]=).with("SOAPAction", '"authenticate"')
        client.http.headers.stubs(:[]=).with("Content-Type", "text/xml;charset=UTF-8")

        client.request :authenticate
      end
    end
  end

  context "with a remote WSDL document" do
    let(:client) { AddressableSavon::Client.new Endpoint.wsdl }
    before { NHTTPI.expects(:get).returns(new_response(:body => Fixture.wsdl(:authentication))) }

    it "returns a list of available SOAP actions" do
      client.wsdl.soap_actions.should == [:authenticate]
    end

    it "adds a SOAPAction header containing the SOAP action name" do
      NHTTPI.stubs(:post).returns(new_response)

      client.request :authenticate do
        http.headers["SOAPAction"].should == %{"authenticate"}
      end
    end

    it "executes SOAP requests and returns the response" do
      NHTTPI.expects(:post).returns(new_response)
      response = client.request(:authenticate)

      response.should be_a(AddressableSavon::SOAP::Response)
      response.to_xml.should == Fixture.response(:authentication)
    end
  end

  context "with a local WSDL document" do
    let(:client) { AddressableSavon::Client.new "spec/fixtures/wsdl/authentication.xml" }

    before { NHTTPI.expects(:get).never }

    it "returns a list of available SOAP actions" do
      client.wsdl.soap_actions.should == [:authenticate]
    end

    it "adds a SOAPAction header containing the SOAP action name" do
      NHTTPI.stubs(:post).returns(new_response)

      client.request :authenticate do
        http.headers["SOAPAction"].should == %{"authenticate"}
      end
    end

    it "gets the value of #element_form_default from the WSDL" do
      NHTTPI.stubs(:post).returns(new_response)
      AddressableSavon::WSDL::Document.any_instance.expects(:element_form_default).returns(:qualified)

      client.request :authenticate
    end

    it "executes SOAP requests and returns the response" do
      NHTTPI.expects(:post).returns(new_response)
      response = client.request(:authenticate)

      response.should be_a(AddressableSavon::SOAP::Response)
      response.to_xml.should == Fixture.response(:authentication)
    end
  end

  context "when the WSDL specifies multiple namespaces" do
    before do
      NHTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:multiple_namespaces)))
      NHTTPI.stubs(:post).returns(new_response)
    end

    it "qualifies each element with the appropriate namespace" do
      NHTTPI::Request.any_instance.expects(:body=).with { |value|
        xml = Nokogiri::XML(value)
        title = xml.at_xpath(
          ".//actions:Save/actions:article/article:Title/text()",
          "article" => "http://example.com/article",
          "actions" => "http://example.com/actions").to_s
        author = xml.at_xpath(
          ".//actions:Save/actions:article/article:Author/text()",
          "article" => "http://example.com/article",
          "actions" => "http://example.com/actions").to_s
        title == "Hamlet" && author == "Shakespeare"
      }

      client.request :save do |c|
        c.soap.body = {:article => {"Title" => "Hamlet", "Author" => "Shakespeare"}}
      end
    end

    it "still sends nil as xsi:nil as in the non-namespaced case" do
      NHTTPI::Request.any_instance.expects(:body=).with { |value|
        xml = Nokogiri::XML(value)
        attribute = xml.at_xpath(".//article:Title/@xsi:nil",
          "xsi" => "http://www.w3.org/2001/XMLSchema-instance",
          "article" => "http://example.com/article").to_s
        attribute == "true"
      }

      client.request :save do |c|
        c.soap.body = {:article => {"Title" => nil}}
      end
    end

    it "translates between symbol :save and string 'Save'" do
      NHTTPI::Request.any_instance.expects(:body=).with { |value|
        xml = Nokogiri::XML(value)
        !!xml.at_xpath(".//actions:Save",
          "actions" => "http://example.com/actions")
      }

      client.request :save do |client|
        client.soap.body = {:article => {:title => "Hamlet", :author => "Shakespeare"}}
      end
    end

    it "qualifies Save with the appropriate namespace" do
      NHTTPI::Request.any_instance.expects(:body=).with { |value|
        xml = Nokogiri::XML(value)
        !!xml.at_xpath(".//actions:Save",
          "actions" => "http://example.com/actions")
      }

      client.request "Save" do |client|
        client.soap.body = {:article => {:title => "Hamlet", :author => "Shakespeare"}}
      end
    end
  end

  context "when the WSDL has a lowerCamel name" do
    before do
      NHTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:lower_camel)))
      NHTTPI.stubs(:post).returns(new_response)
    end

    it "appends namespace when name is specified explicitly" do
      NHTTPI::Request.any_instance.expects(:body=).with { |value|
        xml = Nokogiri::XML(value)
        !!xml.at_xpath(".//actions:Save/actions:lowerCamel",
          "actions" => "http://example.com/actions")
      }

      client.request "Save" do |client|
        client.soap.body = {'lowerCamel' => 'theValue'}
      end
    end

    it "still appends namespace when converting from symbol" do
      NHTTPI::Request.any_instance.expects(:body=).with { |value|
        xml = Nokogiri::XML(value)
        !!xml.at_xpath(".//actions:Save/actions:lowerCamel",
          "actions" => "http://example.com/actions")
      }

      client.request "Save" do |client|
        client.soap.body = {:lower_camel => 'theValue'}
      end
    end
  end

  context "with multiple types" do
    before do
      NHTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:multiple_types)))
      NHTTPI.stubs(:post).returns(new_response)
    end

    it "does not blow up" do
      NHTTPI::Request.any_instance.expects(:body=).with { |value|
        value.include?("Save")
      }

      client.request :save do |client|
        client.soap.body = {}
      end
    end
  end

  context "without a WSDL document" do
    let(:client) do
      AddressableSavon::Client.new do
        wsdl.endpoint = Endpoint.soap
        wsdl.namespace = "http://v1_0.ws.auth.order.example.com/"
      end
    end

    before { NHTTPI.expects(:get).never }

    it "raises an ArgumentError when trying to access the WSDL" do
      expect { client.wsdl.soap_actions }.to raise_error(ArgumentError)
    end

    it "adds a SOAPAction header containing the SOAP action name" do
      NHTTPI.stubs(:post).returns(new_response)

      client.request :authenticate do
        http.headers["SOAPAction"].should == %{"authenticate"}
      end
    end

    it "does not try to get the value of #element_form_default from the WSDL" do
      NHTTPI.stubs(:post).returns(new_response)
      AddressableSavon::WSDL::Document.any_instance.expects(:element_form_default).never

      client.request :authenticate
    end

    it "executes SOAP requests and returns the response" do
      NHTTPI.expects(:post).returns(new_response)
      response = client.request(:authenticate)

      response.should be_a(AddressableSavon::SOAP::Response)
      response.to_xml.should == Fixture.response(:authentication)
    end
  end

  context "when encountering a SOAP fault" do
    let(:client) do
      AddressableSavon::Client.new do
        wsdl.endpoint = Endpoint.soap
        wsdl.namespace = "http://v1_0.ws.auth.order.example.com/"
      end
    end

    before do
      response = new_response :code => 500, :body => Fixture.response(:soap_fault)
      NHTTPI::expects(:post).returns(response)
    end

    it "raises a AddressableSavon::SOAP::Fault" do
      expect { client.request :authenticate }.to raise_error(AddressableSavon::SOAP::Fault)
    end
  end

  context "when encountering an HTTP error" do
    let(:client) do
      AddressableSavon::Client.new do
        wsdl.endpoint = Endpoint.soap
        wsdl.namespace = "http://v1_0.ws.auth.order.example.com/"
      end
    end

    before { NHTTPI::expects(:post).returns(new_response(:code => 500)) }

    it "raises a AddressableSavon::HTTP::Error" do
      expect { client.request :authenticate }.to raise_error(AddressableSavon::HTTP::Error)
    end
  end

  def new_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options

    NHTTPI::Response.new response[:code], response[:headers], response[:body]
  end

end
