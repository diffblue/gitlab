# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::DevopsAdoption::EnabledNamespacesFinder do
  let_it_be(:admin_user) { create(:user, :admin) }
  let(:params) { {} }

  subject(:finder) { described_class.new(admin_user, params: params).execute }

  describe '#execute' do
    let_it_be(:root_group_1) { create(:group, name: 'bbb') }

    let_it_be(:enabled_namespace_1) { create(:devops_adoption_enabled_namespace, namespace: root_group_1, display_namespace: nil) }
    let_it_be(:enabled_namespace_2) { create(:devops_adoption_enabled_namespace, namespace: root_group_1, display_namespace: root_group_1) }
    let_it_be(:enabled_namespace_3) { create(:devops_adoption_enabled_namespace) }

    before do
      stub_licensed_features(instance_level_devops_adoption: true)
      stub_licensed_features(group_level_devops_adoption: true)
    end

    context 'with display_namespace provided' do
      let(:params) { super().merge(display_namespace: root_group_1) }

      it 'returns enabled_namespaces with given display namespace' do
        expect(finder).to eq([enabled_namespace_2])
      end
    end

    context 'without display_namespace provided' do
      it 'returns all namespace without display_namespace' do
        expect(finder).to eq([enabled_namespace_1])
      end
    end
  end
end
