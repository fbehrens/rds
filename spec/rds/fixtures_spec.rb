require 'rubygems'
require 'rspec'
require 'rds/fixtures'
require 'stringio'

module Rds

describe Fixtures do
  
  before do
      @f = Fixtures.new StringIO.new(<<-HERE)
Project: |
- |
  ident,name,active,members,budget,novalue
  a    ,aa  ,true  ,a|b    ,42
- |
  ident,name
  a    ,ab
  b    ,b
- |
  ident
  -a
      HERE
    end
    
    it '#data' do
      @f.data.should ==
        {"Project" => 
          [ { ident: 'a',
              name: 'aa',
              active: true,
              members: %w(a b),
              budget: 42 } ] }
    end

    it "#hashed" do
      @f.hashed.should == value =
        {"Project" => 
           { 'a' => 
              { name: 'aa',
                active: true,
                members: %w(a b),
                budget: 42 } } }
      @f.diffed.should == value
      @f.hashed(1).should == value =
        {"Project" => 
           { 'a' => { name: 'ab'},
             'b' => { name: 'b' } } } 
    end

    it '#diffed' do
      @f.diffed(1).should == 
        {"Project" => 
           { 'a' => 
              { name: 'ab',
                active: true,
                members: %w(a b),
                budget: 42 },
             'b' => 
              { name: 'b' } } }
      @f.diffed(2).should == 
        {"Project" => 
           { 'b' => 
              { name: 'b' } } }
    end    

  end

end
