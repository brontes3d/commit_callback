module CommitCallback
  
  def commit_callback(&block)
    conn = self.connection
    unless conn.respond_to?(:commit_callbacks)
      conn.instance_eval do
        class << self
          unless method_defined?(:commit_db_transaction_original_for_commit_callback_hook)
            attr_accessor :commit_callbacks
            alias commit_db_transaction_original_for_commit_callback_hook commit_db_transaction
            def commit_db_transaction
              commit_db_transaction_original_for_commit_callback_hook
              (self.commit_callbacks || []).each(&:call)
              self.commit_callbacks = []
            end
            alias rollback_db_transaction_original_for_commit_callback_hook rollback_db_transaction
            def rollback_db_transaction
              rollback_db_transaction_original_for_commit_callback_hook
              self.commit_callbacks = []
            end
          end
        end
      end
    end
    conn.commit_callbacks ||= []        
    conn.commit_callbacks << block
  end
  
  def self.adapt_for_transactional_test!(connection)
    unless RAILS_ENV == "test"
      raise ArgumentError, "Use this only in tests please!"
    end
    connection.instance_eval do
      class << self
        attr_accessor :num_transactions_open_to_start
        def release_savepoint
          if self.open_transactions == num_transactions_open_to_start && 
             self.respond_to?(:commit_callbacks)
          then
            (self.commit_callbacks || []).each(&:call)
            self.commit_callbacks = []
          end
          super
        end
        def rollback_to_savepoint
          if self.open_transactions == num_transactions_open_to_start && 
             self.respond_to?(:commit_callbacks)
          then
            self.commit_callbacks = []
          end
          super
        end
      end
    end
    connection.num_transactions_open_to_start = connection.open_transactions    
  end
  
end