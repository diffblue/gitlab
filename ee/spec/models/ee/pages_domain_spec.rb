# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDomain, feature_category: :pages do
  describe '#root_group' do
    let(:pages_domain) { create(:pages_domain, project: project) }

    context 'when pages_domain does not belong to project' do
      let_it_be(:project) { nil }

      it 'returns nil' do
        expect(pages_domain.root_group).to eq(nil)
      end
    end

    context 'when pages_domain belongs to project' do
      context 'when project belongs to user' do
        let_it_be(:user_namespace) { create(:user).namespace }
        let_it_be(:project) { create(:project, namespace: user_namespace) }

        it 'returns nil' do
          expect(pages_domain.root_group).to eq(nil)
        end
      end

      context 'when project belongs to root group' do
        let_it_be(:root_group) { create(:group) }
        let_it_be(:project) { create(:project, namespace: root_group) }

        it 'returns root group' do
          expect(pages_domain.root_group).to eq(root_group)
        end

        context 'when project is in subgroup' do
          let_it_be(:subgroup) { create(:group, parent: root_group) }
          let_it_be(:project) { create(:project, namespace: subgroup) }

          it 'returns root group' do
            expect(pages_domain.root_group).to eq(root_group)
          end
        end
      end
    end
  end
end
