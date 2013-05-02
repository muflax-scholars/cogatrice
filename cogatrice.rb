#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
# Copyright muflax <mail@muflax.com>, 2013
# License: GNU GPL 3 <http://www.gnu.org/copyleft/gpl.html>

require "date"
require "csv"
require "highline/import"

class Test
  def initialize
    @log  = "test.log"
    @desc = "[override me]"
  end

  def run duration=60
    system "clear"
    puts "--> #{@desc} for #{duration} seconds..."
    ask "[press space to begin]" do |q|
      q.limit = 1
    end
    log ["new session"]
    
    start = Time.now
    t = 0
    while t <= duration
      system "clear"
      answer = show_prompt
      log answer
      
      t = Time.now - start
    end
  end

  def show_prompt
    # override and return all results
    
    []
  end

  def log answer
    CSV.open(@log, "a+") do |f|
      f << [Time.now.strftime("%s")] + answer
    end
  end
end

class StroopTest < Test
  def initialize *colors
    @colors = colors
    @log  = "stroop.log"
    @desc = "Stroop test with #{colors.size} colors"
  end

  def show_prompt
    word, color = @colors.sample(2) # ensure incongruent stimuli
    correct_res = color.to_s[0]

    t = Time.now
    res = ask HighLine.color("#{word}", color) do |q|
      q.limit = 1
    end
    dt = Time.now - t

    [res == correct_res, dt, @colors, word, color, res, correct_res]
  end
end

class NBackTest < Test
  def initialize n=2
    @n    = n
    @log  = "nback.log"
    @desc = "Single n-back test with n = #{n}"
    
    @prompts = []
  end

  def show_prompt
    prompt      = (@prompts.size > @n and rand() < 0.3) ? @prompts[-@n] : rand(0..9)
    correct_res = (@prompts.size > @n and @prompts[-@n] == prompt) ? "y" : "n"
    
    t = Time.now
    res = ask "#{prompt}" do |q|
      q.limit = 1
    end
    dt = Time.now - t

    # remember prompt for next round
    @prompts << prompt

    [res == correct_res, dt, @n, prompt, @prompts.size, res, correct_res]
  end
end

class ArithmeticTest < Test
  def initialize *operants
    @operants = operants
    @log      = "arithmetic.log"
    @desc     = "Arithmetic test with #{operants.size} operants"
  end

  def show_prompt
    a  = rand(0..9)
    b  = rand(0..9)
    op = @operants.sample
    correct_res = a.send(op, b).to_s[-1]

    t = Time.now
    res = ask "#{a} #{op} #{b} = ?" do |q|
      q.limit = 1
    end
    dt = Time.now - t

    [res == correct_res, dt, @operants, a, op, b, res, correct_res]
  end
end

tests = [
         ArithmeticTest.new(:+, :-, :*),
         NBackTest.new(3),
         StroopTest.new(:red, :green, :yellow, :blue, :magenta),
        ]
         
duration = 2*60 # per test

tests.each do |test|
  test.run duration
end

puts "done"
