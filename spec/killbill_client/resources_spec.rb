require 'spec_helper'

describe KillBillClient::Model::Resources do
  it 'should respect .each methods' do
    stuff = KillBillClient::Model::Resources.new
    1.upto(10).each { |i| stuff << i }
    stuff.size.should == 10

    stuff.each_with_index { |i,idx| i.should == idx + 1 }

    idx = 1
    stuff.each do |i|
      i.should == idx
      idx += 1
    end
  end
end
