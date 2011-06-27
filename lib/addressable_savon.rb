require "addressable_savon/version"
require "addressable_savon/global"
require "addressable_savon/client"

module AddressableSavon
  extend Global

  def self.configure
    yield self if block_given?
  end

end