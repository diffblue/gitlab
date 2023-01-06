# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::ProtectedRefAccess do
  included_in_classes = [ProtectedBranch::MergeAccessLevel,
                         ProtectedBranch::PushAccessLevel,
                         ProtectedTag::CreateAccessLevel]

  included_in_classes.each do |included_in_class|
    context "in #{included_in_class}" do
      let(:factory_name) { included_in_class.name.underscore.tr('/', '_') }
      let(:access_level) { build(factory_name) }
      let(:project) { access_level.project }
      let(:user) { create(:user) }
      let(:group) { create(:group) }

      before do
        project.add_developer(user)
        project.project_group_links.create!(group: group)
      end

      it "#{included_in_class} includes {described_class}" do
        expect(included_in_class.included_modules).to include(described_class)
      end

      context 'with the `protected_refs_for_users` feature disabled' do
        before do
          stub_licensed_features(protected_refs_for_users: false)
        end

        it "does not allow to create an #{included_in_class} with a group" do
          access_level.group = group

          expect(access_level).not_to be_valid
          expect(access_level.errors.count).to eq 1
          expect(access_level.errors).to include(:group)
        end

        it "does not allow to create an #{included_in_class} with a user" do
          access_level.user = user

          expect(access_level).not_to be_valid
          expect(access_level.errors.count).to eq 1
          expect(access_level.errors).to include(:user)
        end
      end

      context 'with the `protected_refs_for_users` feature enabled' do
        before do
          stub_licensed_features(protected_refs_for_users: true)
        end

        it "allows creating an #{included_in_class} with a group" do
          access_level.group = group

          expect(access_level).to be_valid
        end

        it 'does not allow to add non member groups' do
          access_level.group = create(:group)

          expect(access_level).not_to be_valid
          expect(access_level.errors.count).to eq 1
          expect(access_level.errors[:group].first).to eq 'does not have access to the project'
        end

        it "allows creating an #{included_in_class} with a user" do
          access_level.user = user

          expect(access_level).to be_valid
        end

        it 'does not allow to add non member users' do
          access_level.user = create(:user)

          expect(access_level).not_to be_valid
          expect(access_level.errors.count).to eq 1
          expect(access_level.errors[:user].first).to eq 'is not a member of the project'
        end

        it 'allows users with access through group' do
          new_user = create(:user)

          group.add_developer(new_user)
          access_level.user = new_user

          expect(access_level).to be_valid
        end
      end

      it 'requires access_level if no user or group is specified' do
        subject = build(factory_name, access_level: nil)

        expect(subject).not_to be_valid
      end

      it "doesn't require access_level if user specified" do
        subject = build(factory_name, access_level: nil, user: user)
        subject.project.add_developer(subject.user)

        expect(subject).to be_valid
      end

      it "doesn't require access_level if group specified" do
        subject = build(factory_name, access_level: nil, group: create(:group))
        subject.project.save!
        subject.project.project_group_links.create!(group: subject.group)

        expect(subject).to be_valid
      end

      context 'when importing' do
        subject { build(factory_name, importing: true) }

        it { is_expected.not_to validate_absence_of(:user) }
        it { is_expected.not_to validate_absence_of(:group) }
        it { is_expected.not_to receive(:validate_group_membership) }
        it { is_expected.not_to receive(:validate_user_membership) }
      end
    end
  end
end
