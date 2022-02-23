# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Epics::Create do
  let_it_be(:group) { create(:group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:user) { create(:user) }

  subject(:mutation) { described_class.new(object: group, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    before do
      stub_licensed_features(epics: true)
    end

    subject { mutation.resolve(group_path: group.full_path, title: 'new epic title') }

    it 'raises a not accessible error' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can create epics' do
      before do
        group.add_developer(user)
      end

      it 'creates a new epic' do
        expect(subject[:epic][:title]).to eq('new epic title')
        expect(subject[:errors]).to be_empty
      end

      context 'with rate limiter', :freeze_time, :clean_gitlab_redis_rate_limiting do
        before do
          stub_application_setting(issues_create_limit: 1)
        end

        it 'prevents users from creating more epics' do
          result = mutation.resolve(group_path: group.full_path, title: 'new epic title')

          expect(result[:errors]).to be_empty

          expect do
            mutation.resolve(group_path: group.full_path, title: 'new epic title')
          end.to raise_error(RateLimitedService::RateLimitedError)
        end
      end
    end
  end
end
