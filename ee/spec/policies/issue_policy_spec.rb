# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePolicy do
  let_it_be(:owner) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, group: namespace) }
  let_it_be(:issue) { create(:issue, project: project) }

  subject { described_class.new(owner, issue) }

  before do
    namespace.add_owner(owner)
    allow(issue).to receive(:project).and_return(project)
    allow(project).to receive(:namespace).and_return(namespace)
    allow(project).to receive(:design_management_enabled?).and_return true
  end

  context 'when namespace is locked because storage usage limit exceeded' do
    before do
      allow(namespace).to receive(:over_storage_limit?).and_return true
    end

    it { is_expected.to be_disallowed(:create_issue, :update_issue, :read_issue_iid, :reopen_issue, :create_design, :create_note) }
  end

  context 'when namespace is not locked because storage usage limit not exceeded' do
    before do
      allow(namespace).to receive(:over_storage_limit?).and_return false
    end

    it { is_expected.to be_allowed(:create_issue, :update_issue, :read_issue_iid, :reopen_issue, :create_design, :create_note) }
  end
end
