# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Abuse::ProjectsDownloadBanCheckService, feature_category: :insider_threat do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:project) { build_stubbed(:project, :in_group) }

  subject(:execute) { described_class.execute(user, project) }

  describe '.execute' do
    context 'when no user is given' do
      let(:user) { nil }

      it { is_expected.to be_success }
    end

    context 'when no project is given' do
      let(:project) { nil }

      it { is_expected.to be_success }
    end

    context 'when project is public' do
      let(:project) { build_stubbed(:project, :public) }

      it { is_expected.to be_success }
    end

    context 'when application-level OR namespace-level projects download throttling is configured' do
      let(:feature_flag_state) { true }
      let(:licensed_feature_state) { true }
      let(:service_response) { { banned: true } }

      shared_examples 'uses the result of the configured projects download throttle service' do
        context 'when the user is banned' do
          it { is_expected.to be_error }
        end

        context 'when the user is not banned' do
          let(:service_response) { { banned: false } }

          it { is_expected.to be_success }
        end

        context 'when licensed feature is not available' do
          let(:licensed_feature_state) { false }

          it { is_expected.to be_success }
        end
      end

      context 'when application-level projects download throttling is configured' do
        before do
          stub_licensed_features(git_abuse_rate_limit: licensed_feature_state)

          allow_next_instance_of(Users::Abuse::GitAbuse::ApplicationThrottleService, project, user) do |service|
            allow(service).to receive(:execute).and_return(service_response)
          end

          allow(Gitlab::CurrentSettings).to receive(:unique_project_download_limit_enabled?).and_return(true)
        end

        it_behaves_like 'uses the result of the configured projects download throttle service'

        context 'when setting is disabled' do
          before do
            allow(Gitlab::CurrentSettings).to receive(:unique_project_download_limit_enabled?).and_return(false)
          end

          it 'returns a success response' do
            expect(Users::Abuse::GitAbuse::ApplicationThrottleService).not_to receive(:execute)
            expect(execute).to be_success
          end
        end
      end

      context 'when namespace-level projects download throttling is configured' do
        before do
          stub_feature_flags(limit_unique_project_downloads_per_namespace_user: feature_flag_state)
          stub_licensed_features(unique_project_download_limit: licensed_feature_state)

          allow_next_instance_of(Users::Abuse::GitAbuse::NamespaceThrottleService, project, user) do |service|
            allow(service).to receive(:execute).and_return(service_response)
          end
        end

        context 'when feature flag is disabled' do
          let(:feature_flag_state) { false }

          it { is_expected.to be_success }
        end

        it_behaves_like 'uses the result of the configured projects download throttle service'

        context 'when project\'s root namespace is a User namespace' do
          let_it_be(:project) { build_stubbed(:project) }

          it 'returns a success response' do
            expect(Users::Abuse::GitAbuse::NamespaceThrottleService).not_to receive(:execute)
            expect(execute).to be_success
          end
        end
      end
    end

    context 'when both application- and namespace-level projects download throttling are configured' do
      let(:banned_from_application) { false }
      let(:banned_from_namespace) { false }

      before do
        stub_licensed_features(
          git_abuse_rate_limit: true,
          unique_project_download_limit: true
        )

        allow_next_instance_of(Users::Abuse::GitAbuse::ApplicationThrottleService, project, user) do |service|
          allow(service).to receive(:execute).and_return({ banned: banned_from_application })
        end
        allow_next_instance_of(Users::Abuse::GitAbuse::NamespaceThrottleService, project, user) do |service|
          allow(service).to receive(:execute).and_return({ banned: banned_from_namespace })
        end

        allow(Gitlab::CurrentSettings).to receive(:unique_project_download_limit_enabled?).and_return(true)
      end

      context 'when user is banned at the application-level' do
        let(:banned_from_application) { true }

        it { is_expected.to be_error }
      end

      context 'when user is banned at the namespace-level' do
        let(:banned_from_namespace) { true }

        it { is_expected.to be_error }
      end

      context 'when user is not banned' do
        it { is_expected.to be_success }
      end
    end
  end
end
