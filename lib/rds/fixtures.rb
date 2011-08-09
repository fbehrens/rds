require 'csv'
require 'yaml'
YAML::ENGINE.yamler='syck' # psych

module Rds

  class Fixtures
    
    CSV::Converters[:bool]  ||= lambda{|f| %w(true false).include?(f) ? eval(f) : f}
    CSV::Converters[:trim]  ||= lambda{|f| f.strip rescue f}
    CSV::Converters[:split] ||= lambda{|f| f.include?('|') ? f.split('|') : f rescue f}

    def initialize(io)
      io = File.new("spec/fixtures/#{io}.yml") if io.kind_of? Symbol
      @content = YAML.load io
      @data, @hashed, @diffed  = [], [], []
    end
    
    # Replica => [{k: v,..}, .. ]
    def data(charge=0)
      @data[charge] ||= ::Hash[ @content.map do |klass,chunk|
        [ klass, 
          CSV.parse(chunk[charge], 
                    :headers => true, 
                    :converters => [:all,:trim,:bool,:split], 
                    :header_converters => :symbol ).map{|row| row.to_hash.select{|k,v| v } }
        ]
      end ]
    end

    def hashed(charge=0)
      @hashed[charge] ||= ::Hash[ @content.map do |klass,chunk|
        [ klass, 
          ::Hash[ CSV.parse(chunk[charge], 
                    :headers => true, 
                    :converters => [:all,:trim,:bool,:split], 
                    :header_converters => :symbol ).map{|row| 
                      [ row.delete(0)[1], row.to_hash.select{|k,v| v } ] } ]
        ]
      end ]
    end
    
    # @returns hash of hashes
    def hashi array_of_hashes
      ::Hash[ array_of_hashes.map do |hash|
        first, *rest = hash.to_a
        [first.last, ::Hash[rest]]
      end]
    end

    def diffed(charge=0)
      @diffed[0] ||= hashed
      return @diffed[0] if charge == 0
      result = diffed(charge-1).dup
      hashed(charge).each do |klass,instances|
        instances.each do |ident,values |
          if ident =~ /\-(.*)/
            result[klass].delete $1
          else 
            result[klass][ident] ||= {}
            result[klass][ident].merge! values
          end
        end
      end
      @diffed[charge] = result
    end
    
    def load(charge=0)
      Base.redis.flushdb
      diffed(charge).each do |k, instances|
        klass = k.constantize
        instances.each { |ident,values| klass.create_or_update ident,values }
        klass.index_update
      end
    end
    
    
  end  

end
