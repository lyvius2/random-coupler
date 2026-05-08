# frozen_string_literal: true

require 'functions/fn_couple'

RSpec.describe FnCouple do
  let(:couples) { [] }
  let(:groups)  { [] }
  subject(:fn)  { described_class.new(people, couples, groups) }

  def person(name, gender, workspace)
    { 'name' => name, 'gender' => gender, 'workspace' => workspace }
  end

  describe '#call' do
    context 'people가 2명 미만일 때' do
      let(:people) { [person('Alice', 'female', 'alpha')] }

      it '에러 메시지를 출력하고 couples를 변경하지 않는다' do
        expect { fn.call }.to output(/At least 2 people are required/).to_stdout
        expect(couples).to be_empty
      end
    end

    context '유효한 쌍이 존재할 때' do
      let(:people) do
        [person('Alice', 'female', 'alpha'), person('Bob', 'male', 'beta')]
      end

      it 'couples에 기록을 추가한다' do
        fn.call
        expect(couples.length).to eq(1)
      end

      it '추가된 기록에 person1, person2, coupled_at이 포함된다' do
        fn.call
        record = couples.first
        expect(record).to include('person1', 'person2', 'coupled_at')
      end

      it '매칭 결과를 출력한다' do
        expect { fn.call }.to output(/Matching Result/).to_stdout
      end
    end

    context '[C1] 워크스페이스 인원이 정확히 2명인 경우' do
      let(:people) do
        [person('Alice', 'female', 'solo'), person('Bob', 'male', 'solo')]
      end

      it '유효한 쌍이 없어 에러 메시지를 출력한다' do
        expect { fn.call }.to output(/No valid pair exists/).to_stdout
        expect(couples).to be_empty
      end
    end

    context '[C2] 같은 워크스페이스·동성이 3명 이하인 경우' do
      let(:people) do
        [
          person('Alice', 'female', 'ws'),
          person('Carol', 'female', 'ws'),
          person('Dave',  'male',   'other')
        ]
      end

      it 'Alice와 Carol은 매칭되지 않는다' do
        results = 20.times.map do
          couples.clear
          fn.call
          couples.last&.values_at('person1', 'person2')
        end.compact
        paired_together = results.any? { |pair| pair.sort == %w[Alice Carol] }
        expect(paired_together).to be false
      end
    end

    context '[C3] 최근 RECENT_DAYS일 이내 활동자 제외' do
      let(:people) do
        [
          person('Alice', 'female', 'a'),
          person('Bob',   'male',   'b'),
          person('Carol', 'female', 'c'),
          person('Dave',  'male',   'd')
        ]
      end

      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => Time.now.iso8601 }
      end

      it '최근 활동자(Alice, Bob)는 매칭 후보에서 제외된다' do
        fn.call
        new_record = couples.last
        names = [new_record['person1'], new_record['person2']]
        expect(names).not_to include('Alice')
        expect(names).not_to include('Bob')
      end
    end

    context '유효한 쌍이 전혀 없을 때' do
      let(:people) do
        [person('Alice', 'female', 'solo'), person('Bob', 'male', 'solo')]
      end

      it '제약 조건 목록을 출력한다' do
        output = capture_output { fn.call }
        expect(output).to include('[C1]', '[C2]', '[C3]')
      end
    end
  end

  def capture_output
    output = ''
    allow($stdout).to receive(:puts) { |*args| output += args.join("\n") + "\n" }
    allow($stdout).to receive(:print) { |*args| output += args.join }
    yield
    output
  end
end