# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::NamespaceSettings::UpdateService, feature_category: :subgroups do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  subject { NamespaceSettings::UpdateService.new(user, group, params).execute }

  describe '#execute' do
    context 'as a normal user' do
      let(:params) { { prevent_forking_outside_group: true } }

      it 'does not change settings' do
        subject

        expect { group.save! }
          .not_to(change { group.namespace_settings.prevent_forking_outside_group })
      end

      it 'registers an error' do
        subject

        expect(group.errors[:prevent_forking_outside_group]).to include('Prevent forking setting was not saved')
      end
    end

    context 'as a group owner' do
      before do
        group.add_owner(user)
      end

      context 'for a group that does not have prevent forking feature' do
        let(:params) { { prevent_forking_outside_group: true } }

        it 'does not change settings' do
          subject

          expect { group.save! }
            .not_to(change { group.namespace_settings.prevent_forking_outside_group })
        end

        it 'registers an error' do
          subject

          expect(group.errors[:prevent_forking_outside_group]).to include('Prevent forking setting was not saved')
        end
      end

      context 'for a group that has prevent forking feature' do
        let(:params) { { prevent_forking_outside_group: true } }

        before do
          stub_licensed_features(group_forking_protection: true)
        end

        it 'changes settings' do
          subject
          group.save!

          expect(group.namespace_settings.reload.prevent_forking_outside_group).to eq(true)
        end
      end
    end
  end
end
