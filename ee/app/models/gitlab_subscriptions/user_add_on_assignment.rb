# frozen_string_literal: true

module GitlabSubscriptions
  class UserAddOnAssignment < ApplicationRecord
    belongs_to :user, inverse_of: :assigned_add_ons
    belongs_to :add_on_purchase, class_name: 'GitlabSubscriptions::AddOnPurchase', inverse_of: :assigned_users

    validates :user, :add_on_purchase, presence: true
    validates :add_on_purchase_id, uniqueness: { scope: :user_id }

    scope :by_user, ->(user) { where(user: user) }
  end
end
