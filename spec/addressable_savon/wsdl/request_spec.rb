require "spec_helper"

describe AddressableSavon::WSDL::Request do
  let(:http_request) { NHTTPI::Request.new :url => Endpoint.wsdl }
  let(:request) { AddressableSavon::WSDL::Request.new http_request }

  describe ".execute" do
    it "executes a WSDL request and returns the response" do
      response = NHTTPI::Response.new 200, {}, Fixture.response(:authentication)
      NHTTPI.expects(:get).with(http_request).returns(response)
      AddressableSavon::WSDL::Request.execute(http_request).should == response
    end
  end

  describe "#response" do
    it "executes an HTTP GET request and returns the NHTTPI::Response" do
      response = NHTTPI::Response.new 200, {}, Fixture.response(:authentication)
      NHTTPI.expects(:get).with(http_request).returns(response)
      request.response.should == response
    end
  end

end
