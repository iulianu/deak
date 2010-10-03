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
    attr_reader :debit_is_decrease

    def initialize(opts)
      @splits = []
      @debit_is_decrease = opts[:debit_is_decrease] || false
    end

    def total_increase
      @splits.inject(BigDecimal.new("0")) do |increase, split|
        increase += split.amount
      end
    end

    def balance
      total_increase * (@debit_is_decrease ? -1 : 1)
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

    def balanced?
      net_increase == 0
    end

    def net_increase
      @splits.inject(0) {|net_increase, split| net_increase + split.amount}
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

      if opts.kind_of?(Array)

        opts.each do |split_spec|
          amount = BigDecimal.new(split_spec[:amount])
          if split_spec[:increase_account]
            account_key = :increase_account
          elsif split_spec[:decrease_account]
            account_key = :decrease_account
            amount = - amount
          end
          txn.add_split! :account => split_spec[account_key],
                         :amount  => amount
        end

      elsif opts.kind_of?(Hash)

        if opts[:debit_account] && opts[:credit_account]
          txn.add_split! :account => opts[:credit_account],
                         :amount  => - BigDecimal.new(opts[:amount])
          txn.add_split! :account => opts[:debit_account],
                         :amount  => BigDecimal.new(opts[:amount])
        else
          txn.add_split! :account => opts[:decrease_account],
                         :amount  => - BigDecimal.new(opts[:amount])
          txn.add_split! :account => opts[:increase_account],
                         :amount  => BigDecimal.new(opts[:amount])
        end
      end
      record_transaction!( txn )
    end

    def record_transaction!( txn )
      raise RuntimeError unless txn.balanced?
      txn.splits.each do |split|
        split.account.record_split!(split)
      end
    end
  end

end

