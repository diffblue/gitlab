# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventPolicy do
  let(:user) { create(:user) }
  let(:event) { create(:event, :created, target: target) }

  subject { described_class.new(user, event) }

  context "for epics" do
    before do
      stub_licensed_features(epics: true)
    end

    let(:target) { create(:epic, group: group) }

    context 'when the user cannot read the epic' do
      let(:group) { create(:group, :private) }

      it { expect_disallowed(:read_event) }
    end

    context 'when the user can read the epic' do
      let(:group) { create(:group, :public) }

      it { expect_allowed(:read_event) }
    end
  end

  context "for vulnerabilities" do
    let_it_be(:project) { create(:project) }
    let(:target) { create(:vulnerability, project: project) }
    let(:event) { create(:event, :created, target: target, project: project) }

    before do
      stub_licensed_features(security_dashboard: true)
    end

    context 'when the user cannot read the vulnerability' do
      it { expect_disallowed(:read_event) }
    end

    context 'when the user can read the vulnerability' do
      before do
        project.add_developer(user)
      end

      it { expect_allowed(:read_event) }
    end
  end
end
