# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Projects::ComplianceStandards::AdherencePolicy, feature_category: :compliance_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:adherence) { create(:compliance_standards_adherence, project: project) }

  subject(:policy) { described_class.new(user, adherence) }

  context 'when user does not have owner access to group' do
    it { is_expected.to be_disallowed(:read_group_compliance_dashboard) }
  end

  context 'when user does have access to project' do
    before_all do
      group.add_owner(user)
    end

    it { is_expected.to be_allowed(:read_group_compliance_dashboard) }
  end
end
