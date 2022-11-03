# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Allowlist do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:source_project) { create(:project) }

  let(:scope) { described_class.new(source_project, direction: direction) }

  let(:direction) { :outbound }

  shared_context 'with scoped projects' do
    let!(:inbound_scoped_project) { create_scoped_project(source_project, direction: :inbound) }
    let!(:outbound_scoped_project) { create_scoped_project(source_project, direction: :outbound) }
    let!(:unscoped_project1) { create(:project) }
    let!(:unscoped_project2) { create(:project) }

    let!(:link_out_of_scope) { create(:ci_job_token_project_scope_link, target_project: unscoped_project1) }
  end

  describe '#projects' do
    subject(:all_projects) { scope.all_projects }

    context 'when no projects are added to the scope' do
      [:inbound, :outbound].each do |d|
        let(:direction) { d }

        it 'returns the project defining the scope' do
          expect(all_projects).to contain_exactly(source_project)
        end
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with scoped projects'

      where(:direction, :result) do
        :outbound | ref(:outbound_scoped_project)
        :inbound  | ref(:inbound_scoped_project)
      end

      with_them do
        it 'returns all projects that can be accessed from a given scope' do
          expect(subject).to contain_exactly(source_project, result)
        end
      end
    end
  end

  describe '#includes?' do
    subject { scope.includes?(includes_project) }

    context 'without projects' do
      context 'when project is self referential' do
        where(:direction, :result) do
          :outbound | true
          :inbound  | true
        end

        with_them do
          let(:includes_project) { source_project }

          it { is_expected.to be result }
        end
      end

      context 'when project is not self referential' do
        where(:direction, :result) do
          :outbound | false
          :inbound  | false
        end

        with_them do
          let(:includes_project) { build(:project) }

          it { is_expected.to be result }
        end
      end
    end

    context 'with scoped projects' do
      include_context 'with scoped projects'

      context 'when project is self referential' do
        where(:direction, :result) do
          :outbound | true
          :inbound  | true
        end

        with_them do
          let(:includes_project) { source_project }

          it { is_expected.to be result }
        end
      end

      context 'when project is in inbound scope' do
        where(:direction, :result) do
          :outbound | false
          :inbound  | true
        end

        with_them do
          let(:includes_project) { inbound_scoped_project }

          it { is_expected.to be result }
        end
      end

      context 'when project is in outbound scope' do
        where(:direction, :result) do
          :outbound | true
          :inbound  | false
        end

        with_them do
          let(:includes_project) { outbound_scoped_project }

          it { is_expected.to be result }
        end
      end

      context 'when project is linked to a different project' do
        where(:direction, :result) do
          :outbound | false
          :inbound  | false
        end

        with_them do
          let(:includes_project) { unscoped_project1 }

          it { is_expected.to be result }
        end
      end

      context 'when project is unlinked to any project' do
        where(:direction, :result) do
          :outbound | false
          :inbound  | false
        end

        with_them do
          let(:includes_project) { unscoped_project2 }

          it { is_expected.to be result }
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
