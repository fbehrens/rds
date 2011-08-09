module Rds
  
  # Replica:consistent&title:mydb
  # Replica:title:mydb!consistent
  # Replica:all!consistent
  class Scope
    TTL = 3600 unless defined? TTL
    include Enumerable
    attr_reader :conditions,:exclusions
    
    def initialize(klass,condition=nil,exclusions=nil)
      @klass, @conditions, @exclusions = klass, Array.wrap(condition), Array.wrap(exclusions)
    end
    
    def & *args
      if (s=args.first).kind_of? Scope
        Scope.new @klass, @conditions + s.conditions, @exclusions + s.exclusions 
      else  
        Scope.new @klass, @conditions + to_condition(args), @exclusions
      end 
    end
    
    def - *args
      if (s=args.first).kind_of? Scope
        Scope.new @klass, @conditions + s.exclusions, @exclusions + s.conditions 
      else  
        Scope.new @klass, @conditions, @exclusions + to_condition(args)
      end 
    end
        
    def inverse
      Scope.new @klass, @exclusions, @conditions
    end
    
    def count
      @klass.redis.scard resolve
    end
    
    def each
      @klass.redis.smembers(resolve).each do |id|
        yield @klass.new(id)
      end
    end
    
    def by index_name
      puts @klass.index(index_name).to_s(self)
    end
    
    def index_update *index_names
      @klass.indices(*index_names).map {|i| i.update self }
    end
    
    def to_s
      map(&:to_s).join "\n"
    end
    
    def ids
      map(&:id).sort.join ' '
    end
    
    def inspect
      "<#{@klass}:#{count}: &=#{@conditions.inspect} -=&#{@exclusions.inspect}>"
    end
    
    def method_missing(name, *args)
      super unless @klass.scopes[name]
      self.& @klass.send(name)
    end
    
    private
    
    def to_condition args
      if (last = args.pop).kind_of? ::Hash
        last.map{|key,value| colon(key,value)}
      else
        [last.to_s]
      end + args.map(&:to_s)  
    end
    
    def expand_with_klass_name key
      key.count(':') < 2 ? colon(@klass.name,key) : key
    end
      
    # returns key of expiring key    
    def resolve_conditions
      if @conditions.empty?
        "#{@klass.name}:all"
      elsif @conditions.length == 1
        expand_with_klass_name @conditions.first
      else
        key = @conditions[1..-1].inject(expand_with_klass_name(@conditions.first.dup)) do |sum,c| 
          sum << "&#{c}" 
        end
        param = @conditions.map{|c| expand_with_klass_name c}
        @klass.redis.sinterstore key, *param 
        #Replica:icon:a:icon:b Replica:icon:a Replica:icon:b
#       @klass.redis.expire key, TTL
        key
      end
    end
    
    def resolve
      if @exclusions.empty?
        resolve_conditions
      else
        key_conditions = resolve_conditions
        key = @exclusions.inject(key_conditions.dup) do |sum,e| 
          sum << "!#{e}" 
        end
        param = @exclusions.map{|c| expand_with_klass_name c}
#       workaround for sdiffstore is not working because of expiring keys           
#        @klass.redis.del key
#        @klass.redis.sdiff(key_conditions, *param).each{|k| @klass.redis.sadd key,k}
        @klass.redis.sdiffstore(key, key_conditions, *param)
#        @klass.redis.expire key, TTL
        key
      end
    end
    
  end  
  
end

