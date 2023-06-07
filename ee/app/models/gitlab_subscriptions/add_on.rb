# frozen_string_literal: true

module GitlabSubscriptions
  class AddOn < ApplicationRecord
    self.table_name = 'subscription_add_ons'

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
  end
end
