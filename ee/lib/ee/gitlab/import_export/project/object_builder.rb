# frozen_string_literal: true

module EE
  module Gitlab
    module ImportExport
      module Project
        module ObjectBuilder
          extend ActiveSupport::Concern
          extend ::Gitlab::Utils::Override

          override :prepare_attributes
          def prepare_attributes
            attributes = super

            attributes.dup.tap do |atts|
              atts.delete('project') if iteration?
            end
          end

          override :where_clause_for_klass
          def where_clause_for_klass
            return attrs_to_arel(attributes.slice('iid', 'start_date', 'due_date')) if iteration?

            super
          end

          override :find
          def find
            return if group_relation_without_group?
            return find_iteration if iteration?

            super
          end

          # rubocop: disable CodeReuse/ActiveRecord
          # Only attempt to find existing iteration. Do not try to create it
          # since iterations require associated cadences which we cannot create here
          def find_iteration
            klass
              .joins(:iterations_cadence)
              .where(iterations_cadence: { title: attributes['iterations_cadence']&.title })
              .find_by(where_clause)
          end
          # rubocop: enable CodeReuse/ActiveRecord

          private

          def iteration?
            klass == Iteration
          end

          override :group_level_object?
          def group_level_object?
            super || iteration?
          end
        end
      end
    end
  end
end
