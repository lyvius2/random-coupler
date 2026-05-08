# frozen_string_literal: true

require 'functions/fn_clear'

RSpec.describe FnClear do
  let(:couples) { [] }
  let(:groups)  { [] }
  subject(:fn)  { described_class.new(couples, groups) }

  let(:recent_time) { Time.now.iso8601 }
  let(:old_time)    { (Time.now - (FnClear::RECENT_DAYS + 1) * 24 * 60 * 60).iso8601 }

  describe '#call' do
    context '만료된 기록이 없을 때' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => recent_time }
        groups  << { 'members' => %w[Alice Bob], 'grouped_at' => recent_time }
      end

      it '"No expired records" 메시지를 출력한다' do
        expect { fn.call }.to output(/No expired records found/).to_stdout
      end

      it 'couples와 groups를 변경하지 않는다' do
        fn.call
        expect(couples.length).to eq(1)
        expect(groups.length).to eq(1)
      end
    end

    context '만료된 couple 기록이 있을 때' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => old_time }
        couples << { 'person1' => 'Carol', 'person2' => 'Dave', 'coupled_at' => recent_time }
      end

      it '만료된 기록만 삭제한다' do
        fn.call
        expect(couples.length).to eq(1)
        expect(couples.first['person1']).to eq('Carol')
      end

      it 'Cleared 메시지를 출력한다' do
        expect { fn.call }.to output(/Cleared 1 couple record/).to_stdout
      end
    end

    context '만료된 group 기록이 있을 때' do
      before do
        groups << { 'members' => %w[Alice Bob], 'grouped_at' => old_time }
        groups << { 'members' => %w[Carol Dave], 'grouped_at' => recent_time }
      end

      it '만료된 기록만 삭제한다' do
        fn.call
        expect(groups.length).to eq(1)
        expect(groups.first['members']).to eq(%w[Carol Dave])
      end

      it 'Cleared 메시지를 출력한다' do
        expect { fn.call }.to output(/Cleared 0 couple record\(s\) and 1 group record/).to_stdout
      end
    end

    context '유효하지 않은 timestamp가 있을 때' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => 'invalid' }
      end

      it '해당 기록을 삭제한다' do
        fn.call
        expect(couples).to be_empty
      end
    end

    context '모든 기록이 만료된 경우' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => old_time }
        groups  << { 'members' => %w[Carol Dave], 'grouped_at' => old_time }
      end

      it 'couples와 groups가 모두 비워진다' do
        fn.call
        expect(couples).to be_empty
        expect(groups).to be_empty
      end

      it '남은 레코드 수를 출력한다' do
        expect { fn.call }.to output(/Remaining: 0 couple/).to_stdout
      end
    end
  end
end