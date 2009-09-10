require File.expand_path(File.dirname(__FILE__) + '/test_helper.rb')

class TransactionWrappedTest < Test::Unit::TestCase
  
  # simulate use_transactional_fixtures = true 
  #    by opening a transaction in setup and rolling it back in teardown
  # but also call adapt_for_transactional_test!
  #    so that commit_callback works in a transactional test in the same way that it works in product
  #
  # essentially, this is a test of adapt_for_transactional_test! which allows you to test things
  # that use commit_callback in tests that are transaction wrapped
  
  def setup
    ActiveRecord::Base.connection.increment_open_transactions
    ActiveRecord::Base.connection.transaction_joinable = false
    ActiveRecord::Base.connection.begin_db_transaction
  end
  
  def teardown
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
    #clear any created after_save callback
    Carrot.class_eval do
      @after_save_callbacks = nil
    end
  end
  
  #this test needs to run first  
  def test_a_transaction_interferes_without_adaption
    @callback_ran = false
    c = Carrot.new(:color => "orange")
    Carrot.after_save do |carrot|
      carrot.commit_callback do
        @callback_ran = true
      end
    end
    c.save!
    assert !@callback_ran    
  end
  
  def test_b_adapt_for_transactional_test
    CommitCallback.adapt_for_transactional_test!(ActiveRecord::Base.connection)

    @callback_ran = false
    c = Carrot.new(:color => "orange")
    Carrot.after_save do |carrot|
      carrot.commit_callback do
        @callback_ran = true
      end
    end
    c.save!
    assert @callback_ran
  end
  
  def test_c_adapted_rollback
    CommitCallback.adapt_for_transactional_test!(ActiveRecord::Base.connection)

    c = Carrot.new(:color => "orange")
    Carrot.after_save do |carrot|
      carrot.commit_callback do
        fetch_in_seperate_transaction(c.id)
      end
      raise "fail"
    end
    assert_raises(RuntimeError) do
      c.save!
    end
    assert_equal([], c.connection.commit_callbacks)
  end
  
  
end
