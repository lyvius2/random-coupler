# frozen_string_literal: true

class FnInitGroups
  def initialize(groups)
    @groups = groups
  end

  def call
    if @groups.empty?
      puts "No group records to reset."
      return
    end

    print "Reset all #{@groups.length} group record(s)? This cannot be undone. (y/n): "
    $stdout.flush
    answer = gets&.chomp&.strip
    unless answer&.downcase == 'y'
      puts "Cancelled."
      return
    end

    @groups.clear
    puts "All group records have been reset."
  end
end