# vim:ts=2:sw=2:et:

require 'bigdecimal'

module Deak

  class Account
    attr_reader :debit_is_decrease
    attr_reader :currency

    def initialize(opts)
      @splits = []
      @currency = opts[:currency]
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
      @splits.inject(0) {|net_increase, split| net_increase + split.base_amount}
    end

  end

  class Split
    attr_reader :account
    attr_reader :base_amount # Amount in base currency
    attr_reader :amount      # Amount in the account's currency

    def initialize( opts )
      @account = opts[:account]
      @amount  = opts[:amount]
      @base_amount = opts[:base_amount] || @amount
    end
  end

  class Book

    def initialize(opts)
      @accounts = []
      @transactions = []
      @default_currency = opts[:default_currency]
    end

    def add_account!( opts={} )
      opts[:currency] ||= @default_currency
      account = Account.new(opts)
      @accounts << account
      account
    end

    def add_transaction!( opts={} )
      txn = Transaction.new

      if opts.kind_of?(Array)
        
        base_currency = opts.detect {|split_spec| split_spec[:decrease_account]}[:decrease_account].currency

        opts.each do |split_spec|
          amount = BigDecimal.new(split_spec[:amount])
          if split_spec[:increase_account]
            account = split_spec[:increase_account]
          elsif split_spec[:decrease_account]
            account = split_spec[:decrease_account]
            amount = - amount
          end

          base_amount = nil
          if account.currency != base_currency
            raise RuntimeError.new unless split_spec[:converted_amount]
            base_amount = amount
            amount = BigDecimal.new(split_spec[:converted_amount])
          end

          txn.add_split! :account => account,
                         :amount  => amount,
                         :base_amount => base_amount
        end

      elsif opts.kind_of?(Hash)

        amount = BigDecimal.new(opts[:amount])
        if opts[:debit_account] && opts[:credit_account]
          decrease_account = opts[:credit_account]
          increase_account = opts[:debit_account]
        else
          decrease_account = opts[:decrease_account]
          increase_account = opts[:increase_account]
        end

        increase_amount = amount
        if increase_account.currency != decrease_account.currency
          # Multiple currency transaction
          raise RuntimeError unless opts[:converted_amount]
          increase_amount = BigDecimal.new(opts[:converted_amount])
        end

        txn.add_split! :account => decrease_account,
                       :amount  => - amount
        txn.add_split! :account => increase_account,
                       :amount  => increase_amount,
                       :base_amount => amount
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

