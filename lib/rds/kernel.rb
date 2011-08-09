module Kernel
  
  def load!
    load 'rds/support/kernel.rb'
    load 'lib/rds/base.rb'
    load 'lib/rds/models/domino.rb'
#    load '../rdomino/lib/rdomino/item.rb'
#    @testbed = Rdomino::Database[:testbed].extend Rdomino::Db::Registration
  end
  
  def colon *a
    a.compact.join ':'
  end
   
end
