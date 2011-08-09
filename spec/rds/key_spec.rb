require 'helper'
module Rds
  
  describe Key do
    
    before(:all) do
      @base = Base.new.flushdb
      @redis = @base.redis
    end
    
    describe Hash do
    
      it '#existing values will be overwritten' do
        h = {'a' => 'b', 'c' => 'd'}
        h1 = {'e' => 'f'}
        
        hash = Hash.create(@redis,'hash', h)
        hash.value.should == h 
        hash['a'].should == 'b'
        hash[:a].should == 'b'
        hash.inspect.should == '{hash}  a: b, c: d'
  
        Hash.create(@redis,'hash', h1).value.should == h.merge(h1)
      end
      
      it 'repesensts bool' do
        Hash.create(@redis,'hb', { :a => ''})[:a].should == ''
      end
      
    end 
    
    it '#Set' do
      s = Set.create(@redis,'set','1',2)
      s.value.sort.should == ['1','2']
      s.inspect.should == '(set)  1 2'  
      s << 3
      s.value.sort.should == ['1','2','3']
    end
    
    it '#sdiffstore' do
      Set.create(@redis,'set1','1')  
      Set.create(@redis,'set2','2')  
      @redis.sdiff('set','set1','set2').should == ['3']  
      @redis.sdiffstore('setdiff','set','set1','set2')
      Set.create(@redis,'setdiff').value.should == ['3']  
    end
    
    it '#List' do
      ab,abc = %w(a b), %w(a b c)
      l = List.create @redis,'list',*ab
      l.value.should == ab
      l.inspect.should == '[list]  a b'
      
      l.value = ab #.should be_nil
      l.value = abc#.should be_nil
      l.inspect.should == '[list]  a b c'
    end
    
    it '#String' do
      s = String.create(@redis,'string','v2')
      s.value.should == 'v2'
      s.inspect.should == 'string  v2'
      
      String[@redis,'string'].should == 'v2'
      String[@redis,'string_ne'].should be_nil
      String[@redis,'string_ne']= 'v3'
      String[@redis,'string_ne'].should == 'v3'
      
      String.incr(@redis,'stringinc').should == 1
      String.incr(@redis,'stringinc').should == 2
    end
    
    it '#Zset' do
      z1 = {'1' => 1, '2' => 2}
      z2 = {'2' => 3}  
      z3 = {'2' => 4} 
         
      zset = Zset.create(@redis,'zset', z1)
      zset.value.should == z1
      zset.inspect.should == '({zset})  1(1) 2(2)'
      Zset.create(@redis,'zset').inspect.should == '({zset})  1(1) 2(2)'
        
      Zset.create(@redis,'zset', z2).value.should == z1.merge(z2)
      Zset.create(@redis,'zset1',z2).value.should == z2
      Zset.create(@redis,'zset1',z3).value.should == z3
    end
    
  end
  
end
