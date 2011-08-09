require 'helper'
require 'rds/models/simple'

module Rds
  describe Index do
    
    before(:all) do
      @b = Base.new
      @r = @b.redis
      Fixtures.new(:simple).load
      @c = Replica.index :consistent?
    end
       
    it '#index' do
      Replica.indices.count.should == 6
      Replica.indices.first.should be_an(Index)
      Database.indices.map(&:name).should == [:ident]
    end

    it '#create_index' do
      lambda {
        Replica.create_index :consistent?
      }.should_not change(Replica.indices, :count)
      Replica.create_index(:consistent?).first.should be_an(Index)
    end

    it '#delete_index' do
      lambda {
        Replica.create_index :temp?
      }.should change(Replica.indices, :count).by(1)
      lambda {
        Replica.delete_index :temp?
      }.should change(Replica.indices, :count).by(-1)
      lambda {
        Replica.delete_index :temp?
      }.should_not change(Replica.indices, :count)
    end
    
    it '#temp_index' do
      lambda {
        Replica.temp_index(:import?) do |i|
          i.should be_an(Index)
          i << Replica.first
          i.scope.count.should == 1
        end
      }.should_not change(Replica.indices, :count)
    end
    
    it '#reset' do 
      @c.should be_an(Index)
      Replica.consistent.count.should == 2
      @c.reset
      Replica.consistent.count.should == 0
    end
    
    it '#index_update' do
      Replica.indices.each(&:update)
    end
    
    it '#index_rebuild' do
      Replica.index_rebuild
      @r.type('Replica:id').should == 'string'
      @r.type('Replica:all').should == 'set'
    end
    
    it '#output' do
      ::OutputCatcher.catch_out do
        Replica.by :title
        Replica.&(:consistent?).by :title
        Replica.by :consistent?
        Replica.&(:title => 'mydb').by :consistent?
      end
    end
        
    after(:all) do
#      puts @base
    end
    
  end

end

