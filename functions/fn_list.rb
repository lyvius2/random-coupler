# frozen_string_literal: true

require 'json'

class FnList
  def initialize(people, couples, groups)
    @people = people
    @couples = couples
    @groups = groups
  end

  def call
    puts "\n#{'=' * 40}"
    puts "  People (#{@people.length})"
    puts '=' * 40
    if @people.empty?
      puts "  (none)"
    else
      puts JSON.pretty_generate(@people)
    end

    puts "\n#{'=' * 40}"
    puts "  Couple Records (#{@couples.length})"
    puts '=' * 40
    if @couples.empty?
      puts "  (none)"
    else
      puts JSON.pretty_generate(@couples)
    end

    puts "\n#{'=' * 40}"
    puts "  Group Records (#{@groups.length})"
    puts '=' * 40
    if @groups.empty?
      puts "  (none)"
    else
      puts JSON.pretty_generate(@groups)
    end
  end
end