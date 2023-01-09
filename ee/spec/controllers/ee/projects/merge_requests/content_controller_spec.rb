# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequests::ContentController, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }

  before do
    sign_in(user)
  end

  def do_request(action = :cached_widget)
    get action, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.iid,
      format: :json
    }
  end

  context 'user has access to the project' do
    before do
      expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original

      project.add_maintainer(user)
    end

    describe 'GET cached_widget' do
      it 'renders widget MR entity as json' do
        do_request

        expect(response).to match_response_schema('entities/merge_request_poll_cached_widget')
      end
    end
  end
end
