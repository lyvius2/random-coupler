# frozen_string_literal: true

class FnInitPeople
  def initialize(people)
    @people = people
  end

  def call
    if @people.empty?
      puts "No people data to reset."
      return
    end

    print "Reset all #{@people.length} people? This cannot be undone. (y/n): "
    $stdout.flush
    answer = gets&.chomp&.strip
    unless answer&.downcase == 'y'
      puts "Cancelled."
      return
    end

    @people.clear
    puts "All people data has been reset."
  end
end