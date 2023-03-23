# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PushUser, feature_category: :geo_replication do
  let!(:user) { create(:user) }
  let!(:key) { create(:key, user: user) }

  let(:gl_id) { "key-#{key.id}" }

  subject { described_class.new(gl_id) }

  describe '#user' do
    context 'with a junk gl_id' do
      let(:gl_id) { "test" }

      it 'returns nil' do
        expect(subject.user).to be_nil
      end
    end

    context 'with an unsupported gl_id type' do
      let(:gl_id) { "user-#{user.id}" }

      it 'returns nil' do
        expect(subject.user).to be_nil
      end
    end

    context 'when the User associated to gl_id matches the User associated to gl_username' do
      it 'returns a User' do
        expect(subject.user).to be_a(User)
      end
    end
  end
end
