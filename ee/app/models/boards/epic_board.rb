# frozen_string_literal: true

module Boards
  class EpicBoard < ApplicationRecord
    belongs_to :group, optional: false, inverse_of: :epic_boards
    has_many :epic_board_labels, foreign_key: :epic_board_id, inverse_of: :epic_board
    has_many :epic_board_positions, foreign_key: :epic_board_id, inverse_of: :epic_board
    has_many :epic_board_recent_visits, foreign_key: :epic_board_id, inverse_of: :epic_board
    has_many :epic_lists, -> { ordered }, foreign_key: :epic_board_id, inverse_of: :epic_board
    has_many :labels, through: :epic_board_labels
    has_many :destroyable_lists, -> { destroyable.ordered }, foreign_key: :epic_board_id,
      class_name: 'EpicList', inverse_of: :epic_board

    validates :name, length: { maximum: 255 }, presence: true

    scope :order_by_name_asc, -> { order(arel_table[:name].lower.asc).order(id: :asc) }
    scope :for_groups, ->(ids) { where(group_id: ids) }
    scope :with_api_entity_associations, -> { preload(:labels, epic_lists: :label) }

    def lists
      epic_lists
    end

    def self.to_type
      name.demodulize
    end

    def to_type
      self.class.to_type
    end

    def resource_parent
      group
    end

    def group_board?
      true
    end

    def scoped?
      labels.any?
    end

    def milestone_id
      nil
    end

    def milestone
      nil
    end

    def iteration_id
      nil
    end

    def iteration
      nil
    end

    def assignee_id
      nil
    end

    def assignee
      nil
    end

    def weight
      nil
    end

    def disabled_for?(current_user)
      false
    end
  end
end
