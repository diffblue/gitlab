# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ClustersController, feature_category: :deployment_management do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    login_as(user)
  end

  describe 'GET #environments' do
    def go
      get environments_group_cluster_path(group, cluster, format: :json)
    end

    let(:cluster) { create(:cluster_for_group, groups: [group]) }

    before do
      stub_licensed_features(cluster_deployments: true)

      create(:deployment, :success, cluster: cluster)
    end

    it 'avoids N+1 database queries' do
      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { go }.count
      deployment_count = 2

      create_list(:deployment, deployment_count, :success, cluster: cluster)

      # TODO remove this leeway when we refactor away from deployment_platform
      # (https://gitlab.com/gitlab-org/gitlab/issues/13635)
      leeway = deployment_count * 2
      # it also appears that `can_read_pod_logs?` in ee/app/serializers/clusters/environment_entity.rb
      # generates 3 additional queries per deployment
      leeway += deployment_count * 3
      expect { go }.not_to exceed_all_query_limit(control_count + leeway)
    end
  end
end
