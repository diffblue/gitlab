# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::HookData::UserBuilder do
  let_it_be(:user) { create(:user) }

  describe '#build' do
    let(:event) { :create }
    let(:data) { described_class.new(user).build(event) }

    context 'data for Gitlab.com' do
      context 'contains `email_opted_in` attributes' do
        let(:user) { create(:user, name: 'John Doe', username: 'johndoe', email: 'john@example.com') }

        before do
          expect(Gitlab).to receive(:com?).and_return(true)
        end

        it 'returns correct email_opted_in data' do
          allow(user).to receive(:email_opted_in).and_return(user.email)
          allow(user).to receive(:email_opted_in_ip).and_return('192.168.1.1')
          allow(user).to receive(:email_opted_in_source).and_return('Gitlab.com')
          allow(user).to receive(:email_opted_in_at).and_return('2021-03-31T10:30:58Z')

          expect(data[:email_opted_in]).to eq('john@example.com')
          expect(data[:email_opted_in_ip]).to eq('192.168.1.1')
          expect(data[:email_opted_in_source]).to eq('Gitlab.com')
          expect(data[:email_opted_in_at]).to eq('2021-03-31T10:30:58Z')
        end
      end
    end
  end
end
