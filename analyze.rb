#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
# Copyright muflax <mail@muflax.com>, 2013
# License: GNU GPL 3 <http://www.gnu.org/copyleft/gpl.html>

# Analyzes past data.
require "awesome_print"
require "csv"
require "date"

# outputs
vars          = Hash.new {|h,k| h[k] = Hash.new(0)}
interventions = Hash.new {|h,k| h[k] = Hash.new(0)}
scores        = Hash.new {|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = []}}

class String
  def to_bool
    case self
    when "true"
      true
    when "false"
      false
    else
      nil
    end
  end
end
    

# get log data
logs = Dir["logs/*.log"].sort
logs.each do |log|
  puts "reading #{log}..."
  
  CSV.open(log).each do |row|
    timestamp, type, *data = row
    day = DateTime.strptime(timestamp, "%s").to_date
    
    case type
    when /^variable:/
      var = type.match(/variable: (.+)$/)[1]
      vars[day][var] = data[0].to_i
    when /^intervention:/
      var = type.match(/intervention: (.+)$/)[1]
      interventions[day][var] = data[0]
    when "ArithmeticTest"
      acc  = data[0].to_bool
      time = data[1].to_f
      scores[day]["arithmetic_acc"]  << acc
      scores[day]["arithmetic_time"] << time
    when "NBackTest"
      acc  = data[0].to_bool
      time = data[1].to_f
      scores[day]["nback_acc"]  << acc
      scores[day]["nback_time"] << time
    when "StroopTest"
      acc  = data[0].to_bool
      time = data[1].to_f
      scores[day]["stroop_acc"]  << acc
      scores[day]["stroop_time"] << time
    end
  end
end

# get eventrend data
log = Dir[File.expand_path("~/Dropbox/android/eventrend/*.csv")].sort.last
drugs = Hash.new {|h,k| h[k] = Hash.new(0.0)}
CSV.open(log, :headers => true).each do |row|
  var = row["category_name"]
  day = DateTime.strptime((row["timestamp"].to_i/1000).to_s, "%s").to_date
  drugs[day][var] += row["value"].to_f
end

# aggregate scores
scores_agg = Hash.new {|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = 0.0}}
scores.each do |day, vals|
  vals.each do |type, list|
    agg = case type
          when /_acc$/
            # ignore non-bool values
            valid = list.select{|v| [true, false].include? v}
            valid.reduce(0.0) {|s,t| s + (t ? 1 : 0)} / valid.size
          when /_time$/
            list.reduce(0.0) {|s,t| s+t} / list.size
          end
    scores_agg[day][type] = agg
  end
end

# output data as CSV
Dir.mkdir "analysis" unless Dir.exists? "analysis"

def csv_analysis name, hash
  types = hash.values.flat_map{|v| v.keys}.uniq.sort
  headers = ["day"] + types
  CSV.open("analysis/#{name}.csv", "w+", :headers => headers, :write_headers => true) do |csv|
    hash.each do |day, vals|
      line = []
      types.each do |h|
        line << vals[h]
      end
      csv << [day] + line
    end
  end
end

csv_analysis "vars", vars
csv_analysis "interventions", interventions
csv_analysis "drugs", drugs
csv_analysis "scores_raw", scores
csv_analysis "scores_agg", scores_agg
