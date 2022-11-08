# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::FeatureSetting do
  # rubocop:disable Gitlab/FeatureAvailableUsage
  describe 'default values' do
    it { expect(subject.wiki_access_level).to eq(20) }
  end

  describe '#feature_available?' do
    let_it_be_with_reload(:other_user) { create(:user) }
    let_it_be(:user) { create(:user) }

    let_it_be_with_reload(:group) do
      create(:group) do |g|
        g.add_guest(user)
      end
    end

    let(:features) { %w(wiki) }

    context 'when features are disabled' do
      it 'returns false' do
        update_all_group_features(group, features, Featurable::DISABLED)

        features.each do |feature|
          expect(group.feature_available?(feature.to_sym, user)).to eq(false), "#{feature} failed"
        end
      end
    end

    context 'when features are enabled only for group members' do
      it 'returns false when user is not a group member' do
        update_all_group_features(group, features, Featurable::PRIVATE)

        features.each do |feature|
          expect(group.feature_available?(feature.to_sym, other_user)).to eq(false), "#{feature} failed"
        end
      end

      it 'returns true when user is a group member' do
        update_all_group_features(group, features, Featurable::PRIVATE)

        features.each do |feature|
          expect(group.feature_available?(feature.to_sym, user)).to eq(true)
        end
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'returns true if user is an admin' do
          other_user.update_attribute(:admin, true)

          update_all_group_features(group, features, Featurable::PRIVATE)

          features.each do |feature|
            expect(group.feature_available?(feature.to_sym, other_user)).to eq(true)
          end
        end
      end

      context 'when admin mode is disabled' do
        it 'returns false when user is an admin' do
          other_user.update_attribute(:admin, true)

          update_all_group_features(group, features, Featurable::PRIVATE)

          features.each do |feature|
            expect(group.feature_available?(feature.to_sym, other_user)).to eq(false), "#{feature} failed"
          end
        end
      end
    end

    context 'when feature is enabled for everyone' do
      it 'returns true' do
        expect(group.feature_available?(:wiki)).to eq(true)
      end
    end

    context 'when feature has any other value' do
      it 'returns true' do
        group.group_feature.update_attribute(:wiki_access_level, 200)

        expect(group.feature_available?(:wiki)).to eq(true)
      end
    end

    def update_all_group_features(group, features, value)
      group_feature_attributes = features.to_h { |f| ["#{f}_access_level", value] }
      group.group_feature.update!(group_feature_attributes)
    end
  end
  # rubocop:enable Gitlab/FeatureAvailableUsage
end
