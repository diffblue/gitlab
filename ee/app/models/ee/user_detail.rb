# frozen_string_literal: true

module EE
  module UserDetail
    extend ActiveSupport::Concern

    prepended do
      belongs_to :provisioned_by_group, class_name: 'Group', optional: true, inverse_of: :provisioned_user_details

      scope :enterprise, -> { where.not(provisioned_by_group_id: nil) }
      scope :enterprise_created_via_saml_or_scim, -> { enterprise.where(provisioned_by_group_at: nil) }
      scope :enterprise_based_on_domain_verification, -> { enterprise.where.not(provisioned_by_group_at: nil) }
    end

    def provisioned_by_group?
      !!provisioned_by_group
    end
  end
end
