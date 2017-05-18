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

        describe '#to_rof' do
          describe 'for embargo-date' do
            let(:initial_rof) do
              {
                "rights"=> {
                  "edit"=>["curate_batch_user"],
                  "embargo-date"=>["2016-11-16"],
                  "read"=>["wma1"],
                  "read-groups"=>["public"]
                }
              }
            end
            context 'with one embargo-date' do
              it 'will have a single embargo date' do
                rof = initial_rof
                rof['rights']['embargo-date'] = ['2016-1-2']
                expect(described_class.new(rof).to_rof['rights'].fetch('embargo-date')).to eq('2016-1-2')
              end
            end
            context 'with more than one embargo-date' do
              it 'will raise an exception' do
                rof = initial_rof
                rof['rights']['embargo-date'] = ['2016-1-2', '2016-2-3']
                expect { described_class.new(rof).to_rof }.to raise_error(described_class::TooManyElementsError)
              end
            end
            context 'no embargo-date' do
              it 'will not have an embargo-date' do
                rof = initial_rof
                rof['rights'].delete('embargo-date')
                expect { described_class.new(rof).to_rof['rights'].fetch('embargo-date') }.to raise_error(KeyError)
              end
            end
          end
          describe 'bendo-item' do
            let(:initial_rof) do
              {
                "bendo-item"=> ['abcd1']
              }
            end
            context 'with one embargo-date' do
              it 'will have a single embargo date' do
                rof = initial_rof
                rof['bendo-item'] = ['abcd1']
                expect(described_class.new(rof).to_rof.fetch('bendo-item')).to eq('abcd1')
              end
            end
            context 'with more than one embargo-date' do
              it 'will raise an exception' do
                rof = initial_rof
                rof['bendo-item'] = ['abcd1', 'efgh1']
                expect { described_class.new(rof).to_rof }.to raise_error(described_class::TooManyElementsError)
              end
            end
            context 'no embargo-date' do
              it 'will not have an embargo-date' do
                rof = initial_rof
                rof.delete('bendo-item')
                expect { described_class.new(rof).to_rof.fetch('bendo-item') }.to raise_error(KeyError)
              end
            end
          end
        end
      end
    end
  end
end
