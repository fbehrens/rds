require 'helper'
require 'rds/models/simple'

module Rds
  describe Model do
    
    before(:all) do
      @b = Base.new(:db => 1).flushdb.select 0
      @r = @b.redis
      Fixtures.new(:one).load
      @r1 = Replica.new 1      
    end
    
    it '#bool' do
      @r1.consistent?.should be_true
      @r1.consistent = false
      @r1.consistent?.should be_false
      @r1.consistent = true
    end
    
    it '#multivalue' do
      @r1.multi.should == %w(a b)
      @r1.multi = abc = %w(a b c)
      @r1.multi.should == abc
    end
    
    it '#sorted' do
      @r1.sorted.should == 42
      @r1.sorted = new = 43
      @r1.sorted.should == new
    end

    it '#attributes' do
      @r1.attributes[:database].should == "aa"
      @r1.attributes[:consistent?].should be_true
    end
    
    it '#copy_to' do
#      Replica.copy_db 0 => 1
    end
    
    after(:all) do
#      @b.dump
    end
    
  end

end
