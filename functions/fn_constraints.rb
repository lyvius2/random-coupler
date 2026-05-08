# frozen_string_literal: true

require 'time'

module FnConstraints
  RECENT_DAYS = 14

  private

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

  def valid_group?(group)
    group.combination(2).all? { |p1, p2| can_pair_in_group?(p1, p2) }
  end
end
