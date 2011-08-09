require 'helper'
require 'rds/models/simple'
module Rds
  describe Model do
    
    before(:all) do
      @base = Base.new
      @redis = @base.redis
      Fixtures.new(:simple).load
      @r1 = Replica.new 1      
    end

    it 'has_many' do
      d = Database['aa']
      r = d.replicas
      r.should be_an(Scope)
      r.conditions.should == %w(Database:1:replicas)
      r.ids.should == '1 2 3'
      r1 = r.& :icon => 'ab'
      r1.conditions.should == %w(Database:1:replicas icon:ab)
      r1.count.should == 1
      d.replicas.&(:icon => 'ab').count.should == 1
    end
    
    it 'has_many :class_name => Script' do
      Script.count.should == 3
      @r1.databasescript_script.should be_an(Script)
      Script['aa'].replicas.ids.should == '1 3'
    end
    
    it 'belongs_to' do
      @r1.database.should be_an(Database)
      @r1.database[:ident].should == 'aa'
    end

    it 'field_accessor' do
      @r1.ident.should == 's0!!test.nsf'
      @r1.title.should == 'mydb'
      @r1.title = '1'
      @r1.title.should == '1'
      @r1.title = 'mydb'
    end
    
    it 'counter' do
      @r1.popups.should == 0
      @r1.popups += 1
      @r1.popups.should == 1
      @r1.popups = 20
      @r1.popups.should == 20
    end
    
    it 'time_accessor' do
      t = Time.now
      @r1.created_at = t
      @r1.created_at.to_i.should == t.to_i
    end
    
    it '#[]' do
      Replica['s0!!test.nsf'].id.should == '1'
      Replica['not there'].should be_nil
    end
    
    it 'bool_accessor' do
      @r1.consistent?.should be_true
      @r1.consistent = false
      @r1.consistent?.should be_false
      @r1.consistent = true
    end
    
    it 'delete_fields' do
      @r1.icon.should == 'a'
      Replica.delete_fields :icon
      @r1.icon.should == nil
    end
        
    it 'check' do
      Replica.valid?.should be_true
    end
    
    it '#each' do
      Replica.map(&:id).sort.should == %w(1 2 3 4)
    end
    
    it '#delete' do
      ident = Replica.first.ident
      lambda {
        Replica.first.delete
      }.should change(Replica, :count).by(-1)
      Replica[ident].should be_nil
    end
    
    after(:all) do
#      puts @base
    end
    
  end

end
