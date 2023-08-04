# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::GlobalIds, feature_category: :code_suggestions do
  subject(:helper) do
    Class.new do
      include API::Helpers::GlobalIds
    end.new
  end

  let(:user) { build(:user, id: 1) }
  let(:uuid1) { 'abcDEF' }
  let(:uuid2) { 'abcXYZ' }

  describe '#global_instance_and_user_id_for' do
    context 'for instance UUID component' do
      it 'is stable for the same UUID' do
        expect(Gitlab::CurrentSettings).to receive(:uuid).twice.and_return(uuid1)

        instance_id_1, _ = helper.global_instance_and_user_id_for(user)
        instance_id_2, _ = helper.global_instance_and_user_id_for(user)

        expect(instance_id_1).to be_instance_of(String)
        expect(instance_id_2).to eq(instance_id_1)
      end

      it 'is different across different instance UUIDs' do
        expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid1)
        expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid2)

        instance_id_1, _ = helper.global_instance_and_user_id_for(user)
        instance_id_2, _ = helper.global_instance_and_user_id_for(user)

        expect(instance_id_1).to be_instance_of(String)
        expect(instance_id_2).to be_instance_of(String)
        expect(instance_id_2).not_to eq(instance_id_1)
      end

      it 'is uuid-not-set if instance UUID is not set' do
        expect(Gitlab::CurrentSettings).to receive(:uuid).at_least(:once).and_return(nil)

        instance_id, _ = helper.global_instance_and_user_id_for(user)

        expect(instance_id).to eq('uuid-not-set')
      end

      it 'is uuid-not-set if instance UUID is blank' do
        expect(Gitlab::CurrentSettings).to receive(:uuid).at_least(:once).and_return('')

        instance_id, _ = helper.global_instance_and_user_id_for(user)

        expect(instance_id).to eq('uuid-not-set')
      end
    end

    context 'for user ID component' do
      it 'is stable for the same user and instance UUID' do
        expect(Gitlab::CurrentSettings).to receive(:uuid).twice.and_return(uuid1)

        _, user_id_1 = helper.global_instance_and_user_id_for(user)
        _, user_id_2 = helper.global_instance_and_user_id_for(user)

        expect(user_id_1).to be_instance_of(String)
        expect(user_id_2).to eq(user_id_2)
      end

      it 'is different for the same user but different instance UUIDs' do
        expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid1)
        expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid2)

        _, user_id_1 = helper.global_instance_and_user_id_for(user)
        _, user_id_2 = helper.global_instance_and_user_id_for(user)

        expect(user_id_1).to be_instance_of(String)
        expect(user_id_2).to be_instance_of(String)
        expect(user_id_2).not_to eq(user_id_1)
      end

      it 'is different for different users but same instance UUID' do
        expect(Gitlab::CurrentSettings).to receive(:uuid).twice.and_return(uuid1)

        _, user_id_1 = helper.global_instance_and_user_id_for(user)
        _, user_id_2 = helper.global_instance_and_user_id_for(build(:user, id: 2))

        expect(user_id_1).to be_instance_of(String)
        expect(user_id_2).to be_instance_of(String)
        expect(user_id_2).not_to eq(user_id_1)
      end

      it 'is different for different users and different instance UUIDs' do
        expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid1)
        expect(Gitlab::CurrentSettings).to receive(:uuid).ordered.and_return(uuid2)

        _, user_id_1 = helper.global_instance_and_user_id_for(user)
        _, user_id_2 = helper.global_instance_and_user_id_for(build(:user, id: 2))

        expect(user_id_1).to be_instance_of(String)
        expect(user_id_2).to be_instance_of(String)
        expect(user_id_2).not_to eq(user_id_1)
      end

      it 'is unknown if no user given' do
        expect(Gitlab::CurrentSettings).to receive(:uuid).at_least(:once).and_return(uuid1)

        _, user_id = helper.global_instance_and_user_id_for(nil)

        expect(user_id).to eq('unknown')
      end

      it 'raises an error if instance is not a user' do
        expect(Gitlab::CurrentSettings).to receive(:uuid).at_least(:once).and_return(uuid1)

        expect { helper.global_instance_and_user_id_for(build(:project, id: 1)) }.to raise_error(ArgumentError)
      end
    end
  end
end
