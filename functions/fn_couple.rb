# frozen_string_literal: true

require_relative 'fn_constraints'

class FnCouple
  include FnConstraints

  def initialize(people, couples, groups)
    @people = people
    @couples = couples
    @groups = groups
  end

  def call
    if @people.length < 2
      puts "Error: At least 2 people are required for matching."
      return
    end

    pair = find_random_pair

    if pair.nil?
      puts "\nError: No valid pair exists under the current constraints."
      puts "Active constraints:"
      puts "  [C1] A workspace with exactly 2 members cannot pair those 2 together."
      puts "  [C2] People of the same gender in the same workspace (<=3) cannot pair with each other."
      puts "  [C3] Anyone active (coupled/grouped) within the last #{RECENT_DAYS} days is excluded."
      return
    end

    p1, p2 = pair
    now = Time.now.iso8601
    @couples << { 'person1' => p1['name'], 'person2' => p2['name'], 'coupled_at' => now }

    puts "\n#{'=' * 40}"
    puts "          Matching Result"
    puts '=' * 40
    puts "  #{p1['name']} (#{p1['workspace']}/#{p1['gender']}) " \
         "<-> #{p2['name']} (#{p2['workspace']}/#{p2['gender']})"
    puts '=' * 40
  end

  private

  def find_random_pair
    blocked = recently_active_names
    eligible = @people.reject { |p| blocked.include?(p['name']) }
    valid_pairs = eligible.combination(2).select { |p1, p2| can_pair_in_group?(p1, p2) }
    valid_pairs.sample
  end
end