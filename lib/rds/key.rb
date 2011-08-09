module Rds
  
  class Key
    
    def self.get r, k
      klass = r.type(k).capitalize
      ::Rds.const_get(klass).new r, k
    end
    
    attr_reader :key
    
    def initialize redis, key
      @redis, @key = redis, key
    end

    def inspect
      "#{inspect_key}  #{inspect_value}"
    end
    
  end
  
  class String < Key
    
    def self.create r, k, s
      r.set k, s
      new r, k
    end

    def self.incr r, k
      r.incr k
    end
    
    def self.[] r, k
      r.get k
    end

    def self.[]= r, k, v
      r.set k, v
    end

    def inspect_key
      key
    end
    
    def inspect_value
      value
    end
    
    def value
      @redis.get(key)
    end
    
  end
  
  class Set < Key
    
    def self.create r, k, *a
      a.each{|e| r.sadd k,e }
      new r, k
    end
    
    def << v
      @redis.sadd key,v
    end

    def inspect_key
      "(#{key})"
    end
    
    def inspect_value
      value.sort.join ' '
    end
    
    def value
      @redis.smembers(key)
    end
    
  end
  
  class List < Key
    
    def self.create r, k, *a
      a.each{|e| r.rpush k,e }
      new r, k
    end
    
    def value
      @redis.lrange(key,0, -1)
    end
    
    def value= multi
#      unless multi == value
      @redis.del key
      multi.each do |single|
        @redis.rpush key, single
      end
 #     end
    end
    
    def inspect_key
      "[#{key}]"
    end
    
    def inspect_value
      value.join ' '
    end
    
  end
  
  class Hash < Key
    
    def self.create r, k, hash=nil
      if hash
        a = hash.to_a.flatten
        r.hmset k,*a
      end
      new r, k
    end

    def []= field,value
      @redis.hset key, field, value
    end
        
    def [] field
      @redis.hget key, field
    end
        
    def inspect_key
      "{#{key}}"
    end
    
    def inspect_value
      v = value
      v.keys.sort.map{|e| "#{e}: #{v[e]}"}.join(', ')
    end
        
    def value
      @redis.hgetall(key)
    end
    
  end
  
  
  class Zset < Key
    
    def self.create r, k, values={}
      values.each{|key,v|
        r.zadd k , v , key }
      new r, k
    end
    
    def inspect_key
      "({#{key}})"
    end
    
    def inspect_value
      v = value
      v.keys.sort.map{|e| "#{e}(#{v[e]})"}.join ' '
    end
        
    def value
      @redis.zrange(key,0,-1).inject({}) do |sum,k|
        sum[k] = @redis.zscore(key,k).to_i
        sum
      end
    end
    
  end
  
end
