# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CodeOwners::UsersLoader, feature_category: :source_code_management do
  let(:text) do
    <<~TXT
    This is a long text that mentions some users.
    @user-1, @user-2 and user@gitlab.org take a walk in the park.
    There they meet @user-4 that was out with other-user@gitlab.org.
    @user-1 thought it was late, so went home straight away
    TXT
  end

  let(:extractor) { Gitlab::CodeOwners::ReferenceExtractor.new(text) }
  let(:project) { create(:project) }
  let(:entry) { double('Entries') }

  describe '#load_to' do
    subject(:load_users) do
      described_class.new(project, extractor).load_to([entry])
    end

    before do
      allow(entry).to receive(:add_matching_users_from)
    end

    context 'input has no matching e-mail or usernames' do
      let(:text) { 'My test' }

      it 'returns an empty list of users' do
        load_users

        expect(entry).to have_received(:add_matching_users_from).with([])
      end
    end

    context 'nil input' do
      let(:text) { nil }

      it 'returns an empty relation when nil was passed' do
        load_users

        expect(entry).to have_received(:add_matching_users_from).with([])
      end
    end

    it 'returns the user case insensitive for usernames' do
      user = create(:user, username: "USER-4")
      project.add_developer(user)

      load_users

      expect(entry).to have_received(:add_matching_users_from).with([user])
    end

    it 'returns users for confirmed primary emails' do
      user = create(:user, email: 'user@gitlab.org')
      project.add_developer(user)

      load_users

      expect(entry).to have_received(:add_matching_users_from).with([user])
    end

    it 'returns users for unconfirmed primary emails' do
      user = create(:user, :unconfirmed, email: 'user@gitlab.org')
      project.add_developer(user)

      load_users

      expect(entry).to have_received(:add_matching_users_from).with([user])
    end

    it 'returns users for confirmed secondary emails' do
      user = create(:email, :confirmed, email: 'other-user@gitlab.org').user
      project.add_developer(user)

      load_users

      expect(entry).to have_received(:add_matching_users_from).with([user])
    end

    it 'does not return users for unconfirmed secondary emails' do
      user = create(:email, email: 'other-user@gitlab.org').user
      project.add_developer(user)

      load_users

      expect(entry).to have_received(:add_matching_users_from).with([])
    end

    context 'input as array of strings' do
      let(:text) { super().lines }

      it 'is treated as one string' do
        user_1 = create(:user, username: "USER-1")
        project.add_guest(user_1)

        user_4 = create(:user, username: "USER-4")
        project.add_reporter(user_4)

        user_email = create(:user, email: 'user@gitlab.org')
        project.add_maintainer(user_email)

        load_users

        expect(entry).to have_received(:add_matching_users_from) do |args|
          expect(args).to contain_exactly(user_1, user_4, user_email)
        end
      end
    end
  end
end
