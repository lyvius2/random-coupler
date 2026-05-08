#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'time'

require_relative 'functions/fn_add'
require_relative 'functions/fn_list'
require_relative 'functions/fn_couple'
require_relative 'functions/fn_group'
require_relative 'functions/fn_clear'
require_relative 'functions/fn_init_people'
require_relative 'functions/fn_init_couples'
require_relative 'functions/fn_init_groups'

class RandomCoupler
  DATA_FILE = 'data'
  REQUIRED_FIELDS = %w[name gender workspace].freeze

  def initialize
    @people  = []
    @couples = []
    @groups  = []
    load_data
    at_exit { save_data }
  end

  def run
    display_welcome
    loop do
      print "\n> "
      $stdout.flush
      input = gets&.chomp&.strip
      break if input.nil?

      case input
      when '/add'
        FnAdd.new(@people).call
      when '/list'
        FnList.new(@people, @couples, @groups).call
      when '/couple'
        FnCouple.new(@people, @couples, @groups).call
      when /\A\/group_(\d+)\z/
        FnGroup.new(@people, @couples, @groups).call($1.to_i)
      when '/clear'
        FnClear.new(@couples, @groups).call
      when '/init_people'
        FnInitPeople.new(@people).call
      when '/init_couples', '/init_couple'
        FnInitCouples.new(@couples).call
      when '/init_groups', '/init_group'
        FnInitGroups.new(@groups).call
      when '/quit'
        quit
        break
      when ''
        # 빈 입력 무시
      else
        puts "Unknown command. Available commands: /add, /list, /couple, /group_N, /clear, /init_people, /init_couples, /init_groups, /quit"
      end
    end
  end

  private

  def display_welcome
    puts '=' * 40
    puts '         Random Coupler'
    puts '=' * 40
    if @people.empty?
      puts "No people registered. Use /add to add data."
    else
      puts "Loaded #{@people.length} people from data file."
    end
    puts "Commands: /add, /list, /couple, /group_N, /clear, /init_people, /init_couples, /init_groups, /quit"
  end

  def quit
    puts "Goodbye!"
  end

  def load_data
    return unless File.exist?(DATA_FILE)

    begin
      content = File.read(DATA_FILE)
      data = JSON.parse(content)

      unless valid_data_structure?(data)
        puts "Warning: Data file has an invalid structure. Starting with empty state."
        return
      end

      @people  = data['people']
      @couples = data['couples']
      @groups  = data['groups'] || []
      puts "Data loaded: #{@people.length} people, #{@couples.length} couple record(s), #{@groups.length} group record(s)."
    rescue JSON::ParserError => e
      puts "Warning: Failed to parse data file (#{e.message}). Starting with empty state."
    end
  end

  def valid_data_structure?(data)
    return false unless data.is_a?(Hash)
    return false unless data['people'].is_a?(Array)
    return false unless data['couples'].is_a?(Array)

    people_valid = data['people'].all? do |p|
      p.is_a?(Hash) && REQUIRED_FIELDS.all? { |f| p.key?(f) }
    end
    couples_valid = data['couples'].all? do |c|
      c.is_a?(Hash) && %w[person1 person2 coupled_at].all? { |f| c.key?(f) }
    end
    groups_valid = !data.key?('groups') || data['groups'].is_a?(Array) && data['groups'].all? do |g|
      g.is_a?(Hash) && g['members'].is_a?(Array) && g.key?('grouped_at')
    end

    people_valid && couples_valid && groups_valid
  end

  def save_data
    data = { 'people' => @people, 'couples' => @couples, 'groups' => @groups }
    File.write(DATA_FILE, JSON.pretty_generate(data))
    puts "Data saved to '#{DATA_FILE}'."
  end
end

RandomCoupler.new.run if __FILE__ == $PROGRAM_NAME