#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
# Copyright muflax <mail@muflax.com>, 2013
# License: GNU GPL 3 <http://www.gnu.org/copyleft/gpl.html>

require "date"
require "csv"
require "highline/import"

Log = "logs/#{Time.now.strftime "%Y-%m-%d_%H:%M:%S"}.log"
Dir.mkdir "logs" unless Dir.exists? "logs"

class Test
  def initialize
    @desc = "[override me]"
  end

  def run duration=60
    system "clear"
    puts "--> #{@desc} for #{duration} seconds..."
    ask "[press space to begin]" do |q|
      q.limit = 1
    end
    
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
    CSV.open(Log, "a+") do |f|
      f << [Time.now.strftime("%s"), self.class] + answer
    end
  end
end

class StroopTest < Test
  def initialize *colors
    @colors = colors
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

# get current measurements
puts "Let us pray to the RNG:"
variables = [
             {
              name: "nicotine",
              # rand: [:post, "1mg", "2mg"],
              rand: [:pre, :post],
              wait: true
             },

             {
              name: "caffeine",
              rand: [:pre, :post],
              wait: true
             },

             {
              name: "DXM",
             },
            ]

should_wait = false
variables.each do |var|
  puts " -> #{var[:name]}"

  
  opts = [:yes, :no]
  opts << :randomize if var[:rand]
  
  res = ask opts.map(&:to_s).map{|s| "(#{s[0]})#{s[1..-1]}"}.join(" ") do |q|
    q.limit = 1
    q.in = opts.map {|o| o.to_s[0]}
  end

  # get dose 
  dose = :none
  case opts.find{|o| o.to_s[0] == res}
  when :yes
    dose = ask "enter dose"
  when :no
    # skip
  when :randomize
    # TODO support for blinding
    dose = var[:rand].sample
    case dose
    when :pre
      puts "Apply to brain now."
      should_wait ||= var[:wait]
    when :post
      puts "Skip it."
    else
      puts "RNG prescribes: #{r}"
    end
  end

  # log it
  CSV.open(Log, "a+") do |f|
    f << [Time.now.strftime("%s"), "var: #{var[:name]}", dose]
  end

end

# allow for the drug to take effect
if should_wait
  puts "You should wait for 5 minutes. Do stuff, I'll remind you."
  sleep(5*60)
  system "gxmessage -timeout 5 'Science time!' &"
  system "mplayer -really-quiet alarm.mp3"
end

# run tests
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
