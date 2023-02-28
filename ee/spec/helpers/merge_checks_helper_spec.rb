# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeChecksHelper, type: :helper, feature_category: :code_review_workflow do
  let_it_be(:group) { create_default(:group, :public) }
  let_it_be(:project) { create_default(:project, group: group) }

  before do
    group.namespace_settings.update!(allow_merge_on_skipped_pipeline: true)
    stub_licensed_features(group_level_merge_checks_setting: true)
  end

  describe '#merge_checks' do
    context 'when source is group' do
      let(:source) { group }

      it 'returns the correct settings' do
        expect(helper.merge_checks(source)).to eq({
          source_type: 'namespace_setting',
          settings: {
            pipeline_must_succeed: {
              locked: false,
              value: false
            },
            allow_merge_on_skipped_pipeline: {
              locked: false,
              value: true
            },
            only_allow_merge_if_all_resolved: {
              locked: false,
              value: false
            }
          }.to_json,
          parent_group_name: ''
        })
      end
    end

    context 'when source has a parent group' do
      let_it_be(:parent_group) { create_default(:group, :public) }
      let_it_be(:source) { create_default(:group, :public, parent: parent_group) }

      it 'returns the correct settings' do
        expect(helper.merge_checks(source)).to eq({
          source_type: 'namespace_setting',
          settings: {
            pipeline_must_succeed: {
              locked: false,
              value: false
            },
            allow_merge_on_skipped_pipeline: {
              locked: false,
              value: false
            },
            only_allow_merge_if_all_resolved: {
              locked: false,
              value: false
            }
          }.to_json,
          parent_group_name: parent_group.name
        })
      end
    end

    context 'when source is project' do
      let(:source) { project }

      it 'returns the correct settings' do
        expect(helper.merge_checks(source)).to eq({
          source_type: 'project',
          settings: {
            pipeline_must_succeed: {
              locked: false,
              value: false
            },
            allow_merge_on_skipped_pipeline: {
              locked: true,
              value: true
            },
            only_allow_merge_if_all_resolved: {
              locked: false,
              value: false
            }
          }.to_json,
          parent_group_name: group.name
        })
      end
    end
  end
end
