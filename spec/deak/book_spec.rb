# vim:ts=2:sw=2:et:

require 'deak'

module Deak
  describe Book do

    before(:each) do
      @book = Book.new
    end

    it "should add a simple transaction" do
      act_cash      = @book.add_account!( :name => "Cash" ) 
      act_groceries = @book.add_account!( :name => "Groceries" )
      @book.add_transaction!( :amount => "120",
                              :decrease_account => act_cash,
                              :increase_account => act_groceries )
      act_cash.total_increase.should == -120
      act_groceries.total_increase.should == 120
    end
  
    it "should reflect the difference between balance and total increase" do
      act_owner_equity = @book.add_account!( :name => "Owner Equity",
                                             :debit_is_decrease => true ) 
      act_cash         = @book.add_account!( :name => "Cash" )
      @book.add_transaction!( :amount => "1000",
                              :decrease_account => act_owner_equity,
                              :increase_account => act_cash )
      act_owner_equity.balance.       should == 1000
      act_owner_equity.total_increase.should == -1000
      act_cash.        balance.       should == 1000
      act_cash.        total_increase.should == 1000
    end

    it "should add a debit/credit between two asset accounts" do
      act_cash      = @book.add_account!( :name => "Cash" ) 
      act_groceries = @book.add_account!( :name => "Groceries" )
      @book.add_transaction!( :amount => "120",
                              :debit_account  => act_groceries,
                              :credit_account => act_cash )
      act_groceries.balance.should == 120
      act_cash.balance.should      == -120
    end

    it "should add a debit/credit between asset and equity account" do
      act_owner_equity = @book.add_account!( :name => "Owner Equity",
                                             :debit_is_decrease => true ) 
      act_cash         = @book.add_account!( :name => "Cash" )
      @book.add_transaction!( :amount => "1000",
                              :debit_account  => act_cash,
                              :credit_account => act_owner_equity )
      act_owner_equity.balance.should == 1000
      act_cash.        balance.should == 1000
    end

  end
end
