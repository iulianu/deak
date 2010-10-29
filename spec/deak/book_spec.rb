# vim:ts=2:sw=2:et:

require 'deak'

module Deak
  describe Book do

    before(:each) do
      @book = Book.new :default_currency => "RON"
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
  
    describe "debits, credits, and balance" do

      before(:each) do
        @act_cash         = @book.add_account!( :name => "Cash" )
        @act_groceries    = @book.add_account!( :name => "Groceries" )
        @act_owner_equity = @book.add_account!( :name => "Owner Equity",
                                                :debit_is_decrease => true ) 
      end

      it "should reflect the difference between balance and total increase" do
        @book.add_transaction!( :amount => "1000",
                                :decrease_account => @act_owner_equity,
                                :increase_account => @act_cash )
        @act_owner_equity.balance.       should == 1000
        @act_owner_equity.total_increase.should == -1000
        @act_cash.        balance.       should == 1000
        @act_cash.        total_increase.should == 1000
      end

      it "should add a debit/credit between two asset accounts" do
        @book.add_transaction!( :amount => "120",
                                :debit_account  => @act_groceries,
                                :credit_account => @act_cash )
        @act_groceries.balance.should == 120
        @act_cash.balance.should      == -120
      end

      it "should add a debit/credit between asset and equity account" do
        @book.add_transaction!( :amount => "1000",
                                :debit_account  => @act_cash,
                                :credit_account => @act_owner_equity )
        @act_owner_equity.balance.should == 1000
        @act_cash.        balance.should == 1000
      end

    end

    describe "splits" do

      before(:each) do
        @act_card      = @book.add_account!( :name => "Card" )
        @act_groceries = @book.add_account!( :name => "Groceries" )
        @act_transport = @book.add_account!( :name => "Transport" )
      end

      it "should add split transaction" do
        @book.add_transaction!( [{:amount => "120", :decrease_account => @act_card},
                                 {:amount => "80",  :increase_account => @act_groceries},
                                 {:amount => "40",  :increase_account => @act_transport}] )
        @act_card.total_increase.should == -120
        @act_groceries.total_increase.should == 80
        @act_transport.total_increase.should == 40
      end

      it "should fail when splits are not balanced" do
        expect {
          @book.add_transaction!( [{:amount => "120", :decrease_account => @act_card},
                                  {:amount => "60",  :increase_account => @act_groceries},
                                  {:amount => "40",  :increase_account => @act_transport}] )
        }.to raise_error
      end

    end

    describe "multiple currencies" do

      before(:each) do
        @act_card      = @book.add_account!( :name => "Card", :currency => "RON" )
        @act_groceries = @book.add_account!( :name => "Groceries", :currency => "RON" )
        @act_rent      = @book.add_account!( :name => "Rent", :currency => "EUR")
      end

      it "should convert currencies" do
        @book.add_transaction! :amount => "860",
                               :decrease_account => @act_card,
                               :increase_account => @act_rent,
                               :converted_amount => "210"
        @act_card.balance.should == -860
        @act_rent.balance.should == 210
      end

      it "should convert currencies in split transactions" do
        @book.add_transaction!( [{:amount => "980", :decrease_account => @act_card},
                                 {:amount => "120", :increase_account => @act_groceries},
                                 {:amount => "860", :increase_account => @act_rent, :converted_amount => "210"}] )
        @act_card.balance.should == -980
        @act_groceries.balance.should == 120
        @act_rent.balance.should == 210
      end

      it "should fail when not specifying converted amount" do
        expect {
          @book.add_transaction! :amount => "860",
                                :decrease_account => @act_card,
                                :increase_account => @act_rent
        }.to raise_error
      end

    end

  end
end
