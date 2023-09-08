# frozen_string_literal: true

module GitlabSubscriptions
  class UserAddOnAssignment < ApplicationRecord
    include EachBatch

    belongs_to :user, inverse_of: :assigned_add_ons
    belongs_to :add_on_purchase, class_name: 'GitlabSubscriptions::AddOnPurchase', inverse_of: :assigned_users

    validates :user, :add_on_purchase, presence: true
    validates :add_on_purchase_id, uniqueness: { scope: :user_id }

    scope :by_user, ->(user) { where(user: user) }

    scope :for_user_ids, ->(user_ids) { where(user_id: user_ids) }

    scope :for_active_add_on_purchase_ids, ->(add_on_purchase_ids) do
      joins(:add_on_purchase)
        .merge(::GitlabSubscriptions::AddOnPurchase.where(id: add_on_purchase_ids).active)
    end

    def self.pluck_user_ids
      pluck(:user_id)
    end
  end
end
