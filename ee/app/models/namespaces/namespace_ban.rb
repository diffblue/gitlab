# frozen_string_literal: true

module Namespaces
  class NamespaceBan < ApplicationRecord
    belongs_to :namespace, optional: false
    belongs_to :user, optional: false

    validates :user_id, uniqueness: { scope: :namespace_id, message: -> (_, _) { _('already banned from namespace') } }
    validate :namespace_is_root_namespace
    validate :user_is_not_namespace_owner

    private

    def namespace_is_root_namespace
      return unless namespace

      errors.add(:namespace, _('must be a root namespace')) if namespace.has_parent?
    end

    def user_is_not_namespace_owner
      return unless namespace

      errors.add(:user, _('must not be an owner of the namespace')) if namespace.owned_by?(user)
    end
  end
end
