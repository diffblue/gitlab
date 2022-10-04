# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableResourceLinksFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }

  let_it_be(:issuable_resource_link_1) do
    create(:issuable_resource_link, issue: incident)
  end

  let_it_be(:issuable_resource_link_2) do
    create(:issuable_resource_link, issue: incident)
  end

  let(:params) { {} }

  describe '#execute' do
    subject(:execute) { described_class.new(user, incident, params).execute }

    context 'when feature is available' do
      before do
        stub_licensed_features(issuable_resource_links: true)
      end

      context 'when user has permissions' do
        before do
          project.add_reporter(user)
        end

        it 'returns issuable resource links' do
          is_expected.to eq([issuable_resource_link_1, issuable_resource_link_2])
        end

        context 'when incident is nil' do
          let_it_be(:incident) { nil }

          it { is_expected.to eq(IncidentManagement::IssuableResourceLink.none) }
        end
      end

      context 'when user has no permissions' do
        before do
          project.add_guest(user)
        end

        it { is_expected.to eq(IncidentManagement::IssuableResourceLink.none) }
      end
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(issuable_resource_links: false)
      end

      it { is_expected.to eq(IncidentManagement::IssuableResourceLink.none) }
    end
  end
end
