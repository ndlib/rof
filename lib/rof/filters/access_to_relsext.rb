require 'rof/filter'
module ROF
  module Filters
    class AccessToRelsext < ROF::Filter
      def initialize(options = {}); end

      def process(obj_list)
        # We need to map access with pid to rels-ext predicates
        obj_list.map! do |obj|
          obj.fetch('rights').each do |access_type, access_list|
            convert_to_relsext(access_type, access_list, obj)
          end
          obj
        end
      end

      def convert_to_relsext(access_type, access_list, rof)
        # map any access fields of the form XXX:YYY into
        # a rels-ext section
        Array.wrap(access_list).each do |access_user|
          next unless access_user =~ /([^:]+):.+/
          rof['rels-ext'] ||= {}
          case access_type
          when 'read'
            rof['rels-ext']['hasViewer'] ||= []
            rof['rels-ext']['hasViewer'] << access_user
          when 'read-groups'
            rof['rels-ext']['hasViewerGroup'] ||= []
            rof['rels-ext']['hasViewerGroup'] << access_user
          when 'edit'
            rof['rels-ext']['hasEditor'] ||= []
            rof['rels-ext']['hasEditor'] << access_user
          when 'edit-groups'
            rof['rels-ext']['hasEditorGroup'] ||= []
            rof['rels-ext']['hasEditorGroup'] << access_user
          else
            raise AccessMappingNotFound
          end
        end
        rof
      end
    end
  end
end
