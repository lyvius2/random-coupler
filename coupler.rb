#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'time'

class RandomCoupler
  DATA_FILE = 'data'
  REQUIRED_FIELDS = %w[name gender workspace].freeze
  RECENT_DAYS = 14

  def initialize
    @people  = []
    @couples = []   # /couple 기록
    @groups  = []   # /group_N 기록
    load_data
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
        add_people
      when '/list'
        list_people
      when '/couple'
        couple_people
      when /\A\/group_(\d+)\z/
        group_people($1.to_i)
      when '/clear'
        clear_old_records
      when '/init_people'
        init_people
      when '/init_couples', '/init_couple'
        init_couples
      when '/init_groups', '/init_group'
        init_groups
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

  # ------------------------------------------
  # 시작 / 종료
  # ------------------------------------------

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
    save_data
    puts "Goodbye!"
  end

  # ------------------------------------------
  # 데이터 파일 I/O
  # ------------------------------------------

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
    # groups 키는 선택적 (구버전 데이터 파일 호환)
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

  # ------------------------------------------
  # /add 명령어
  # ------------------------------------------

  def add_people
    loop do
      person = prompt_person
      break if person.nil?          # 입력 스트림 종료 시 탈출

      @people << person
      puts "Registered: #{person['name']} | #{person['gender']} | #{person['workspace']}"
      puts "Total people: #{@people.length}"

      break unless ask_continue?   # 추가 등록 여부 확인
    end
  end

  # 한 명의 정보를 순차적으로 입력받아 person hash를 반환한다.
  # 오류가 발생하면 해당 항목부터 다시 묻는다. 입력 스트림이 끊기면 nil을 반환한다.
  def prompt_person
    # 1. 이름 입력
    print "  Name: "
    $stdout.flush
    name = gets&.chomp&.strip
    return nil if name.nil?

    if name.empty?
      puts "Error: Name cannot be empty. Please start over."
      return prompt_person
    end

    # 2. 성별 입력 (m / f, 대소문자 무관)
    gender = prompt_gender
    return nil if gender.nil?

    # 3. 워크스페이스 입력 (대소문자 무관 → 소문자로 정규화)
    print "  Workspace: "
    $stdout.flush
    workspace = gets&.chomp&.strip
    return nil if workspace.nil?

    if workspace.empty?
      puts "Error: Workspace cannot be empty. Please start over."
      return prompt_person
    end

    { 'name' => name, 'gender' => gender, 'workspace' => workspace.downcase }
  end

  # 성별을 입력받는다. 유효하지 않으면 오류 메시지 후 재입력 요청.
  def prompt_gender
    print "  Gender (m/f): "
    $stdout.flush
    raw = gets&.chomp&.strip
    return nil if raw.nil?

    case raw.downcase
    when 'm' then 'male'
    when 'f' then 'female'
    else
      puts "Error: Invalid gender '#{raw}'. Please enter 'm' (male) or 'f' (female)."
      prompt_gender
    end
  end

  # 추가 등록 여부를 y/n으로 묻는다. 대소문자 무관.
  def ask_continue?
    loop do
      print "  Add another person? (y/n): "
      $stdout.flush
      answer = gets&.chomp&.strip
      return false if answer.nil?

      case answer.downcase
      when 'y' then return true
      when 'n' then return false
      else
        puts "Error: Please enter 'y' or 'n'."
      end
    end
  end

  # ------------------------------------------
  # /list 명령어
  # ------------------------------------------

  def list_people
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

  # ------------------------------------------
  # /clear 명령어
  # ------------------------------------------

  # 만료된 커플·그룹 기록(RECENT_DAYS일 초과)을 모두 삭제한다.
  def clear_old_records
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

  # ------------------------------------------
  # /init_people / /init_couples 명령어
  # ------------------------------------------

  # 사람 데이터를 전체 초기화한다. 확인 후 실행.
  def init_people
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

  # 커플 기록을 전체 초기화한다. 확인 후 실행.
  def init_couples
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

  # 그룹 기록을 전체 초기화한다. 확인 후 실행.
  def init_groups
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

  # ------------------------------------------
  # /couple 명령어
  # ------------------------------------------

  def couple_people
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

  # ------------------------------------------
  # /group_N 명령어
  # ------------------------------------------

  def group_people(group_size)
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

  # ------------------------------------------
  # 제약 조건 검사
  # ------------------------------------------

  # 최근 RECENT_DAYS일 이내 커플·그룹 기록에 등장한 사람 이름 목록을 반환한다.
  # /couple 과 /group_N 양쪽 모두 참조한다.
  def recently_active_names
    cutoff = Time.now - (RECENT_DAYS * 24 * 60 * 60)
    names = []

    @couples.each do |c|
      t = (Time.parse(c['coupled_at']) rescue nil)
      next unless t && t >= cutoff
      names << c['person1'] << c['person2']
    end

    @groups.each do |g|
      t = (Time.parse(g['grouped_at']) rescue nil)
      next unless t && t >= cutoff
      names.concat(g['members'])
    end

    names.uniq
  end

  # p1과 p2를 같은 그룹(또는 커플)에 넣을 수 있는지 C1·C2 기준으로 판단한다.
  # C3(차단 목록)는 호출 측에서 사전 필터링한다.
  def can_pair_in_group?(p1, p2)
    same_ws = p1['workspace'] == p2['workspace']

    if same_ws
      ws_count = @people.count { |p| p['workspace'] == p1['workspace'] }

      # [C1] 워크스페이스 인원이 정확히 2명이면 서로 같은 그룹 불가.
      return false if ws_count == 2

      # [C2] 같은 워크스페이스·gender 그룹이 3명 이하이면 같은 그룹 불가.
      if p1['gender'] == p2['gender']
        sg_count = @people.count { |p| p['workspace'] == p1['workspace'] && p['gender'] == p1['gender'] }
        return false if sg_count <= 3
      end
    end

    true
  end

  # 그룹 내 모든 2인 조합이 C1·C2를 만족하면 true를 반환한다.
  def valid_group?(group)
    group.combination(2).all? { |p1, p2| can_pair_in_group?(p1, p2) }
  end

  # ------------------------------------------
  # /couple 매칭 알고리즘
  # ------------------------------------------

  # 유효한 쌍을 모두 구한 뒤 무작위로 1쌍을 반환한다.
  # 유효한 쌍이 없으면 nil을 반환한다.
  def find_random_pair
    blocked = recently_active_names
    eligible = @people.reject { |p| blocked.include?(p['name']) }
    valid_pairs = eligible.combination(2).select { |p1, p2| can_pair_in_group?(p1, p2) }
    valid_pairs.sample
  end

  # ------------------------------------------
  # /group_N 그룹핑 알고리즘
  # ------------------------------------------

  # eligible 목록을 group_size 정원으로 나눠 그룹 배열을 반환한다.
  # 유효한 배치를 찾지 못하면 nil을 반환한다.
  def find_valid_groups(eligible, group_size)
    200.times do
      result = backtrack_groups(eligible.shuffle, [], group_size)
      return result if result
    end
    nil
  end

  # 재귀 백트래킹으로 그룹 배치를 탐색한다.
  def backtrack_groups(remaining, groups, group_size)
    return groups if remaining.empty?

    # 남은 인원이 1명 → 마지막 그룹에 정원 초과 편입
    if remaining.length == 1
      return nil if groups.empty?
      return groups[0..-2] + [groups.last + remaining]
    end

    # 남은 인원이 group_size 미만 → 제약 없이 마지막 그룹으로 편성
    if remaining.length < group_size
      return groups + [remaining]
    end

    # 정상 케이스: remaining[0]을 포함한 group_size 조합 탐색
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

RandomCoupler.new.run if __FILE__ == $PROGRAM_NAME
