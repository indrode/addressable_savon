require "spec_helper"

describe AddressableSavon::SOAP do

  it "contains the SOAP namespace for each supported SOAP version" do
    AddressableSavon::SOAP::Versions.each do |soap_version|
      AddressableSavon::SOAP::Namespace[soap_version].should be_a(String)
      AddressableSavon::SOAP::Namespace[soap_version].should_not be_empty
    end
  end

  it "contains a Rage of supported SOAP versions" do
    AddressableSavon::SOAP::Versions.should == (1..2)
  end

end
