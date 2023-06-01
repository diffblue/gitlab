# frozen_string_literal: true

class NamespaceLimit < ApplicationRecord
  MIN_REQURIED_STORAGE_USAGE_RATIO = 0.5

  self.primary_key = :namespace_id

  belongs_to :namespace, inverse_of: :namespace_limit

  validates :namespace, presence: true

  validate :namespace_is_root_namespace
  validate :temporary_storage_increase_set_once, if: :temporary_storage_increase_ends_on_changed?
  validate :temporary_storage_increase_eligibility, if: :temporary_storage_increase_ends_on_changed?

  def temporary_storage_increase_enabled?
    return false unless ::Feature.enabled?(:temporary_storage_increase, namespace)
    return false if temporary_storage_increase_ends_on.nil?

    temporary_storage_increase_ends_on >= Date.today
  end

  def eligible_for_temporary_storage_increase?
    return false unless ::Feature.enabled?(:temporary_storage_increase, namespace)

    namespace.root_storage_size.usage_ratio >= MIN_REQURIED_STORAGE_USAGE_RATIO
  end

  def eligible_additional_purchased_storage_size
    if Feature.enabled?(:expired_storage_check, namespace) &&
        additional_purchased_storage_ends_on &&
        Date.today > additional_purchased_storage_ends_on
      0
    else
      additional_purchased_storage_size
    end
  end

  private

  def namespace_is_root_namespace
    return unless namespace

    errors.add(:namespace, _('must be a root namespace')) if namespace.has_parent?
  end

  def temporary_storage_increase_set_once
    if temporary_storage_increase_ends_on_was.present?
      errors.add(:temporary_storage_increase_ends_on, s_('TemporaryStorageIncrease|can only be set once'))
    end
  end

  def temporary_storage_increase_eligibility
    unless eligible_for_temporary_storage_increase?
      errors.add(
        :temporary_storage_increase_ends_on,
        s_("TemporaryStorageIncrease|can only be set with more than %{percentage}%% usage") %
          {
            percentage: (MIN_REQURIED_STORAGE_USAGE_RATIO * 100).to_i
          }
      )
    end
  end
end
