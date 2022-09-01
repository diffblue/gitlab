# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironments::CreateService, '#execute' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:maintainer_access) { Gitlab::Access::MAINTAINER }

  let(:params) do
    attributes_for(:protected_environment,
                   deploy_access_levels_attributes: [{ access_level: maintainer_access }])
  end

  subject { described_class.new(container: project, current_user: user, params: params).execute }

  context 'with valid params' do
    it { is_expected.to be_truthy }

    it 'creates a record on ProtectedEnvironment' do
      expect { subject }.to change(ProtectedEnvironment, :count).by(1)
    end

    it 'creates a record on ProtectedEnvironment record' do
      expect { subject }.to change(ProtectedEnvironments::DeployAccessLevel, :count).by(1)
    end
  end

  context 'with invalid params' do
    let(:maintainer_access) { 0 }

    it 'returns a non-persisted Protected Environment record' do
      expect(subject.persisted?).to be_falsy
    end

    context 'multiple deploy access levels' do
      let(:params) do
        attributes_for(:protected_environment,
                       deploy_access_levels_attributes: [{ group_id: group.id, user_id: user_to_add.id }])
      end

      it_behaves_like 'invalid multiple deployment access levels' do
        it 'does not create protected environment' do
          expect { subject }.not_to change(ProtectedEnvironment, :count)
        end
      end
    end
  end

  context 'deploy access level by group' do
    let(:params) do
      attributes_for(:protected_environment,
                     deploy_access_levels_attributes: [{ group_id: group.id }])
    end

    it_behaves_like 'invalid protected environment group' do
      it 'does not create protected environment' do
        expect { subject }.not_to change(ProtectedEnvironment, :count)
      end
    end

    it_behaves_like 'valid protected environment group' do
      it 'creates protected environment' do
        expect { subject }.to change(ProtectedEnvironment, :count).by(1)
      end
    end
  end

  context 'deploy access level by user' do
    let(:params) do
      attributes_for(:protected_environment,
                     deploy_access_levels_attributes: [{ user_id: user_to_add.id }])
    end

    it_behaves_like 'invalid protected environment user' do
      it 'does not create protected environment' do
        expect { subject }.not_to change(ProtectedEnvironment, :count)
      end
    end

    it_behaves_like 'valid protected environment user' do
      it 'creates protected environment' do
        expect { subject }.to change(ProtectedEnvironment, :count).by(1)
      end
    end
  end
end
