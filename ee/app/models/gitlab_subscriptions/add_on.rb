# frozen_string_literal: true

module GitlabSubscriptions
  class AddOn < ApplicationRecord
    has_many :add_on_purchases, foreign_key: :subscription_add_on_id, inverse_of: :add_on

    validates :name,
      presence: true,
      uniqueness: true
    validates :description,
      presence: true,
      length: { maximum: 512 }

    enum name: {
      code_suggestions: 1
    }

    # Note: If a new enum is added, make sure to update this method to reflect that as well.
    def self.descriptions
      {
        code_suggestions: 'Add-on for code suggestions.'
      }
    end

    def self.find_or_create_by_name(add_on_name)
      create_with(description: GitlabSubscriptions::AddOn.descriptions[add_on_name.to_sym])
        .find_or_create_by!(name: add_on_name)
    end
  end
end
