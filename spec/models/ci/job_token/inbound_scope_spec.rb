# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::InboundScope do
  let_it_be(:source_project) { create(:project, ci_inbound_job_token_scope_enabled: true).tap(&:save!) }

  let(:scope) { described_class.new(source_project) }

  shared_context 'with scoped projects' do
    let!(:inbound_scoped_project) { create_scoped_project(source_project, direction: :inbound) }
    let!(:outbound_scoped_project) { create_scoped_project(source_project, direction: :outbound) }
    let!(:unscoped_project1) { create(:project) }
    let!(:unscoped_project2) { create(:project) }

    let!(:link_out_of_scope) { create(:ci_job_token_project_scope_link, target_project: unscoped_project1) }
  end

  describe '#all_projects' do
    subject(:all_projects) { scope.all_projects }

    context 'when no projects are added to the scope' do
      it 'returns the project defining the scope' do
        expect(all_projects).to contain_exactly(source_project)
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with scoped projects'

      it 'returns all projects that can be accessed from a given scope' do
        expect(subject).to contain_exactly(source_project, inbound_scoped_project)
      end
    end
  end

  describe '#includes?' do
    subject { scope.includes?(includes_project) }

    context 'without projects' do
      context 'when param is in scope' do
        let(:includes_project) { source_project }

        it { is_expected.to be_truthy }
      end
    end

    context 'with scoped projects' do
      include_context 'with scoped projects'

      context 'when project is self refrential' do
        let(:includes_project) { source_project }

        it { is_expected.to be_truthy }
      end

      context 'when project is in inbound scope' do
        let(:includes_project) { inbound_scoped_project }

        it { is_expected.to be_truthy }
      end

      context 'when project is in outbound scope' do
        let(:includes_project) { outbound_scoped_project }

        it { is_expected.to be_falsey }
      end

      context 'when project is linked to a different project' do
        let(:includes_project) { unscoped_project1 }

        it { is_expected.to be_falsey }
      end

      context 'when project is unlinked to any project' do
        let(:includes_project) { unscoped_project2 }

        it { is_expected.to be_falsey }
      end

      context 'when project scope setting is disabled' do
        let(:includes_project) { unscoped_project1 }

        before do
          source_project.ci_inbound_job_token_scope_enabled = false
        end

        it 'considers any project to be part of the scope' do
          expect(subject).to be_truthy
        end
      end

      context 'when feature flag is disabled' do
        let(:includes_project) { unscoped_project1 }

        before do
          stub_feature_flags(ci_inbound_job_token_scope: false)
        end

        it 'considers any project to be part of the scope' do
          expect(subject).to be_truthy
        end
      end
    end
  end

  private

  def create_scoped_project(source_project, direction: 0)
    create(:project).tap do |scoped_project|
      create(
        :ci_job_token_project_scope_link,
        source_project: source_project,
        target_project: scoped_project,
        direction: direction
      )
    end
  end
end
