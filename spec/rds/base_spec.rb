require 'helper'
module Rds
  
  describe Base do
    
    before(:all) do
      @base = Base.new.flushdb
      @redis = @base.redis
    end
    
    it '#writes Keys' do
      h = {:a => 1,:b => 2}
      Hash.create(@redis,'hash', h)
      Set.create(@redis,'set','s1','s2')
      List.create(@redis,'list','l1','l2')
      String.create(@redis,'string','s')
      zset = Zset.create(@redis,'zset', h)
      
      lambda {
        @base.delete_keys('s*')
      }.should change(@redis, :dbsize).by(-2)
    end

  end
  
end
