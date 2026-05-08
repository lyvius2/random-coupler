# frozen_string_literal: true

require 'functions/fn_add'

RSpec.describe FnAdd do
  let(:people) { [] }
  subject(:fn) { described_class.new(people) }

  def stub_inputs(*lines)
    allow(fn).to receive(:gets).and_return(*lines.map { |l| l&.then { "#{l}\n" } })
  end

  describe '#call' do
    context '정상 입력 후 추가 안 함(n)' do
      it '사람 1명을 people에 추가한다' do
        stub_inputs('Alice', 'f', 'alpha', 'n')
        expect { fn.call }.to output(/Registered: Alice/).to_stdout
        expect(people.length).to eq(1)
        expect(people.first).to eq('name' => 'Alice', 'gender' => 'female', 'workspace' => 'alpha')
      end
    end

    context '2명 연속 추가 후 종료(n)' do
      it 'people에 2개의 항목이 추가된다' do
        stub_inputs('Alice', 'f', 'alpha', 'y', 'Bob', 'm', 'beta', 'n')
        fn.call
        expect(people.length).to eq(2)
      end
    end

    context '워크스페이스 대소문자 정규화' do
      it 'workspace를 소문자로 저장한다' do
        stub_inputs('Alice', 'f', 'ALPHA', 'n')
        fn.call
        expect(people.first['workspace']).to eq('alpha')
      end
    end

    context '성별 입력 처리' do
      it "'m' 입력 시 'male'로 저장한다" do
        stub_inputs('Bob', 'm', 'ws', 'n')
        fn.call
        expect(people.first['gender']).to eq('male')
      end

      it "'f' 입력 시 'female'로 저장한다" do
        stub_inputs('Alice', 'f', 'ws', 'n')
        fn.call
        expect(people.first['gender']).to eq('female')
      end

      it '잘못된 성별 입력 후 올바른 입력 시 등록된다' do
        stub_inputs('Alice', 'x', 'f', 'ws', 'n')
        expect { fn.call }.to output(/Invalid gender/).to_stdout
        expect(people.length).to eq(1)
      end
    end

    context '빈 이름 입력' do
      it '에러 메시지 출력 후 재입력을 요청한다' do
        stub_inputs('', 'Alice', 'f', 'ws', 'n')
        expect { fn.call }.to output(/Name cannot be empty/).to_stdout
        expect(people.first['name']).to eq('Alice')
      end
    end

    context '빈 워크스페이스 입력' do
      it '에러 메시지 출력 후 재입력을 요청한다' do
        stub_inputs('Alice', 'f', '', 'Alice', 'f', 'ws', 'n')
        expect { fn.call }.to output(/Workspace cannot be empty/).to_stdout
        expect(people.first['workspace']).to eq('ws')
      end
    end

    context 'y/n 이외 입력 후 정상 입력' do
      it '에러 메시지 출력 후 처리를 계속한다' do
        stub_inputs('Alice', 'f', 'ws', 'maybe', 'n')
        expect { fn.call }.to output(/Please enter 'y' or 'n'/).to_stdout
        expect(people.length).to eq(1)
      end
    end

    context 'nil 입력(스트림 종료)' do
      it '추가 없이 종료한다' do
        stub_inputs(nil)
        fn.call
        expect(people).to be_empty
      end
    end
  end
end