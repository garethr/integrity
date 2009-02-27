$:.unshift File.dirname(__FILE__) + "/../lib", File.dirname(__FILE__),
  File.dirname(__FILE__) + "/../vendor/webrat/lib"

%w(test/unit
context
pending
matchy
storyteller
webrat/sinatra
rr
mocha
test/zentest_assertions
dm-sweatshop).each { |dependency|
  begin
    require dependency
  rescue LoadError
    puts "You're missing some gems required to run the tests."
    puts "Please run `rake test:install_dependencies`"
    puts "You'll probably need to run that command as root or with sudo."

    puts "Thanks :)"
    puts

    exit 1
  end
}

begin
  require "ruby-debug"
  require "redgreen"
rescue LoadError
end

require "integrity"
require "helpers/expectations"
require "helpers/fixtures"

module TestHelper
  def ignore_logs!
    Integrity.config[:log] = "/tmp/integrity.test.log"
  end
end

class Test::Unit::TestCase
  class << self
    alias_method :specify, :test
  end

  include RR::Adapters::TestUnit
  include Integrity
  include TestHelper

  before(:all) do
    DataMapper.setup(:default, "sqlite3::memory:")
  end

  before(:each) do
    RR.reset
    DataMapper.auto_migrate!
    Integrity.instance_variable_set(:@config, nil)

    repository(:default) do
      transaction = DataMapper::Transaction.new(repository)
      transaction.begin
      repository.adapter.push_transaction(transaction)
    end
  end

  after(:each) do
    repository(:default) do
      while repository.adapter.current_transaction
        repository.adapter.current_transaction.rollback
        repository.adapter.pop_transaction
      end
    end
  end
end
