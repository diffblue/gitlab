# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::RepositoryController, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_refind(:project) { create(:project_empty_repo, :public, namespace: group) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET show' do
    context 'push rule' do
      subject(:push_rule) { assigns(:push_rule) }

      it 'is created' do
        get :show, params: { namespace_id: project.namespace, project_id: project }

        is_expected.to be_persisted
      end

      it 'is connected to project_settings' do
        get :show, params: { namespace_id: project.namespace, project_id: project }

        expect(project.project_setting.push_rule).to eq(subject)
      end

      context 'unlicensed' do
        before do
          stub_licensed_features(push_rules: false)
        end

        it 'is not created' do
          get :show, params: { namespace_id: project.namespace, project_id: project }

          is_expected.to be_nil
        end
      end
    end

    describe 'group protected branches' do
      using RSpec::Parameterized::TableSyntax

      where(:feature_flag, :licensed_feature, :expected_include_group) do
        false            | false           | false
        false            | true            | false
        true             | false           | false
        true             | true            | true
      end

      let!(:protected_branch) { create(:protected_branch, project: nil, group: group) }

      let(:base_params) { { namespace_id: project.namespace, project_id: project } }
      let(:include_group) { assigns[:protected_branches].include?(protected_branch) }

      subject { get :show, params: base_params }

      with_them do
        before do
          stub_feature_flags(group_protected_branches: feature_flag)
          stub_feature_flags(allow_protected_branches_for_group: feature_flag)
          stub_licensed_features(group_protected_branches: licensed_feature)
        end

        it 'include group correctly' do
          subject

          expect(include_group).to eq(expected_include_group)
        end
      end
    end

    describe 'avoid N+1 sql queries' do
      subject { get :show, params: { namespace_id: project.namespace, project_id: project } }

      context 'when the feature group protected branches disabled' do
        it 'does not perform N+1 sql queries' do
          control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { subject }

          create_list(:protected_branch, 2, project: project)
          create_list(:protected_branch, 2, project: nil, group: group)

          expect { subject }.not_to exceed_all_query_limit(control_count)
        end
      end

      context 'when the feature group protected branches enabled' do
        before do
          stub_feature_flags(group_protected_branches: true)
          stub_feature_flags(allow_protected_branches_for_group: true)
          stub_licensed_features(group_protected_branches: true)
        end

        it 'does not perform N+1 sql queries' do
          control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { subject }

          create_list(:protected_branch, 2, project: project)
          create_list(:protected_branch, 2, project: nil, group: group)

          expect { subject }.not_to exceed_all_query_limit(control_count)
        end
      end
    end
  end
end
