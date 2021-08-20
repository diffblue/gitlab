# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalStatePolicy do
  let!(:project) { create(:project) }
  let!(:user) { create(:user) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let!(:approval_state) { ApprovalState.new(merge_request) }

  subject(:policy) { described_class.new(user, approval_state) }

  context 'when user does not have access to project' do
    it { is_expected.to be_disallowed(:read_merge_request) }
  end

  context 'when user does have access to project' do
    before do
      project.add_developer(user)
    end

    it { is_expected.to be_allowed(:read_merge_request) }
  end
end
