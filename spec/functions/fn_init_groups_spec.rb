# frozen_string_literal: true

require 'functions/fn_init_groups'

RSpec.describe FnInitGroups do
  let(:groups) { [] }
  subject(:fn) { described_class.new(groups) }

  describe '#call' do
    context 'groups가 비어 있을 때' do
      it '"No group records to reset" 메시지를 출력한다' do
        expect { fn.call }.to output(/No group records to reset/).to_stdout
      end
    end

    context 'groups에 데이터가 있고 "y"를 입력할 때' do
      before do
        groups << { 'members' => %w[Alice Bob], 'grouped_at' => Time.now.iso8601 }
      end

      it 'groups를 비운다' do
        allow(fn).to receive(:gets).and_return("y\n")
        fn.call
        expect(groups).to be_empty
      end

      it '"All group records have been reset" 메시지를 출력한다' do
        allow(fn).to receive(:gets).and_return("y\n")
        expect { fn.call }.to output(/All group records have been reset/).to_stdout
      end
    end

    context '"n"을 입력할 때' do
      before do
        groups << { 'members' => %w[Alice Bob], 'grouped_at' => Time.now.iso8601 }
      end

      it '"Cancelled" 메시지를 출력하고 데이터를 유지한다' do
        allow(fn).to receive(:gets).and_return("n\n")
        expect { fn.call }.to output(/Cancelled/).to_stdout
        expect(groups.length).to eq(1)
      end
    end

    context 'nil 입력(스트림 종료)' do
      before do
        groups << { 'members' => %w[Alice Bob], 'grouped_at' => Time.now.iso8601 }
      end

      it '"Cancelled"를 출력하고 데이터를 유지한다' do
        allow(fn).to receive(:gets).and_return(nil)
        expect { fn.call }.to output(/Cancelled/).to_stdout
        expect(groups.length).to eq(1)
      end
    end
  end
end
