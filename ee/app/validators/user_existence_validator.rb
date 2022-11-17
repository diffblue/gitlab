# frozen_string_literal: true

class UserExistenceValidator < ActiveModel::EachValidator # rubocop:disable Gitlab/NamespacedClass
  def validate_each(record, attr, usernames)
    invalid = non_existing_users(usernames)

    if invalid.present?
      record.errors.add(
        attr,
        _("should be an array of existing usernames. %{invalid} does not exist") % { invalid: invalid.join(", ") }
      )
    end
  end

  private

  def non_existing_users(usernames)
    return unless usernames.present? && usernames.is_a?(Array)

    usernames - ::User.where(username: usernames).pluck(:username) # rubocop: disable CodeReuse/ActiveRecord
  end
end
