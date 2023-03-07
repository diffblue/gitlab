# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Labels::CreateService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:namespace) { create(:group) }

    let(:params) do
      {
        title: title,
        color: '#000000'
      }
    end

    subject { described_class.new(params).execute(execute_params) }

    context 'for scoped labels' do
      let(:title) { 'scoped::label' }

      context 'for a project' do
        let(:execute_params) { { project: project } }
        let(:namespace) { project.group }

        it_behaves_like 'records an onboarding progress action', :scoped_label_created
      end

      context 'for a group' do
        let(:execute_params) { { group: namespace } }

        it_behaves_like 'records an onboarding progress action', :scoped_label_created
      end

      context 'without a group or project' do
        let(:execute_params) { {} }

        it_behaves_like 'does not record an onboarding progress action'
      end
    end

    context 'without scoped label' do
      let(:title) { 'not scoped label' }
      let(:execute_params) { { group: namespace } }

      it_behaves_like 'does not record an onboarding progress action'
    end
  end
end
