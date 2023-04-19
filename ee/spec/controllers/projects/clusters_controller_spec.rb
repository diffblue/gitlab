# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ClustersController, feature_category: :deployment_management do
  let_it_be(:project) { create(:project) }

  it_behaves_like 'cluster metrics' do
    let(:user) { create(:user) }
    let(:clusterable) { project }

    let(:cluster) do
      create(:cluster, :project, :provided_by_gcp, projects: [project])
    end

    let(:metrics_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: cluster
      }
    end

    before do
      clusterable.add_maintainer(user)
    end

    describe 'security' do
      let(:prometheus_adapter) { double(:prometheus_adapter, can_query?: true, query: nil) }

      before do
        sign_in(user)
        allow(controller).to receive(:prometheus_adapter).and_return(prometheus_adapter)
      end

      it 'is allowed for admin when admin mode enabled', :enable_admin_mode do
        expect { go }.to be_allowed_for(:admin)
      end

      it 'is denied for admin when admin mode disabled' do
        expect { go }.to be_denied_for(:admin)
      end

      it { expect { go }.to be_allowed_for(:owner).of(clusterable) }
      it { expect { go }.to be_allowed_for(:maintainer).of(clusterable) }
      it { expect { go }.to be_denied_for(:developer).of(clusterable) }
      it { expect { go }.to be_denied_for(:reporter).of(clusterable) }
      it { expect { go }.to be_denied_for(:guest).of(clusterable) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end
end
