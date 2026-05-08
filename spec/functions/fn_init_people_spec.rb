# frozen_string_literal: true

require 'functions/fn_init_people'

RSpec.describe FnInitPeople do
  let(:people) { [] }
  subject(:fn) { described_class.new(people) }

  describe '#call' do
    context 'people가 비어 있을 때' do
      it '"No people data to reset" 메시지를 출력한다' do
        expect { fn.call }.to output(/No people data to reset/).to_stdout
      end

      it 'people를 변경하지 않는다' do
        fn.call
        expect(people).to be_empty
      end
    end

    context 'people에 데이터가 있고 "y"를 입력할 때' do
      before { people << { 'name' => 'Alice', 'gender' => 'female', 'workspace' => 'alpha' } }

      it 'people를 비운다' do
        allow(fn).to receive(:gets).and_return("y\n")
        fn.call
        expect(people).to be_empty
      end

      it '"All people data has been reset" 메시지를 출력한다' do
        allow(fn).to receive(:gets).and_return("y\n")
        expect { fn.call }.to output(/All people data has been reset/).to_stdout
      end
    end

    context '"n"을 입력할 때' do
      before { people << { 'name' => 'Alice', 'gender' => 'female', 'workspace' => 'alpha' } }

      it '"Cancelled" 메시지를 출력하고 데이터를 유지한다' do
        allow(fn).to receive(:gets).and_return("n\n")
        expect { fn.call }.to output(/Cancelled/).to_stdout
        expect(people.length).to eq(1)
      end
    end

    context 'nil 입력(스트림 종료)' do
      before { people << { 'name' => 'Alice', 'gender' => 'female', 'workspace' => 'alpha' } }

      it '"Cancelled"를 출력하고 데이터를 유지한다' do
        allow(fn).to receive(:gets).and_return(nil)
        expect { fn.call }.to output(/Cancelled/).to_stdout
        expect(people.length).to eq(1)
      end
    end
  end
end