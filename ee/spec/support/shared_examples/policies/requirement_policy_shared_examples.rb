# frozen_string_literal: true

RSpec.shared_examples 'resource with requirement permissions' do
  include AdminModeHelper

  let(:all_permissions) do
    [:read_requirement, :create_requirement, :admin_requirement,
     :update_requirement, :destroy_requirement,
     :create_requirement_test_report, :export_requirements]
  end

  let(:manage_permissions) { all_permissions - [:destroy_requirement] }
  let(:non_read_permissions) { all_permissions - [:read_requirement] }

  subject { described_class.new(current_user, resource) }

  shared_examples 'user with manage permissions' do
    it { is_expected.to be_allowed(*manage_permissions) }
    it { is_expected.to be_disallowed(:destroy_requirement) }
  end

  shared_examples 'user with read-only permissions' do
    it { is_expected.to be_allowed(:read_requirement) }
    it { is_expected.to be_disallowed(*non_read_permissions) }
  end

  context 'when requirements feature is enabled' do
    before do
      stub_licensed_features(requirements: true)
    end

    context 'with admin', :enable_admin_mode do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(*all_permissions) }
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(*all_permissions) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it_behaves_like 'user with manage permissions'
    end

    context 'with developer' do
      let(:current_user) { developer }

      it_behaves_like 'user with manage permissions'
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it_behaves_like 'user with manage permissions'
    end

    context 'with guest' do
      let(:current_user) { guest }

      it_behaves_like 'user with read-only permissions'
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it_behaves_like 'user with read-only permissions'

      context 'with private resource parent' do
        before do
          parent = resource.is_a?(Project) ? resource : resource.resource_parent
          parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end

        it { is_expected.to be_disallowed(*all_permissions) }
      end
    end

    context 'when access level is disabled' do
      before do
        parent = resource.is_a?(Project) ? resource : resource.resource_parent
        parent.project_feature.update!(requirements_access_level: ProjectFeature::DISABLED)
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_disallowed(*all_permissions) }
      end

      context 'with admin' do
        let(:current_user) { admin }

        it { is_expected.to be_disallowed(*all_permissions) }
      end
    end

    context 'when access level is private' do
      before do
        parent = resource.is_a?(Project) ? resource : resource.resource_parent
        parent.project_feature.update!(requirements_access_level: ProjectFeature::PRIVATE)
      end

      context 'with admin user' do
        let(:current_user) { admin }

        it { is_expected.to be_disallowed(*all_permissions) }

        context 'with admin mode enabled' do
          before do
            enable_admin_mode!(current_user)
          end

          it { is_expected.to be_allowed(*all_permissions) }
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(*all_permissions) }
      end

      context 'with maintainer' do
        let(:current_user) { maintainer }

        it_behaves_like 'user with manage permissions'
      end

      context 'with developer' do
        let(:current_user) { developer }

        it_behaves_like 'user with manage permissions'
      end

      context 'with reporter' do
        let(:current_user) { reporter }

        it_behaves_like 'user with manage permissions'
      end

      context 'with guest' do
        let(:current_user) { guest }

        it_behaves_like 'user with read-only permissions'
      end

      context 'with non member' do
        let(:current_user) { create(:user) }

        it { is_expected.to be_disallowed(*all_permissions) }
      end
    end
  end

  context 'when requirements feature is disabled' do
    before do
      stub_licensed_features(requirements: false)
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_disallowed(*all_permissions) }
    end

    context 'with admin' do
      let(:current_user) { admin }

      it { is_expected.to be_disallowed(*all_permissions) }
    end
  end
end
