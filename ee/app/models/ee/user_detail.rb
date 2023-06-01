# frozen_string_literal: true

module EE
  module UserDetail
    extend ActiveSupport::Concern

    prepended do
      belongs_to :provisioned_by_group, class_name: 'Group', optional: true, inverse_of: :provisioned_user_details
    end

    def provisioned_by_group?
      !!provisioned_by_group
    end
  end
end
