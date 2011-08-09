module Rds
  
  class Base
    
    class << self
      
      attr_accessor :redis
      
      def config
        YAML.load_file( File.expand_path( '../config.yml', __FILE__ ))
      end
      
      def establish_connection(env='development')
        @env = env
        new config[@env] 
      end
      
    end

    attr_reader :db, :redis
    
    def initialize(options={:host => 'localhost', :port => 6379})
      @db = options.delete(:db)||0
      @redis = Redis.new options
      self.class.redis = redis 
      select @db
    end
    
    def inspect
      nil
    end
    
    def select(n)
      if block_given?
        @redis.select n
        result = yield
        @redis.select @db
        result
      else
        @db = n
        @redis.select @db
        self
      end
    end
    
    def keys(pattern='*')
      @redis.keys(pattern).sort.map do |k| 
        self[k] 
      end
    end
    
    def delete_keys(pattern)
      @redis.keys(pattern).each do |k| 
        @redis.del k 
      end
    end
    
    def [](key)
      Key.get @redis, key
    end
    
    def to_s
      puts "db[#{db}]=====================================\n"  
      keys.map(&:inspect).join("\n")
    end
    
    def dump
      16.times do |i|
         select(i) do
           puts "#{i}: #{@redis.dbsize}" if @redis.dbsize > 0
         end    
      end
    end
    
    def flushdb
      @redis.flushdb
      self
    end
    
  end
  
end
