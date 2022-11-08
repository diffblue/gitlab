# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ExternalStatusCheckPolicy do
  let_it_be(:project) { create(:project) }
  let_it_be(:external_status_check) { create(:external_status_check, project: project) }

  subject { described_class.new(user, external_status_check) }

  context 'when user can admin project' do
    let(:user) { project.creator }

    it { is_expected.to be_allowed(:read_external_status_check) }
  end

  context 'when user cannot admin project' do
    let(:user) { create(:user) }

    before do
      project.add_developer(user)
    end

    it { is_expected.to be_disallowed(:read_external_status_check) }
  end
end
