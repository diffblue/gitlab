# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::ContainerRegistryAuthenticationService do
  include AdminModeHelper

  context 'in maintenance mode' do
    include_context 'container registry auth service context'

    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project) }

    let(:log_data) do
      {
        message: 'Write access denied in maintenance mode',
        write_access_denied_in_maintenance_mode: true
      }
    end

    before do
      stub_maintenance_mode_setting(true)
      project.add_developer(current_user)
    end

    context 'allows developer to pull images' do
      let(:current_params) do
        { scopes: ["repository:#{project.full_path}:pull"] }
      end

      it_behaves_like 'a pullable'
    end

    context 'does not allow developer to push images' do
      let(:current_params) do
        { scopes: ["repository:#{project.full_path}:push"] }
      end

      it_behaves_like 'not a container repository factory'
      it_behaves_like 'logs an auth warning', ['push']
    end

    context 'does not allow developer to delete images' do
      let(:current_params) do
        { scopes: ["repository:#{project.full_path}:delete"] }
      end

      it_behaves_like 'not a container repository factory'
      it_behaves_like 'logs an auth warning', ['delete']
    end
  end

  context 'when not in maintenance mode' do
    it_behaves_like 'a container registry auth service'
  end

  context 'when over storage limit' do
    include_context 'container registry auth service context'

    let_it_be(:current_user) { create(:user) }
    let_it_be(:namespace) { create(:group) }

    before do
      allow_next_found_instance_of(Project) do |instance|
        allow(instance).to receive(:root_ancestor).and_return namespace
      end

      allow(namespace).to receive(:over_storage_limit?).and_return true
    end

    context 'when there is a project' do
      let_it_be(:project) { create(:project, namespace: namespace) }

      before do
        project.add_developer(current_user)
      end

      context 'does not allow developer to push images' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:push"] }
        end

        it_behaves_like 'not a container repository factory' do
          it 'returns an appropriate response' do
            expect(subject[:errors].first).to include(
              code: 'DENIED',
              message: 'You are above your storage quota! Visit https://docs.gitlab.com/ee/user/usage_quotas.html to learn more.'
            )
          end
        end
      end

      context 'allows developers to pull images' do
        let(:current_params) do
          { scopes: ["repository:#{project.full_path}:pull"] }
        end

        it_behaves_like 'a pullable'
      end

      context 'allows maintainers to delete images' do
        before do
          project.add_maintainer(current_user)
        end

        it_behaves_like 'allowed to delete container repository images'
      end
    end

    context 'when there is no project' do
      let(:project) { nil }

      it 'does not return a storage error' do
        expect(subject[:errors]).to be_nil
      end
    end
  end
end
