require 'spec_helper'
require 'rof/translators/jsonld_to_rof/accumulator'
module ROF
  module Translators
    module JsonldToRof
      RSpec.describe Accumulator do
        describe '#add_pid' do
          it 'sets the pid if non has been set' do
            subject.add_pid('abcd')
            expect(subject.to_rof.fetch('pid')).to eq('abcd')
          end
          it 'raises an exception if a different pid is set with the same accumulator' do
            subject.add_pid('abcd')
            expect { subject.add_pid('hijk') }.to raise_error(described_class::PidAlreadySetError)
          end
          it 'ignores attempts to set the same pid over and over' do
            subject.add_pid('abcd')
            expect { subject.add_pid('abcd') }.not_to change { subject.to_rof }
          end
        end
        describe '#add_predicate_location_and_value' do
          it 'will register a pid if one is given' do
            subject.add_predicate_location_and_value(['pid'], 1)
            expect(subject.to_rof).to eq({ "pid" => 1 })
          end
          it 'will not allow another pid to be register if it is different' do
            subject.add_pid('abc')
            expect { subject.add_predicate_location_and_value(['pid'], 1) }.to raise_error(described_class::PidAlreadySetError)
          end
          it 'wraps values in an array' do
            subject.add_predicate_location_and_value(['hello'], 1)
            expect(subject.to_rof).to eq({ "hello" => [1] })
            subject.add_predicate_location_and_value(['hello'], 2)
            expect(subject.to_rof).to eq({ "hello" => [1, 2] })
          end
          it 'handles deep locations' do
            subject.add_predicate_location_and_value(['hello', 'world'], "value")
            expect(subject.to_rof).to eq({ "hello" => { "world" => ["value"] } })
          end

          it 'handles locations at different levels' do
            subject.add_predicate_location_and_value(['hello', 'world'], "value")
            subject.add_predicate_location_and_value(['kitchen'], "another")
            expect(subject.to_rof).to eq({ "hello" => { "world" => ["value"] }, "kitchen" => ["another"] } )
          end
        end
      end
    end
  end
end
