require File.expand_path(File.dirname(__FILE__) + '/test_helper.rb')

class CommitCallbackTest < Test::Unit::TestCase
  
  #suppose there is a background message processor that needs to know 
  #about new carrots so that it can peel them
  #if we send the message on after save, the carrot might not be created yet when it tries to peel it
  #if we send the message on a commit callback, 
  #   the message processor should always happen after the carrot is really created
  
  def teardown
    #clear any created after_save callback
    Carrot.class_eval do
      @after_save_callbacks = nil
    end
  end
  
  def test_that_after_save_isnt_enough
    @found_carrot = []
    c = Carrot.new(:color => "orange")
    Carrot.after_save do
      fetch_in_seperate_transaction(c.id)
    end
    c.save!
    assert_equal([], @found_carrot)
  end
  
  def test_that_commit_callback_works
    @found_carrot = []
    c = Carrot.new(:color => "orange")
    Carrot.after_save do |carrot|
      carrot.commit_callback do
        fetch_in_seperate_transaction(c.id)
      end
    end
    c.save!
    assert_equal([[c.id.to_s, "orange"]], @found_carrot)
    assert !@found_carrot.empty?
  end
  
  def test_rollback
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
  
  private
  
  def fetch_in_seperate_transaction(carrot_id)
    Carrot.connection_pool.with_connection do |conn|
      @found_carrot = conn.select_rows("Select * from carrots where id = #{carrot_id}");
    end
  end  
  
end
