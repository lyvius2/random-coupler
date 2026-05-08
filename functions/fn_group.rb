# frozen_string_literal: true

require_relative 'fn_constraints'

class FnGroup
  include FnConstraints

  def initialize(people, couples, groups)
    @people = people
    @couples = couples
    @groups = groups
  end

  def call(group_size)
    if group_size < 2
      puts "Error: Group size must be 2 or more."
      return
    end

    if @people.length < 2
      puts "Error: At least 2 people are required for grouping."
      return
    end

    blocked  = recently_active_names
    eligible = @people.reject { |p| blocked.include?(p['name']) }

    if eligible.length < 2
      puts "\nError: Not enough eligible people."
      puts "  #{blocked.length} person(s) are blocked by the #{RECENT_DAYS}-day rule."
      return
    end

    result = find_valid_groups(eligible, group_size)

    if result.nil?
      puts "\nError: Cannot form valid groups under the current constraints."
      puts "Active constraints:"
      puts "  [C1] A workspace with exactly 2 members: those 2 cannot be in the same group."
      puts "  [C2] People of the same gender in the same workspace (<=3) cannot be in the same group."
      puts "  [C3] Anyone active within the last #{RECENT_DAYS} days is excluded."
      return
    end

    now = Time.now.iso8601
    puts "\n#{'=' * 40}"
    puts "   Group Results (size: #{group_size})"
    puts '=' * 40
    result.each_with_index do |group, i|
      members_str = group.map { |p| p['name'] }.join(', ')
      puts "  Group #{i + 1} [#{group.length}]: #{members_str}"
      @groups << { 'members' => group.map { |p| p['name'] }, 'grouped_at' => now }
    end

    if blocked.any?
      puts "\n  Note: #{blocked.length} person(s) skipped due to #{RECENT_DAYS}-day rule: #{blocked.join(', ')}"
    end
    puts '=' * 40
  end

  private

  def find_valid_groups(eligible, group_size)
    200.times do
      result = backtrack_groups(eligible.shuffle, [], group_size)
      return result if result
    end
    nil
  end

  def backtrack_groups(remaining, groups, group_size)
    return groups if remaining.empty?

    if remaining.length == 1
      return nil if groups.empty?
      return groups[0..-2] + [groups.last + remaining]
    end

    if remaining.length < group_size
      return groups + [remaining]
    end

    first = remaining[0]
    rest  = remaining[1..-1]

    rest.combination(group_size - 1).each do |selected|
      group = [first] + selected
      next unless valid_group?(group)

      new_remaining = rest - selected
      result = backtrack_groups(new_remaining, groups + [group], group_size)
      return result if result
    end

    nil
  end
end