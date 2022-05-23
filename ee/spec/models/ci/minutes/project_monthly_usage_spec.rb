# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::ProjectMonthlyUsage do
  let_it_be(:project) { create(:project) }

  describe 'unique index' do
    before do
      create(:ci_project_monthly_usage, project: project)
    end

    it 'raises unique index violation' do
      expect { create(:ci_project_monthly_usage, project: project) }
        .to raise_error { ActiveRecord::RecordNotUnique }
    end

    it 'does not raise exception if unique index is not violated' do
      expect { create(:ci_project_monthly_usage, project: project, date: described_class.beginning_of_month(1.month.ago)) }
        .to change { described_class.count }.by(1)
    end
  end

  describe '.find_or_create_current' do
    subject { described_class.find_or_create_current(project_id: project.id) }

    shared_examples 'creates usage record' do
      it 'creates new record and resets minutes consumption' do
        freeze_time do
          expect { subject }.to change { described_class.count }.by(1)

          expect(subject.amount_used).to eq(0)
          expect(subject.project).to eq(project)
          expect(subject.date).to eq(described_class.beginning_of_month)
          expect(subject.created_at).to eq(Time.current)
        end
      end
    end

    context 'when project usage does not exist' do
      it_behaves_like 'creates usage record'
    end

    context 'when project usage exists for previous months' do
      before do
        create(:ci_project_monthly_usage, project: project, date: described_class.beginning_of_month(2.months.ago))
      end

      it_behaves_like 'creates usage record'
    end

    context 'when project usage exists for the current month' do
      it 'returns the existing usage' do
        freeze_time do
          usage = create(:ci_project_monthly_usage, project: project)

          expect(subject).to eq(usage)
        end
      end
    end

    context 'when a usage for another project exists for the current month' do
      let!(:usage) { create(:ci_project_monthly_usage) }

      it_behaves_like 'creates usage record'
    end
  end

  describe '#increase_usage' do
    let_it_be_with_refind(:current_usage) do
      create(:ci_project_monthly_usage,
        project: project,
        amount_used: 100)
    end

    it_behaves_like 'CI minutes increase usage'
  end

  describe '.for_namespace_monthly_usage' do
    let(:date_for_usage) { Date.new(2021, 5, 1) }
    let(:namespace_usage) { create(:ci_namespace_monthly_usage, namespace: project.namespace, amount_used: 50, date: date_for_usage) }
    let(:other_project) { create(:project, namespace: project.namespace) }

    let(:top_group) { create(:group) }
    let(:subgroup) { create(:group, parent: top_group) }
    let(:group_usage) { create(:ci_namespace_monthly_usage, namespace: top_group, amount_used: 50, date: date_for_usage) }

    it "fetches project monthly usages matching the namespace monthly usage's date and namespace" do
      date_not_for_usage = date_for_usage + 1.month
      matching_project_usage = create(:ci_project_monthly_usage, project: project, amount_used: 50, date: date_for_usage)
      create(:ci_project_monthly_usage, project: project, amount_used: 50, date: date_not_for_usage)
      create(:ci_project_monthly_usage, project: create(:project), amount_used: 50, date: date_for_usage)

      project_usages = described_class.for_namespace_monthly_usage(namespace_usage)

      expect(project_usages).to contain_exactly(matching_project_usage)
    end

    it 'does not join across databases' do
      with_cross_joins_prevented do
        described_class.for_namespace_monthly_usage(namespace_usage)
      end
    end

    it "fetches project monthly usages with more than 0 minutes used" do
      matching_project_usage = create(:ci_project_monthly_usage, project: project, amount_used: 10, date: date_for_usage)
      no_minutes_project = create(:ci_project_monthly_usage, project: other_project, amount_used: 0, date: date_for_usage)

      project_usages = described_class.for_namespace_monthly_usage(namespace_usage)

      expect(project_usages).to contain_exactly(matching_project_usage)
      expect(project_usages).not_to include(no_minutes_project)
    end

    it "fetches project monthly usages sorted by amount used in descending order" do
      matching_project_usage_20_mins = create(:ci_project_monthly_usage, project: other_project, amount_used: 20, date: date_for_usage)
      matching_project_usage_30_mins = create(:ci_project_monthly_usage, project: project, amount_used: 30, date: date_for_usage)
      create(:ci_project_monthly_usage, project: create(:project, namespace: project.namespace), amount_used: 0, date: date_for_usage)

      project_usages = described_class.for_namespace_monthly_usage(namespace_usage)

      expect(project_usages).to start_with(matching_project_usage_30_mins)
      expect(project_usages).to end_with(matching_project_usage_20_mins)
      expect(project_usages).to contain_exactly(matching_project_usage_20_mins, matching_project_usage_30_mins)
    end

    it "fetches project monthly usages in namespace and descendants" do
      matching_project_usage = create(:ci_project_monthly_usage, project: create(:project, namespace: top_group), amount_used: 50, date: date_for_usage)
      subgroup_project_usage = create(:ci_project_monthly_usage, project: create(:project, namespace: subgroup), amount_used: 10, date: date_for_usage)

      project_usages = described_class.for_namespace_monthly_usage(group_usage)

      expect(project_usages).to contain_exactly(matching_project_usage, subgroup_project_usage)
    end
  end

  context 'loose foreign key on ci_project_monthly_usages.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project) }
      let!(:model) { create(:ci_project_monthly_usage, project: parent) }
    end
  end
end
