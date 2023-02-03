# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(
  Gitlab::Usage::Metrics::Instrumentations::CountUsersWithCustomRolesMetric,
  feature_category: :system_access
) do
  let(:expected_value) { 2 }
  let(:expected_query) do
    'SELECT COUNT(DISTINCT "members"."user_id") FROM "members" WHERE "members"."member_role_id" IS NOT NULL'
  end

  before do
    member_role1 = create(:member_role, :guest)
    member_role2 = create(:member_role, :guest)

    # 1 user with 2 custom roles
    user1 = create(:user)
    member_role1.namespace.add_guest(user1).update!(member_role: member_role1)
    member_role2.namespace.add_guest(user1).update!(member_role: member_role2)

    # 1 user with 1 custom role
    user2 = create(:user)
    member_role1.namespace.add_guest(user2).update!(member_role: member_role1)

    # 1 user without custom role
    user3 = create(:user)
    member_role2.namespace.add_guest(user3)

    # should result in a count of 2
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
