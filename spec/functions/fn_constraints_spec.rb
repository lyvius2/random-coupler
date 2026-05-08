# frozen_string_literal: true

require 'functions/fn_constraints'

# FnConstraints モジュールを直接テストするためのスタブクラス
class ConstraintsTestHost
  include FnConstraints

  attr_accessor :people, :couples, :groups

  def initialize(people: [], couples: [], groups: [])
    @people  = people
    @couples = couples
    @groups  = groups
  end

  public :recently_active_names, :can_pair_in_group?, :valid_group?
end

RSpec.describe FnConstraints do
  def person(name, gender, workspace)
    { 'name' => name, 'gender' => gender, 'workspace' => workspace }
  end

  describe 'RECENT_DAYS' do
    it '14が定義されている' do
      expect(FnConstraints::RECENT_DAYS).to eq(14)
    end
  end

  describe '#recently_active_names' do
    let(:host) { ConstraintsTestHost.new(people: [], couples: couples, groups: groups) }
    let(:couples) { [] }
    let(:groups)  { [] }

    let(:recent_time) { Time.now.iso8601 }
    let(:old_time)    { (Time.now - (FnConstraints::RECENT_DAYS + 1) * 24 * 60 * 60).iso8601 }

    context '최근 couple 기록이 있을 때' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => recent_time }
      end

      it 'Alice와 Bob이 포함된다' do
        expect(host.recently_active_names).to include('Alice', 'Bob')
      end
    end

    context '만료된 couple 기록만 있을 때' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => old_time }
      end

      it '빈 배열을 반환한다' do
        expect(host.recently_active_names).to be_empty
      end
    end

    context '최근 group 기록이 있을 때' do
      before do
        groups << { 'members' => %w[Carol Dave Eve], 'grouped_at' => recent_time }
      end

      it 'グループ全員が含まれる' do
        expect(host.recently_active_names).to include('Carol', 'Dave', 'Eve')
      end
    end

    context '중복 이름이 있을 때' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => recent_time }
        groups  << { 'members' => %w[Alice Carol], 'grouped_at' => recent_time }
      end

      it '이름이 중복 없이 반환된다' do
        names = host.recently_active_names
        expect(names.uniq).to eq(names)
        expect(names).to include('Alice', 'Bob', 'Carol')
      end
    end

    context '유효하지 않은 timestamp가 있을 때' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => 'invalid' }
      end

      it '해당 기록을 무시한다' do
        expect(host.recently_active_names).to be_empty
      end
    end
  end

  describe '#can_pair_in_group?' do
    context '서로 다른 워크스페이스' do
      let(:people) { [person('Alice', 'female', 'a'), person('Bob', 'male', 'b')] }
      let(:host)   { ConstraintsTestHost.new(people: people) }

      it '항상 true를 반환한다' do
        expect(host.can_pair_in_group?(people[0], people[1])).to be true
      end
    end

    context '[C1] 같은 워크스페이스에 2명만 있을 때' do
      let(:people) { [person('Alice', 'female', 'solo'), person('Bob', 'male', 'solo')] }
      let(:host)   { ConstraintsTestHost.new(people: people) }

      it 'false를 반환한다' do
        expect(host.can_pair_in_group?(people[0], people[1])).to be false
      end
    end

    context '[C2] 같은 워크스페이스·동성이 3명 이하일 때' do
      let(:people) do
        [
          person('Alice', 'female', 'ws'),
          person('Carol', 'female', 'ws'),
          person('Bob',   'male',   'ws')
        ]
      end
      let(:host) { ConstraintsTestHost.new(people: people) }

      it '동성 2명은 false를 반환한다' do
        expect(host.can_pair_in_group?(people[0], people[1])).to be false
      end

      it '이성 2명은 true를 반환한다(C1: 워크스페이스에 3명이므로 통과)' do
        expect(host.can_pair_in_group?(people[0], people[2])).to be true
      end
    end

    context '같은 워크스페이스·동성이 4명 이상일 때' do
      let(:people) do
        [
          person('A', 'female', 'ws'),
          person('B', 'female', 'ws'),
          person('C', 'female', 'ws'),
          person('D', 'female', 'ws')
        ]
      end
      let(:host) { ConstraintsTestHost.new(people: people) }

      it '[C2]가 적용되지 않아 true를 반환한다' do
        expect(host.can_pair_in_group?(people[0], people[1])).to be true
      end
    end
  end

  describe '#valid_group?' do
    context '모든 쌍이 유효한 그룹' do
      let(:people) do
        [
          person('Alice', 'female', 'a'),
          person('Bob',   'male',   'b'),
          person('Carol', 'female', 'c')
        ]
      end
      let(:host) { ConstraintsTestHost.new(people: people) }

      it 'true를 반환한다' do
        expect(host.valid_group?(people)).to be true
      end
    end

    context 'C1을 위반하는 쌍이 포함된 그룹' do
      let(:people) do
        [person('Alice', 'female', 'solo'), person('Bob', 'male', 'solo')]
      end
      let(:host) { ConstraintsTestHost.new(people: people) }

      it 'false를 반환한다' do
        expect(host.valid_group?(people)).to be false
      end
    end
  end
end