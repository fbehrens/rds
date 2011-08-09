require 'helper'
require 'rds/models/simple'

module Rds
  describe Scope do
    
    before(:all) do
      @base = Base.new
      @redis = @base.redis
      Fixtures.new(:simple).load
      @r1 = Replica.new 1      
    end

    it '#Scope' do
      Replica.count.should == 4
      Database.count.should == 2
      Replica.all.ids.should == '1 2 3 4'
    end

    it '#[]' do
      r = Replica['s0!!test.nsf']
      r.should be_an(Replica)
      r.id.should == '1'
    end
    
    it '#&' do
      s = Replica.& :title => 'mydb'
      s.should be_an(Scope)
      s.conditions.should == ['title:mydb']
      s.count.should == 3
      
      b = Replica.& :icon_letter => 'b'
      b.count.should == 2
      
      s1 = s.& :icon_letter => 'b'
      s1.conditions.should == %w(title:mydb icon_letter:b) 
      s1.count.should == 1
    end
    
    it '#& bool' do
      s = Replica.&(:consistent?)
      s.ids.should == '1 4'
      s.&(:icon=>'a').ids.should == '1'
    end
    
    it '#-' do
      s = Replica.-(:title=>'db1')
      s.exclusions.should == %w(title:db1)
      s.ids.should == '1 2 3'
      s.&(:consistent?).ids.should == '1'
    end
    
    it '#- bool' do
      s = Replica.-(:consistent?)
      s.exclusions.should == %w(consistent?)
      s.count.should == 2
      s.map(&:id).sort.should == %w(2 3)
    end
    
    it '#& bool?, :field => value ' do
      s = Replica.& :consistent?, :title=>'mydb', :icon => 'a'
      s.conditions.should == %w(title:mydb icon:a consistent?)
      s.ids.should == '1'
    end
     
    it '#multi condition and exclusion' do
      s = Replica.&(:title=>'mydb', :icon => 'a').- :consistent?
      s.conditions.should == %w(title:mydb icon:a)
      s.exclusions.should == %w(consistent?)
      s.ids.should == '2'
    end
    
    it '#&- Scope' do
      s1 = Replica.& :title=>'mydb', :icon => 'a'
      s2= Replica.- :consistent?
      s1.&(s2).conditions.should == %w(title:mydb icon:a)
      s1.&(s2).exclusions.should == %w(consistent?)
      s1.&(s2).ids.should == '2'
      s1.-(s2).conditions.should == %w(title:mydb icon:a consistent?)
      s1.-(s2).ids.should == '1'
    end
     
    it 'scope' do
      Replica.mydb.should be_an(Scope) 
      Replica.mydb.ids.should == '1 2 3'
    end
    
    it 'boolean scope' do
      Replica.consistent.ids.should == '1 4'
      Replica.not_consistent.ids.should == '2 3'
      Replica.mydb.not_consistent.ids.should == '2 3'
    end
    
    it '#inverse' do
      Replica.consistent.inverse.ids.should == '2 3'
    end

    it 'scope combined' do
      Replica.combined.ids.should == '1'
    end
    
    it 'chained scopes' do
      Replica.mydb.a.conditions.should == %w(title:mydb icon:a)
      Replica.mydb.a.ids.should == '1 2'
    end
    
    it '#&custom_index' do
      Replica.&(:_title=>'_mydb').ids.should == '1 2 3'
    end

    it '#index_update' do
      Replica.mydb.index_update(:icon).first.to_s.should_not match(/"abc"/)
      Replica.index_update(:icon).first.to_s.should match(/"abc"/)
    end
           
    after(:all) do
#      puts @base
    end
    
  end

end

