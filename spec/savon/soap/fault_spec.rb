require "spec_helper"

describe AddressableSavon::SOAP::Fault do
  let(:soap_fault) { AddressableSavon::SOAP::Fault.new new_response(:body => Fixture.response(:soap_fault)) }
  let(:soap_fault2) { AddressableSavon::SOAP::Fault.new new_response(:body => Fixture.response(:soap_fault12)) }
  let(:another_soap_fault) { AddressableSavon::SOAP::Fault.new new_response(:body => Fixture.response(:another_soap_fault)) }
  let(:no_fault) { AddressableSavon::SOAP::Fault.new new_response }

  it "is a AddressableSavon::Error" do
    AddressableSavon::SOAP::Fault.should < AddressableSavon::Error
  end

  describe "#http" do
    it "returns the HTTPI::Response" do
      soap_fault.http.should be_an(HTTPI::Response)
    end
  end

  describe "#present?" do
    it "returns true if the HTTP response contains a SOAP 1.1 fault" do
      soap_fault.should be_present
    end

    it "returns true if the HTTP response contains a SOAP 1.2 fault" do
      soap_fault2.should be_present
    end

    it "returns true if the HTTP response contains a SOAP fault with different namespaces" do
      another_soap_fault.should be_present
    end

    it "returns false unless the HTTP response contains a SOAP fault" do
      no_fault.should_not be_present
    end
  end

  [:message, :to_s].each do |method|
    describe "##{method}" do
      it "returns an empty String unless a SOAP fault is present" do
        no_fault.send(method).should == ""
      end

      it "returns a SOAP 1.1 fault message" do
        soap_fault.send(method).should == "(soap:Server) Fault occurred while processing."
      end

      it "returns a SOAP 1.2 fault message" do
        soap_fault2.send(method).should == "(soap:Sender) Sender Timeout"
      end

      it "returns a SOAP fault message (with different namespaces)" do
        another_soap_fault.send(method).should == "(ERR_NO_SESSION) Wrong session message"
      end
    end
  end

  describe "#to_hash" do
    it "returns the SOAP response as a Hash unless a SOAP fault is present" do
      no_fault.to_hash[:authenticate_response][:return][:success].should be_true
    end

    it "returns a SOAP 1.1 fault as a Hash" do
      soap_fault.to_hash.should == {
        :fault => {
          :faultstring => "Fault occurred while processing.",
          :faultcode   => "soap:Server"
        }
      }
    end

    it "returns a SOAP 1.2 fault as a Hash" do
      soap_fault2.to_hash.should == {
        :fault => {
          :detail => { :max_time => "P5M" },
          :reason => { :text => "Sender Timeout" },
          :code   => { :value => "soap:Sender", :subcode => { :value => "m:MessageTimeout" } }
        }
      }
    end
  end

  def new_response(options = {})
    defaults = { :code => 500, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options

    HTTPI::Response.new response[:code], response[:headers], response[:body]
  end

end
