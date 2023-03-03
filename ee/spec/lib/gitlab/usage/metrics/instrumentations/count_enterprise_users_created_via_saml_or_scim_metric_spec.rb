# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(
  Gitlab::Usage::Metrics::Instrumentations::CountEnterpriseUsersCreatedViaSamlOrScimMetric,
  feature_category: :user_management
) do
  let_it_be(:enterprise_user_created_via_saml) { create(:user, :enterprise_user_created_via_saml) }

  let_it_be(:enterprise_user_created_via_scim) { create(:user, :enterprise_user_created_via_scim) }

  let_it_be(:enterprise_user_based_on_domain_verification) do
    create(:user, :enterprise_user_based_on_domain_verification)
  end

  let_it_be(:non_enterprise_users) { create_list(:user, 3) }

  let(:expected_value) { 2 }

  let(:expected_query) do
    'SELECT COUNT("user_details"."user_id") FROM "user_details" ' \
      'WHERE "user_details"."provisioned_by_group_id" IS NOT NULL AND "user_details"."provisioned_by_group_at" IS NULL'
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
