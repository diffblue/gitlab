# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationContext do
  describe '#to_lazy_hash' do
    let(:user) { build(:user) }
    let(:project) { create(:project) }
    let(:namespace) { create(:group) }
    let(:subgroup) { create(:group, parent: namespace) }

    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    def result(context)
      context.to_lazy_hash.transform_values { |v| v.respond_to?(:call) ? v.call : v }
    end

    it 'correctly loads the expected values' do
      # Make sure the plan is loaded, otherwise it would not be included in the context
      subgroup.actual_plan
      context = described_class.new(namespace: -> { subgroup })

      expect(result(context))
        .to include(root_namespace: namespace.full_path,
                    subscription_plan: 'free')
    end

    it 'falls back to a projects namespace plan when a project is passed but no namespace' do
      create(:gitlab_subscription, :premium, namespace: project.namespace)
      project.actual_plan_name
      context = described_class.new(project: project)

      expect(result(context))
        .to include(project: project.full_path,
                    root_namespace: project.full_path_components.first,
                    subscription_plan: 'premium')
    end
  end

  context 'only include values for which an option was specified' do
    using RSpec::Parameterized::TableSyntax

    where(:provided_options, :expected_context_keys) do
      [:user, :namespace, :project] | [:user, :project, :root_namespace, :client_id, :subscription_plan, :user_id]
      [:user, :project]             | [:user, :project, :root_namespace, :client_id, :subscription_plan, :user_id]
      [:user, :namespace]           | [:user, :root_namespace, :client_id, :subscription_plan, :user_id]
      [:user]                       | [:user, :client_id, :user_id]
      [:remote_ip]                  | [:remote_ip, :client_id]
      [:runner]                     | [:project, :root_namespace, :client_id, :subscription_plan]
      [:caller_id]                  | [:caller_id]
      []                            | []
    end

    with_them do
      specify do
        # Build a hash that has all `provided_options` as keys, and `nil` as value
        provided_values = provided_options.index_with { |key| nil }
        context = described_class.new(**provided_values)

        expect(context.to_lazy_hash.keys).to contain_exactly(*expected_context_keys)
      end
    end
  end
end
