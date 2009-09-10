$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'commit_callback'

ActiveRecord::Base.class_eval do
  include CommitCallback  
end