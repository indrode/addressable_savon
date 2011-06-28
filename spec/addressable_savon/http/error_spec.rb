require "spec_helper"

describe AddressableSavon::HTTP::Error do
  let(:http_error) { AddressableSavon::HTTP::Error.new new_response(:code => 404, :body => "Not Found") }
  let(:no_error) { AddressableSavon::HTTP::Error.new new_response }

  it "be a AddressableSavon::Error" do
    AddressableSavon::HTTP::Error.should < AddressableSavon::Error
  end

  describe "#http" do
    it "returns the NHTTPI::Response" do
      http_error.http.should be_an(NHTTPI::Response)
    end
  end

  describe "#present?" do
    it "returns true if there was an HTTP error" do
      http_error.should be_present
    end

    it "returns false unless there was an HTTP error" do
      no_error.should_not be_present
    end
  end

  [:message, :to_s].each do |method|
    describe "##{method}" do
      it "returns an empty String unless an HTTP error is present" do
        no_error.send(method).should == ""
      end

      it "returns the HTTP error message" do
        http_error.send(method).should == "HTTP error (404): Not Found"
      end
    end
  end

  describe "#to_hash" do
    it "returns the HTTP response details as a Hash" do
      http_error.to_hash.should == { :code => 404, :headers => {}, :body => "Not Found" }
    end
  end

  def new_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options

    NHTTPI::Response.new response[:code], response[:headers], response[:body]
  end

end
