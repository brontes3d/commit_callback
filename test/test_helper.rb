require 'rubygems'
require 'test/unit'
require 'activerecord'

#require this plugin
require File.join(File.dirname(__FILE__), "..", "init")

unless defined?(RAILS_ENV)
  RAILS_ENV = "test"
end

begin

  ActiveRecord::Base.establish_connection(
    :adapter  => "mysql", 
    :database => "commit_callback_test", 
    :username => "root")

  #load the database schema for this test
  load File.expand_path(File.dirname(__FILE__) + "/test_models/schema.rb")

  #require the mock models
  require File.expand_path(File.dirname(__FILE__) + '/test_models/models.rb')

rescue Mysql::Error => e
  puts "You need mysql to run these tests, to create the test database run:\n"+
       "mysqladmin create commit_callback_test -u root"
  exit(1)
end