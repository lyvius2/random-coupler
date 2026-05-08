# frozen_string_literal: true

require 'functions/fn_list'

RSpec.describe FnList do
  let(:people)  { [] }
  let(:couples) { [] }
  let(:groups)  { [] }
  subject(:fn)  { described_class.new(people, couples, groups) }

  describe '#call' do
    context '전체 데이터가 비어 있을 때' do
      it '각 섹션에 (none)을 출력한다' do
        expect { fn.call }.to output(/\(none\)/).to_stdout
      end

      it 'People (0) 헤더를 출력한다' do
        expect { fn.call }.to output(/People \(0\)/).to_stdout
      end

      it 'Couple Records (0) 헤더를 출력한다' do
        expect { fn.call }.to output(/Couple Records \(0\)/).to_stdout
      end

      it 'Group Records (0) 헤더를 출력한다' do
        expect { fn.call }.to output(/Group Records \(0\)/).to_stdout
      end
    end

    context 'people에 데이터가 있을 때' do
      before { people << { 'name' => 'Alice', 'gender' => 'female', 'workspace' => 'alpha' } }

      it 'people 수를 헤더에 표시한다' do
        expect { fn.call }.to output(/People \(1\)/).to_stdout
      end

      it 'people 이름을 출력한다' do
        expect { fn.call }.to output(/Alice/).to_stdout
      end
    end

    context 'couples에 데이터가 있을 때' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => Time.now.iso8601 }
      end

      it 'couple 수를 헤더에 표시한다' do
        expect { fn.call }.to output(/Couple Records \(1\)/).to_stdout
      end

      it 'couple 구성원을 출력한다' do
        expect { fn.call }.to output(/Alice.*Bob/m).to_stdout
      end
    end

    context 'groups에 데이터가 있을 때' do
      before do
        groups << { 'members' => %w[Alice Bob Charlie], 'grouped_at' => Time.now.iso8601 }
      end

      it 'group 수를 헤더에 표시한다' do
        expect { fn.call }.to output(/Group Records \(1\)/).to_stdout
      end

      it 'group 구성원을 출력한다' do
        expect { fn.call }.to output(/Charlie/).to_stdout
      end
    end
  end
end