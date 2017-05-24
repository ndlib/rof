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

          context 'with multiple: true' do
            it 'will raise an error if too many' do
              subject.add_predicate_location_and_value(['hello', 'world'], "value", multiple: false)
              expect do
                subject.add_predicate_location_and_value(['hello', 'world'], "another", multiple: false)
              end.to raise_error(described_class::TooManyElementsError)
            end
            it 'will not be an array (but instead a String)' do
              subject.add_predicate_location_and_value(['hello', 'world'], "value", multiple: false)
              expect(subject.to_rof.fetch('hello').fetch('world')).to eq('value')
            end
          end

          context 'handling blank nodes' do
            context 'for the same node' do
              it 'collects values for the same location' do
                blank_node = RDF::Node.new('_b0')
                subject.add_blank_node(RDF::Statement.new(blank_node, nil, nil))
                subject.add_predicate_location_and_value(['parent', 'child'], "value", blank_node)
                subject.add_predicate_location_and_value(['parent', 'child'], "another", blank_node)
                expect(subject.to_rof).to eq({
                  "parent" => [{
                    "child" => ["value", "another"]
                  }]
                })
              end

              it 'collects values for the same deep location' do
                blank_node = RDF::Node.new('_b0')
                subject.add_blank_node(RDF::Statement.new(blank_node, nil, nil))
                subject.add_predicate_location_and_value(['parent', 'child', 'grandchild'], "value", blank_node)
                subject.add_predicate_location_and_value(['parent', 'child', 'grandchild'], "another", blank_node)
                expect(subject.to_rof).to eq({
                  "parent" => {
                    "child" => [{
                      "grandchild" => ["value", "another"]
                    }]
                  }
                })
              end

              it 'collects values for the same location' do
                blank_node = RDF::Node.new('_b0')
                subject.add_blank_node(RDF::Statement.new(blank_node, nil, nil))
                subject.add_predicate_location_and_value(['parent'], "value", blank_node)
                subject.add_predicate_location_and_value(['parent'], "another", blank_node)
                expect(subject.to_rof).to eq({
                  "parent" => ["value", "another"]
                })
              end

              it 'merges different locations' do
                blank_node = RDF::Node.new('_b0')
                subject.add_blank_node(RDF::Statement.new(blank_node, nil, nil))
                subject.add_predicate_location_and_value(['parent', 'child_one'], "value", blank_node)
                subject.add_predicate_location_and_value(['parent', 'child_two'], "another", blank_node)
                expect(subject.to_rof).to eq({
                  "parent" => [{
                    "child_one" => ["value"],
                    "child_two" => ["another"]
                  }]
                })
              end
            end

            context 'for different nodes' do
              it 'separates them in the JSON output' do
                blank_node_1 = RDF::Node.new('_b0')
                blank_node_2 = RDF::Node.new('_b1')
                subject.add_blank_node(RDF::Statement.new(blank_node_1, nil, nil))
                subject.add_blank_node(RDF::Statement.new(blank_node_2, nil, nil))
                subject.add_predicate_location_and_value(['parent', 'child'], "value", blank_node_1)
                subject.add_predicate_location_and_value(['parent', 'child'], "another", blank_node_2)
                expect(subject.to_rof).to eq({
                  "parent" => [{
                    "child" => ["value"]
                  }, {
                    "child" => ["another"]
                  }]
                })
              end
            end
          end
        end
      end
    end
  end
end
