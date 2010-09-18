# vim:ts=2:sw=2:et:

require 'bigdecimal'

module Deak

#  class Security
#
#  end
#
#  class Currency < Security
#    
#    def self.iso(iso_code)
#      Currency.new :code => iso_code
#    end
#
#    def initialize( attrs={} )
#      @code = attrs[:code]
#    end
#  end

  class Account
#    attr_accessor :security

    def initialize(opts)
      @splits = []
    end

    def balance
      @splits.inject(BigDecimal.new("0")) do |balance, split|
        balance += split.amount
      end
    end

    def record_split!( split )
      @splits << split
    end
  end

  class Transaction
    attr_reader :splits

    def initialize
      @splits = []
    end

    def add_split!( opts )
      split = Split.new opts
      @splits << split
      split
    end
  end

  class Split
    attr_reader :account, :amount

    def initialize( opts )
      @account = opts[:account]
      @amount  = opts[:amount]
    end
  end

  class Book

    def initialize
      @accounts = []
      @transactions = []
    end

    def add_account!( opts={} )
      account = Account.new(opts)
      @accounts << account
      account
    end

    def add_transaction!( opts={} )
      txn = Transaction.new
      txn.add_split! :account => opts[:decrease_account],
                     :amount  => - BigDecimal.new(opts[:amount])
      txn.add_split! :account => opts[:increase_account],
                     :amount  => BigDecimal.new(opts[:amount])
      record_transaction!( txn )
    end

    def record_transaction!( txn )
      txn.splits.each do |split|
        split.account.record_split!(split)
      end
    end
  end

end

