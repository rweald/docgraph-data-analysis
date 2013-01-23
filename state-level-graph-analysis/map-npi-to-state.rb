#!/usr/bin/env ruby
# encoding: utf-8

STDIN.each do |line|
  vals = line.split(",")
  if vals.length > 2
    puts "Invalid line with more than 1 comma"
    next
  end
  (npi, state) = vals
  npi = npi.gsub(/"/, "").strip
  state = state.gsub(/"/, "").strip
  if state.length <= 2
    puts "#{npi},#{state}"
    #puts "Weird state name for npi - #{npi} with value - #{state}"
  end
end
