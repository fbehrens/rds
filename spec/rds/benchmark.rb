require 'helper'
require 'benchmark'

module Rds
  
  describe 'Redis' do
    
    before(:all) do
      @base = Base.new.flushdb
      @r = @base.redis
    end
    
    it '#string' do
      n = 20000
      Benchmark.bm do |x|
        x.report('set') { n.times { |i|   @r.set "s#{i}",i}}
        x.report('sadd') { n.times { |i|  @r.sadd "set#{i}",i}}
      end
    end

    it '#for' do    
      n = 50000
      Benchmark.bm do |x|
        x.report { for i in 1..n; a = "1"; end }
        x.report { n.times do   ; a = "1"; end }
      end
    end
    
  end

end
