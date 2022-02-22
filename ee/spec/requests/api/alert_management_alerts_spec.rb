# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::AlertManagementAlerts do
  let_it_be(:creator) { create(:user) }
  let_it_be(:project) do
    create(:project, :public, creator_id: creator.id, namespace: creator.namespace)
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:alert) { create(:alert_management_alert, project: project) }

  describe 'GET /projects/:id/alert_management_alerts/:alert_iid/metric_images' do
    using RSpec::Parameterized::TableSyntax

    let!(:image) { create(:alert_metric_image, alert: alert) }

    subject { get api("/projects/#{project.id}/alert_management_alerts/#{alert.iid}/metric_images", user) }

    shared_examples 'can_read_metric_image' do
      it 'can read the metric images' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.first).to match(
          {
            id: image.id,
            created_at: image.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
            filename: image.filename,
            file_path: image.file_path,
            url: image.url,
            url_text: nil
          }.with_indifferent_access
        )
      end
    end

    shared_examples 'unauthorized_read' do
      it 'cannot read the metric images' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    where(:user_role, :public_project, :expected_status) do
      :not_member | false | :unauthorized_read
      :not_member | true  | :unauthorized_read
      :guest      | false | :unauthorized_read
      :reporter   | false | :unauthorized_read
      :developer  | false | :can_read_metric_image
    end

    with_them do
      before do
        stub_licensed_features(alert_metric_upload: true)
        project.send("add_#{user_role}", user) unless user_role == :not_member
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE) unless public_project
      end

      it_behaves_like "#{params[:expected_status]}"
    end
  end
end
