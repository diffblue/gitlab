# frozen_string_literal: true

# Factory that builds either an epic or an epic issue, depending
# on the value of :object_type
FactoryBot.define do
  factory :epic_tree_node, class: 'Object' do
    association :parent, factory: :epic
    sequence(:object_type) { |n| n.even? ? :epic_issue : :epic }

    relative_position { RelativePositioning::START_POSITION }

    group { parent.group }

    initialize_with do
      g = group # Need to call so it does not get assigned
      key = object_type == :epic ? :parent : :epic
      extras = object_type == :epic ? { group: g } : {}

      obj = FactoryBot.build(
        object_type,
        **extras,
        key => parent,
        relative_position: relative_position
      )

      obj
    end
  end
end
