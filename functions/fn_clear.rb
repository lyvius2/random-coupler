# frozen_string_literal: true

require 'time'

class FnClear
  RECENT_DAYS = 14

  def initialize(couples, groups)
    @couples = couples
    @groups = groups
  end

  def call
    cutoff = Time.now - (RECENT_DAYS * 24 * 60 * 60)

    before_c = @couples.length
    @couples.reject! do |c|
      t = (Time.parse(c['coupled_at']) rescue nil)
      t.nil? || t < cutoff
    end

    before_g = @groups.length
    @groups.reject! do |g|
      t = (Time.parse(g['grouped_at']) rescue nil)
      t.nil? || t < cutoff
    end

    removed_c = before_c - @couples.length
    removed_g = before_g - @groups.length
    total     = removed_c + removed_g

    if total.zero?
      puts "No expired records found. All records are within the last #{RECENT_DAYS} days."
    else
      puts "Cleared #{removed_c} couple record(s) and #{removed_g} group record(s) (total: #{total})."
      puts "Remaining: #{@couples.length} couple record(s), #{@groups.length} group record(s)."
    end
  end
end