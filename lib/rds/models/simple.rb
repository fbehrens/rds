class Replica
  include Rds::Model
  
  belongs_to          :database
  belongs_to          :server
  belongs_to          :databasescript_script, :class_name => 'Script'
  field_accessor      :title, :icon, :consistent?
  counter             :popups
  time_accessor       :created_at
  multivalue_accessor :multi
  sorted_accessor     :sorted
  create_index        :icon , :title ,:_title , :icon_letter,:consistent?
 
  scope :mydb, :title => 'mydb'
  scope :a,    :icon  => 'a'
  scope :consistent?
  scope :combined, :consistent?, :title => 'mydb'
  
  def icon_letter
    icon.scan /./
  end
  
  def _title
    "_#{title}" if title 
  end
  
end

class Database
  include Rds::Model
  
  has_many :replicas
end

class Server
  include Rds::Model
  
  has_many :replicas
end

class Script
  include Rds::Model
  has_many :replicas
end
