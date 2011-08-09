require 'helper'

module Rds
  
  describe 'Redis' do
    
    before(:all) do
      @base = Base.new.flushdb
      @r = @base.redis
    end
    
    it '#string' do
      @r.set('string','value').should == 'OK'
      @r.set('string','value1').should == 'OK'
      @r.get('string').should == 'value1'
#      @r.set('string','ö').should == 'OK'
#      @r.get('string').should == 'ö'
      @r.get('s1').should be_nil  
    end

    it '#set' do   
      @r.sadd 'set','s1'
        
    end
    
    it '#list' do   
      @r.rpush 'list','l1'
      @r.rpush 'list','l2'
    end
    
    it '#hash' do   
      a = ['k1','v1','k2','v2']
      @r.hmset 'hash',*a
   
      @r.hexists('h1','k').should be_false
      @r.hset('h1','k','').should be_true
      @r.hset('h1','k','').should be_false # returns if key was new
      @r.hexists('h1','k').should be_true
      @r.hget('h1','k').should  == ''
      @r.hdel('h1','k').should  be_true
      @r.hdel('h1','k').should  == 0
      
      #get nonexistent Key
      @r.hget('h2','k').should  == nil
    end
    
    it '#zset' do   
      4.times{|i| @r.zadd 'zset',i,"v#{i}"}
      @r.zrange('zset', 1, 2).should == %w(v1 v2)
      
    end
       
    after(:all) do
#      puts @base
    end
    
  end

end
