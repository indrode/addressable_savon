require "spec_helper"

describe AddressableSavon do

  describe ".configure" do
    around do |example|
      AddressableSavon.reset_config!
      example.run
      AddressableSavon.reset_config!
      AddressableSavon.log = false  # disable logging
    end

    describe "log" do
      it "defaults to true" do
        AddressableSavon.log?.should be_true
      end

      it "sets whether to log HTTP requests" do
        AddressableSavon.configure { |config| config.log = false }
        AddressableSavon.log?.should be_false
      end
    end

    describe "logger" do
      it "sets the logger to use" do
        MyLogger = Class.new
        AddressableSavon.configure { |config| config.logger = MyLogger }
        AddressableSavon.logger.should == MyLogger
      end

      it "defaults to Logger writing to STDOUT" do
        AddressableSavon.logger.should be_a(Logger)
      end
    end

    describe "log_level" do
      it "defaults to :debug" do
        AddressableSavon.log_level.should == :debug
      end

      it "sets the log level to use" do
        AddressableSavon.configure { |config| config.log_level = :info }
        AddressableSavon.log_level.should == :info
      end
    end

    describe "raise_errors" do
      it "defaults to true" do
        AddressableSavon.raise_errors?.should be_true
      end

      it "does not raise errors when disabled" do
        AddressableSavon.raise_errors = false
        AddressableSavon.raise_errors?.should be_false
      end
    end

    describe "soap_version" do
      it "defaults to SOAP 1.1" do
        AddressableSavon.soap_version.should == 1
      end

      it "returns 2 if set to SOAP 1.2" do
        AddressableSavon.soap_version = 2
        AddressableSavon.soap_version.should == 2
      end

      it "raises in case of an invalid version" do
        lambda { AddressableSavon.soap_version = 3 }.should raise_error(ArgumentError)
      end
    end

    describe "strip_namespaces" do
      it "defaults to true" do
        AddressableSavon.strip_namespaces?.should == true
      end

      it "does not strip namespaces when set to false" do
        AddressableSavon.strip_namespaces = false
        AddressableSavon.strip_namespaces?.should == false
      end
    end
  end

end
