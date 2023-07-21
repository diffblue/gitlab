# frozen_string_literal: true

module GitlabSubscriptions
  class AddOnPurchase < ApplicationRecord
    belongs_to :add_on, foreign_key: :subscription_add_on_id, inverse_of: :add_on_purchases
    belongs_to :namespace

    has_many :assigned_users, class_name: 'GitlabSubscriptions::UserAddOnAssignment', inverse_of: :add_on_purchase

    validates :add_on, :namespace, :expires_on, presence: true
    validates :subscription_add_on_id, uniqueness: { scope: :namespace_id }
    validates :quantity,
      presence: true,
      numericality: { only_integer: true, greater_than_or_equal_to: 1 }
    validates :purchase_xid,
      presence: true,
      length: { maximum: 255 }

    scope :active, -> { where('expires_on >= ?', Date.current) }
    scope :by_add_on_name, ->(name) { joins(:add_on).where(add_on: { name: name }) }
    scope :for_code_suggestions, -> { where(subscription_add_on_id: AddOn.code_suggestions.pick(:id)) }
    scope :for_project, ->(project_id) { where(namespace: Project.find_by_id(project_id)&.root_namespace) }
  end
end
