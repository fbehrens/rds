module Rds
  
  module Model
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      include Enumerable
      
      attr_writer :redis
      def redis
        @redis ||= Base.redis
      end
      
      def valid?
        invalid_ids.empty?
      end
      
      def invalid_ids
        redis.smembers(name).select do |member|
          redis.type(colon(name,member)) != 'hash' ||
          redis.hget(colon(name,member),'ident') == ''
        end
      end
      
      # index gets attay of indexes
      # index(name) gets index name
      # default unique index on ident
      def indices *only
        if only.empty?
          @indices ||= [Index.new(self, :ident, :unique => true)]
        else
          indices.select{|i| only.include? i.name }
        end
      end
      
      def index name
        indices.detect{|i| i.name == name}
      end
      
      def create_index *param
        i, options_array = param.partition{|p| p.kind_of? Symbol}
        options = options_array.empty? ? {} : options_array.first  
        i.each do |name|
          delete_index name
          indices << Index.new(self, name, options)
        end
        indices *i
      end
      
      def delete_index name
        indices.delete index(name)
      end
      
      def temp_index name
        i= create_index(name).first.reset
        yield i
        delete_index name
      end
      
      def index_update(*names)
        indices(*names).each(&:update)
      end
      
      # deletes all Keys
      def index_rebuild
        # TODO index_rebuild breaks sorted attributes
        redis.keys("#{name}:*").each do |key|
          redis.del key unless key =~ /^#{name}:(all|id|\d+)/
        end
        index_update
      end

      def by index_name
        puts index(index_name)
      end
      
      def has_many(*f)
        f.each do |field|
          define_method(field) do
            klass = field.to_s.singularize.camelize.constantize
            Scope.new klass, colon(name,field)  
          end
        end
      end
      
      def delete_association association 
        redis.keys("#{name}:*:#{association}").each{|k| redis.del k}
      end
      
      def delete_without association
        each {|d| d.delete unless redis.exists(colon(name,d.id,association)) }
      end
      
      def belongs_to(field,options={})
        define_method(field) do
          (options[:class_name] ||field.to_s.camelize).constantize.new self[field] 
        end
        define_method("#{field}=") do |value|
          klass = (options[:class_name] || field.to_s.camelize).constantize
          value = klass.create_or_update(value).id
          @redis.sadd colon(klass.name , value, parent.name.downcase.pluralize), id
          self[field.to_sym] = value
        end
      end
      
      # id    -> attributes will be updated
      # ident -> id will be created
      def create_or_update(ident,attributes={})
        raise "updating id is not supported" if attributes[:id] 
        unless id = redis.get("#{name}:ident:#{ident}") 
          id = redis.incr "#{name}:id"        #Replica:id
          redis.sadd "#{name}:all", id      # Replica
          redis.hset colon(name,id), :ident, ident
          redis.set colon(name, :ident, ident ) ,id
        end
        new id, attributes
      end
      
      def create_or_update_hash(attributes)
        create_or_update(attributes.delete(:ident),attributes)
      end

      def copy_db direction
        from,to = direction.first
        each do |m|
          redis.select from
          attr = m.attributes
          redis.select to
          create_or_update_hash attr 
        end
      end 
      
      def [] ident
        if id = redis.get(colon(name, :ident, ident))
          new id
        end
      end
      
      def all
        Scope.new( self)
      end
      
      def each(&b)
        all.each(&b)
      end
      
      [:&, :-, :count].each do |m|
        define_method m do |*args|
          all.send m, *args
        end
      end
          
      # find :field, value, ..
      def find hash
        field, value = hash.first
        if index(field).unique
          if id = redis.get(colon(name, field, value))
             new id
          end
        else
          raise "no unique index on #{field}"
        end
      end
      
      # simple fields
      def delete_fields *f
        f.each do |field|
          each {|m| redis.hdel m.name, field }
        end
      end
      
      # create attribute accessors
      def field_accessor *f
        field_reader *f
        field_writer *f
      end
      
      def field_reader *f
        f.each do |field|
          if field =~ /(.*)\?$/  # bool
            define_method(field) do                #consistent?
              @redis.hexists name, field
            end
          else  
            define_method(field) do                #title
              self[field] 
            end
          end
        end 
      end
      
      def field_writer *f
        f.each do |field|
          if field =~ /(.*)\?$/  # bool
            define_method("#{$1}=") do |value|     #consistent = bool
              value ?
                @redis.hset(name, field, '') :
                @redis.hdel(name, field)
            end
          else  
            define_method("#{field}=") do |value|  #title = 
              if value 
                self[field] = value
              else
                @redis.hdel(name, field)
              end 
            end
          end
        end 
      end
      
      def time_accessor *f
        f.each do |field|
          define_method(field) do                #popuped_at
            self[field] && Time.at(self[field].to_i)
          end
          define_method("#{field}=") do |value|  #popuped_at = 
            self[field] = value.to_i 
          end
        end
      end
      
      def counter *f
        f.each do |field|
            define_method(field) do                #popups
              return 0 unless self[field]
              self[field].to_i
            end
            define_method("#{field}=") do |value|  #popups = 
              self[field] = value 
            end
        end
      end
      
      def multivalue_accessor *f
        f.each do |field|
          define_method("#{field}_list") do       # fullname_list
            List.new @redis, colon(name,field)  
          end
          define_method(field) do                 #fullname
            send("#{field}_list").value
          end
          define_method("#{field}=") do |value|   #fullname = 
            send("#{field}_list").value = value
          end
        end 
      end
      
      def sorted_accessor *f
        f.each do |field|
          define_method(field) do                 #sorted
            (@redis.zscore colon(parent.name,field), id).to_i
          end
          define_method("#{field}=") do |value|   #sorted = 
            @redis.zadd colon(parent.name,field), value,id
          end
        end 
      end
      
      def scope( name, *conditions)
        if !conditions.empty?
          scopes[name] = true
          singleton_class.send(:define_method, name) do
            self.& *conditions
          end
        elsif name =~ /(.*)\?$/
          method = $1
          scopes[:"#{method}"] = scopes[:"not_#{method}"] = true
          singleton_class.send :define_method, method do
            self.& name
          end
          singleton_class.send :define_method, "not_#{method}" do
            self.- name
          end
        else
          raise "Define boolean scope with trailing ?"
        end
      end
      
      def scopes
        @scopes ||= {}
      end
      
    end
    
    # Instance Methods
    attr_reader :id, :name
    
    def parent
      self.class
    end
    
    def initialize( id, att={} )
      @redis, @id = parent.redis, id
      @name = colon parent.name, id
      update att
    end
    
    def update att
      att.each do |field,value|
        if respond_to? "#{field}="
          send "#{field}=",value
        else
          self[field] = value
        end
      end
    end
    
    def attributes
      @redis.hkeys(name).inject({}) do |sum,key|
        value = if respond_to? key
          send key
        else
          @redis.hget(name,key)
        end
        value = value.ident if value.class.included_modules.include? Rds::Model
        sum[key.to_sym] = value 
        sum
      end
    end
    
    def delete
      @redis.del "#{parent.name}:ident:#{ident}"
      @redis.srem "#{parent.name}:all", id
      @redis.del name
    end
    
    def ident
      self[:ident]
    end
    
    def [] field
      @redis.hget name, field
    end
    
    def []= field, value
      @redis.hset name, field, value
    end
    
    def inspect
      "<#{name} #{ident}: #{attributes.inspect}>"
    end
    
    def tick
      print " #{ident} "
      self
    end

  end  
  
end
