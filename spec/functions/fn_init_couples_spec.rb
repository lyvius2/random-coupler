# frozen_string_literal: true

require 'functions/fn_init_couples'

RSpec.describe FnInitCouples do
  let(:couples) { [] }
  subject(:fn)  { described_class.new(couples) }

  describe '#call' do
    context 'couples가 비어 있을 때' do
      it '"No couple records to reset" 메시지를 출력한다' do
        expect { fn.call }.to output(/No couple records to reset/).to_stdout
      end
    end

    context 'couples에 데이터가 있고 "y"를 입력할 때' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => Time.now.iso8601 }
      end

      it 'couples를 비운다' do
        allow(fn).to receive(:gets).and_return("y\n")
        fn.call
        expect(couples).to be_empty
      end

      it '"All couple records have been reset" 메시지를 출력한다' do
        allow(fn).to receive(:gets).and_return("y\n")
        expect { fn.call }.to output(/All couple records have been reset/).to_stdout
      end
    end

    context '"n"을 입력할 때' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => Time.now.iso8601 }
      end

      it '"Cancelled" 메시지를 출력하고 데이터를 유지한다' do
        allow(fn).to receive(:gets).and_return("n\n")
        expect { fn.call }.to output(/Cancelled/).to_stdout
        expect(couples.length).to eq(1)
      end
    end

    context 'nil 입력(스트림 종료)' do
      before do
        couples << { 'person1' => 'Alice', 'person2' => 'Bob', 'coupled_at' => Time.now.iso8601 }
      end

      it '"Cancelled"를 출력하고 데이터를 유지한다' do
        allow(fn).to receive(:gets).and_return(nil)
        expect { fn.call }.to output(/Cancelled/).to_stdout
        expect(couples.length).to eq(1)
      end
    end
  end
end