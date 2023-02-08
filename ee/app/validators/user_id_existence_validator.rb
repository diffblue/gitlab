# frozen_string_literal: true

class UserIdExistenceValidator < ActiveModel::EachValidator # rubocop:disable Gitlab/NamespacedClass
  def validate_each(record, attr, user_ids)
    invalid = non_existing_users(user_ids)

    return if invalid.blank?

    record.errors.add(
      attr,
      format(_('should be an array of existing user ids. %{invalid} does not exist'), invalid: invalid.join(', '))
    )
  end

  private

  def non_existing_users(user_ids)
    return unless user_ids.present? && user_ids.is_a?(Array)

    user_ids - ::User.id_in(user_ids).pluck_primary_key
  end
end
