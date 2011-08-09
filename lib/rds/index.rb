module Rds
  
  # gives immediate access to filters 
  # example Project
  #   :done? [Boolean]   Project:done [1,2]
  #   :status            Project:status:ok [1,2] 
  #                      Project:status:red [3,4]
  #   :id    [Unique]    Project:id:10001 1   
  class Index
    
    class << self
      attr_reader :all
      def all
        @all ||= []
      end
      def update
        all.map(&:update).map(&:to_s).join "\n\n"
      end
    end
    
    attr_reader :name, :unique
    
    def initialize(klass,name,o={})
      @klass, @name = klass, name
      @unique = o[:unique]
      self.class.all << self   
    end
    
    def boolean?
      name =~ /\?$/
    end
    
    # adds the values of  
    def write_instance model
      value = model.send name
      if boolean?
        self << model if value
      elsif @unique
        @klass.redis.set pattern(value), model.id
      else 
        Array.wrap( value ).each do |v|
          @klass.redis.sadd pattern(v) ,model.id
        end
      end
    end
    
    def <<(model)
      @klass.redis.sadd pattern(nil) ,model.id 
    end
    
    # only for boolean
    def scope
      @klass.& name
    end
    
    # Project:status:*
    def pattern( v='*' )
      colon @klass.name, name, v
    end
    
    
    def keys
      @klass.redis.keys(pattern).map{|k| k[/[^:]*$/]}
    end
    
    def update(scope=@klass.all)
      reset
      calculate scope
      self  
    end
    
    # delete all caculated values
    def reset
      if boolean?
        @klass.redis.del pattern(nil)
      else
        @klass.redis.keys(pattern).each {|k| @klass.redis.del k }
      end
      self
    end
    
    # 
    def calculate(scope)
      scope.each do |m|
         write_instance m
      end
    end
    
    def out(scope=@klass.all)
      puts update(scope).to_s(scope)
    end
    
    def to_s(scope=@klass.all)
      values(scope).inject("#{scope.inspect || @klass } by #{name}\n") do |sum,v| 
        sum << "%6s %1s\n" % v 
      end
    end
    
    # for output
    def values(scope)
      if boolean?
        [[scope.&(name).count,name],
         [scope.-(name).count,'' ] ]
      else
        keys.map { |k| [scope.&( name => k).count, k.inspect ] }
      end. \
      <<([scope.count,"sum"]). \
      sort_by(&:first).reverse
    end
    
  end  
  
end
