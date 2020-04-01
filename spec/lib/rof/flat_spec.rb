# frozen_string_literal: true

require 'spec_helper'

module ROF
  RSpec.describe Flat do
    it 'does decodes initial hashes' do
      first = described_class.from_hash('name' => ['Jane Doe', 'Issac Newton'],
                                        'date' => '2020-01-01')
      second = described_class.new
      second.add('date', '2020-01-01')
      second.add('name', 'Jane Doe')
      second.add('name', 'Issac Newton')

      expect(first).to eq(second)
    end

    [{ name: 'with no record', input: '()', output: {} },
     { name: 'with escaped quotes', input: '(record (name "something \\" quotes"))', output: { 'name' => 'something " quotes' } },
     { name: 'with multiline quotes', input: '(record (first value) (pid und:12345) (dc:title "an approach to (something) that
      we like"))', output: { 'first' => 'value', 'pid' => 'und:12345',
                             'dc:title' => "an approach to (something) that\n      we like" } }].each do |t|
      it 'decodes s-expressions ' + t[:name] do
        output, rest = described_class.from_sexp(t[:input])
        record = described_class.from_hash(t[:output])
        expect(output).to eq(record)
      end
    end
  end
end
