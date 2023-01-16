# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::MembersPreloader do
  include OncallHelpers

  describe '#preload_all' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:saml_provider) { create(:saml_provider, group: group) }
    let_it_be(:escalation_policy) { create(:incident_management_escalation_policy, project: project, rule_count: 0) }

    it 'preloads associations to avoid N+1 queries' do
      member = create(:group_member, :developer, group: group)
      create_member_associations(member)

      control = ActiveRecord::QueryRecorder.new { access_group_with_preload([member]) }

      members = create_list(:group_member, 3, :developer, group: group)
      create_member_associations(members.first)
      create_member_associations(members.last)

      expect { access_group_with_preload(members) }.not_to exceed_query_limit(control)
    end

    def access_group_with_preload(members)
      MembersPreloader.new(members).preload_all
      MembersPresenter.new(members, current_user: nil).map(&:group_sso?)

      members.each do |member|
        member.user.oncall_schedules.any?
        member.user.escalation_policies.any?
        member.user.user_detail
        member.user.namespace_bans.any?
      end
    end

    def create_member_associations(member)
      create(:group_saml_identity, user: member.user, saml_provider: saml_provider)
      create_schedule_with_user(project, member.user)
      create(:incident_management_escalation_rule, :with_user, policy: escalation_policy, user: member.user)
      create(:namespace_ban, namespace: group, user: member.user)
      member.user.user_detail.save!
      member.reload
    end
  end
end
