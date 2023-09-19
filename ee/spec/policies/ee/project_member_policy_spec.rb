# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMemberPolicy, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user) }
  let(:member) { create(:project_member, project: project, user: member_user) }
  let(:current_user) { maintainer }

  subject { described_class.new(current_user, member) }

  before do
    create(:project_member, :maintainer, project: project, user: maintainer)
  end

  context 'with a security policy bot member' do
    let(:member_user) { create(:user, :security_policy_bot) }

    it { is_expected.not_to be_allowed(:destroy_project_member) }
  end
end
