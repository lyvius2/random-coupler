# frozen_string_literal: true

class FnInitCouples
  def initialize(couples)
    @couples = couples
  end

  def call
    if @couples.empty?
      puts "No couple records to reset."
      return
    end

    print "Reset all #{@couples.length} couple record(s)? This cannot be undone. (y/n): "
    $stdout.flush
    answer = gets&.chomp&.strip
    unless answer&.downcase == 'y'
      puts "Cancelled."
      return
    end

    @couples.clear
    puts "All couple records have been reset."
  end
end