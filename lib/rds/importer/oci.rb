require 'oci8'
module Rds
  module Importer
    class Oci
      include Enumerable
      
      def self.connection
        @connection || begin 
          config = Registration.oci
          con = OCI8.new(config['username'] , config['password'],config['database'] )
          con.autocommit = true
          con.exec "alter session set cursor_sharing = similar" rescue nil
          con      
        end
      end
        
      def initialize(klass)
        @sql = "select * from #{klass.name}_rds"
      end
      
      def column_names
        @column_names ||= @cursor.column_metadata.map{|c| c.name.downcase.to_sym }
      end
      
      def to_hash row
        column_names.inject({}) do |sum,column|
          sum[column] = row.shift
          sum
        end
      end
      
      def each
        @cursor = self.class.connection.exec @sql
        counter = 0
        while r = @cursor.fetch()
          counter += 1
          yield to_hash(r)
        end
        counter
      end
      
      def attributes(ident)
        @cursor = self.class.connection.exec "#{@sql} where \"ident\"='#{ident}'"
        if r = @cursor.fetch()
          to_hash(r).delete :ident
        end
      end

    end
  end
end
