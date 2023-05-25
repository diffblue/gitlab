# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '[EE] Public Group access', feature_category: :groups_and_projects do
  include AccessMatchers

  let_it_be(:group)   { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:project_guest) do
    create(:user) do |user|
      project.add_guest(user)
    end
  end

  describe 'GET /groups/:path/-/insights' do
    before do
      stub_licensed_features(insights: true)
    end

    subject { group_insights_path(group) }

    it { is_expected.to be_allowed_for(:admin) }
    it { is_expected.to be_allowed_for(:auditor) }
    it { is_expected.to be_allowed_for(:owner).of(group) }
    it { is_expected.to be_allowed_for(:maintainer).of(group) }
    it { is_expected.to be_allowed_for(:developer).of(group) }
    it { is_expected.to be_allowed_for(:reporter).of(group) }
    it { is_expected.to be_allowed_for(:guest).of(group) }
    it { is_expected.to be_allowed_for(project_guest) }
    it { is_expected.to be_allowed_for(:user) }
    it { is_expected.to be_allowed_for(:external) }
    it { is_expected.to be_allowed_for(:visitor) }
  end

  describe 'GET /groups/:path' do
    subject { group_path(group) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe 'GET /groups/:path/-/issues' do
    subject { issues_group_path(group) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe 'GET /groups/:path/-/merge_requests' do
    let(:project) { create(:project, :public, :repository, group: group) }

    subject { merge_requests_group_path(group) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe 'GET /groups/:path/-/group_members' do
    subject { group_group_members_path(group) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe 'GET /groups/:path/-/edit' do
    subject { edit_group_path(group) }

    it { is_expected.to be_denied_for(:auditor) }
  end
end
