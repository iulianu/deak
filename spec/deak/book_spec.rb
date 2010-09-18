# vim:ts=2:sw=2:et:

require 'deak'

module Deak
  describe Book do

    before(:each) do
      @book = Book.new
      @act_cash      = @book.add_account!( :name => "Cash" ) 
      @act_groceries = @book.add_account!( :name => "Groceries" )
    end

    it "should add a simple transaction" do
      @book.add_transaction!( :amount => "120",
                              :decrease_account => @act_cash,
                              :increase_account => @act_groceries )
      @act_cash.balance.should == -120
      @act_groceries.balance.should == 120
    end
  
  end
end
