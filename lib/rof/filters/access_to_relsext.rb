require 'rof/filter'
module ROF
  module Filters

    class AccessToRelsext < ROF::Filter
      def initialize(options = {})
      end

      def process(obj_list)
        # We need to map access with pid to rels-ext predicates
        obj_list.map! do |obj|
          obj.fetch("rights").each do |access_type, access_list|
            convert_to_relsext(access_type, access_list, obj)
          end
          obj
        end
      end

      def convert_to_relsext(access_type, access_list, rof)
        # map any access fields of the form XXX:YYY into
        # a rels-ext section
        Array.wrap(access_list).each do |access_user|
          if access_user =~ /([^:]+):.+/
            rof['rels-ext'] ||= {}
            case access_type
              when "read"
                rof['rels-ext']['hydramata-rel:hasViewer'] ||=[]
                rof['rels-ext']['hydramata-rel:hasViewer'] << access_user
              when "read-groups"
                rof['rels-ext']['hydramata-rel:hasViewerGroup'] ||= []
                rof['rels-ext']['hydramata-rel:hasViewerGroup'] << access_user
              when "edit"
                rof['rels-ext']['hydramata-rel:hasEditor'] ||= []
                rof['rels-ext']['hydramata-rel:hasEditor'] << access_user
              when "edit-groups"
                rof['rels-ext']['hydramata-rel:hasEditorGroup'] ||= []
                rof['rels-ext']['hydramata-rel:hasEditorGroup'] << access_user
              else
                raise AccessMappingNotFound
            end
          end
        end
        return rof
      end
    end
  end
end
