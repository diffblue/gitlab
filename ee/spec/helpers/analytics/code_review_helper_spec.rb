# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CodeReviewHelper do
  let_it_be(:project) { build(:project) }

  describe '#code_review_app_data' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(helper).to receive(:project_path).with(project).and_return('/mock/project')
      allow(helper).to receive(:namespace_project_new_merge_request_path).with(project.namespace).and_return('/mock/project/-/merge_requests/new')
      allow(helper).to receive(:image_path).with('illustrations/empty-state/empty-merge-requests-md.svg').and_return('/assets/illustrations/mock.svg')
      allow(helper).to receive(:project_milestones_path).with(project).and_return('/mock/project/-/milestones')
      allow(helper).to receive(:project_labels_path).with(project).and_return('/mock/project/-/labels')
    end

    where(:merge_request_source_project_for_project_return_value, :new_merge_request_url_expected) do
      true  | '/mock/project/-/merge_requests/new'
      false | nil
    end

    with_them do
      context "when `merge_request_source_project_for_project` is #{params[:merge_request_source_project_for_project_return_value]}" do
        before do
          allow(helper).to receive(:merge_request_source_project_for_project).with(project).and_return(merge_request_source_project_for_project_return_value)
        end

        it "returns expected hash with `new_merge_request_url` set to #{params[:new_merge_request_url_expected]}" do
          expect(helper.code_review_app_data(project)).to match(
            {
              project_id: project.id,
              project_path: '/mock/project',
              empty_state_svg_path: '/assets/illustrations/mock.svg',
              milestone_path: '/mock/project/-/milestones',
              labels_path: '/mock/project/-/labels'
            }.merge({ new_merge_request_url: new_merge_request_url_expected })
          )
        end
      end
    end
  end
end
