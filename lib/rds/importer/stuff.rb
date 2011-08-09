class Person
  class << self
    def import_oci
      require 'rds/importer/oci'
      Replica.delete_association :persons
      temp_index(:import?) do |i|
        if Rds::Importer::Oci.new(self).each do |hash|
            i << create_or_update_hash(hash)
          end == p(i.scope.count) 
          i.scope.inverse.each(&:delete)
        end
      end
      Replica.delete_without :people
    end
    
  end
  
end
