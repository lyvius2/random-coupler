# frozen_string_literal: true

require 'functions/fn_group'

RSpec.describe FnGroup do
  let(:couples) { [] }
  let(:groups)  { [] }
  subject(:fn)  { described_class.new(people, couples, groups) }

  def person(name, gender, workspace)
    { 'name' => name, 'gender' => gender, 'workspace' => workspace }
  end

  describe '#call' do
    context 'group_size가 1 이하일 때' do
      let(:people) { [person('A', 'male', 'ws'), person('B', 'female', 'ws2')] }

      it '에러 메시지를 출력한다' do
        expect { fn.call(1) }.to output(/Group size must be 2 or more/).to_stdout
        expect(groups).to be_empty
      end
    end

    context 'people가 2명 미만일 때' do
      let(:people) { [person('Alice', 'female', 'alpha')] }

      it '에러 메시지를 출력한다' do
        expect { fn.call(2) }.to output(/At least 2 people are required/).to_stdout
      end
    end

    context '4명, group_size=2인 경우' do
      let(:people) do
        [
          person('Alice', 'female', 'a'),
          person('Bob',   'male',   'b'),
          person('Carol', 'female', 'c'),
          person('Dave',  'male',   'd')
        ]
      end

      it '2개의 그룹이 groups에 기록된다' do
        fn.call(2)
        expect(groups.length).to eq(2)
      end

      it '각 그룹에 members와 grouped_at이 포함된다' do
        fn.call(2)
        groups.each do |g|
          expect(g).to include('members', 'grouped_at')
          expect(g['members']).to be_an(Array)
        end
      end

      it '모든 사람이 정확히 한 그룹에 배치된다' do
        fn.call(2)
        all_members = groups.flat_map { |g| g['members'] }
        expect(all_members.sort).to eq(%w[Alice Bob Carol Dave].sort)
      end
    end

    context '[C1] 워크스페이스 인원이 정확히 2명인 경우' do
      let(:people) do
        [
          person('Alice', 'female', 'solo'),
          person('Bob',   'male',   'solo'),
          person('Carol', 'female', 'other'),
          person('Dave',  'male',   'other2')
        ]
      end

      it 'Alice と Bob は同じグループにならない' do
        20.times { groups.clear; fn.call(2) }
        same_group = groups.any? do |g|
          g['members'].include?('Alice') && g['members'].include?('Bob')
        end
        expect(same_group).to be false
      end
    end

    context '[C3] 최근 활동자가 있을 때' do
      let(:people) do
        [
          person('Alice', 'female', 'a'),
          person('Bob',   'male',   'b'),
          person('Carol', 'female', 'c'),
          person('Dave',  'male',   'd')
        ]
      end

      before do
        couples << {
          'person1'    => 'Alice',
          'person2'    => 'Bob',
          'coupled_at' => Time.now.iso8601
        }
      end

      it '최근 활동자(Alice, Bob)는 그룹에 포함되지 않는다' do
        fn.call(2)
        all_members = groups.flat_map { |g| g['members'] }
        expect(all_members).not_to include('Alice', 'Bob')
      end

      it '스킵 안내 메시지를 출력한다' do
        expect { fn.call(2) }.to output(/skipped due to.*-day rule/).to_stdout
      end
    end

    context '활동자 제외 후 eligible이 2명 미만인 경우' do
      let(:people) do
        [person('Alice', 'female', 'a'), person('Bob', 'male', 'b')]
      end

      before do
        couples << {
          'person1'    => 'Alice',
          'person2'    => 'Bob',
          'coupled_at' => Time.now.iso8601
        }
      end

      it '에러 메시지를 출력하고 groups를 변경하지 않는다' do
        expect { fn.call(2) }.to output(/Not enough eligible people/).to_stdout
        expect(groups).to be_empty
      end
    end

    context '남은 인원이 group_size보다 적을 때(나머지 편성)' do
      let(:people) do
        [
          person('Alice', 'female', 'a'),
          person('Bob',   'male',   'b'),
          person('Carol', 'female', 'c')
        ]
      end

      it '3명을 group_size=2로 나누면 1개의 3인 그룹 또는 2인+1인으로 처리된다' do
        fn.call(2)
        total_members = groups.flat_map { |g| g['members'] }.length
        expect(total_members).to eq(3)
      end
    end
  end
end