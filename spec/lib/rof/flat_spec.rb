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

    it 'decodes s-expressions' do
      output, rest = described_class.from_sexp("(record (first
      value) (pid und:12345) (dc:title an approach to (something) that
      we don't like))")
      record = described_class.from_hash('first' => 'value',
                                         'pid' => 'und:12345',
                                         'dc:title' => "an approach to (something) that\n      we don't like")

      expect(output).to eq(record)
    end
  end
end
