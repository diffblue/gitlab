# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationSetting do
  using RSpec::Parameterized::TableSyntax

  subject(:setting) { described_class.create_from_defaults }

  describe 'validations' do
    describe 'mirror', feature_category: :source_code_management do
      it { is_expected.to allow_value(100).for(:mirror_max_delay) }
      it { is_expected.not_to allow_value(nil).for(:mirror_max_delay) }
      it { is_expected.not_to allow_value(0).for(:mirror_max_delay) }
      it { is_expected.not_to allow_value(1.1).for(:mirror_max_delay) }
      it { is_expected.not_to allow_value(-1).for(:mirror_max_delay) }
      it { is_expected.not_to allow_value((Gitlab::Mirror::MIN_DELAY - 1.minute) / 60).for(:mirror_max_delay) }

      it { is_expected.to allow_value(10).for(:mirror_max_capacity) }
      it { is_expected.not_to allow_value(nil).for(:mirror_max_capacity) }
      it { is_expected.not_to allow_value(0).for(:mirror_max_capacity) }
      it { is_expected.not_to allow_value(1.1).for(:mirror_max_capacity) }
      it { is_expected.not_to allow_value(-1).for(:mirror_max_capacity) }

      it { is_expected.to allow_value(10).for(:mirror_capacity_threshold) }
      it { is_expected.not_to allow_value(nil).for(:mirror_capacity_threshold) }
      it { is_expected.not_to allow_value(0).for(:mirror_capacity_threshold) }
      it { is_expected.not_to allow_value(1.1).for(:mirror_capacity_threshold) }
      it { is_expected.not_to allow_value(-1).for(:mirror_capacity_threshold) }
      it { is_expected.not_to allow_value(subject.mirror_max_capacity + 1).for(:mirror_capacity_threshold) }
      it { is_expected.to allow_value(nil).for(:custom_project_templates_group_id) }
    end

    describe 'elasticsearch', feature_category: :global_search do
      it { is_expected.to allow_value(10).for(:search_max_shard_size_gb) }
      it { is_expected.not_to allow_value(0).for(:search_max_shard_size_gb) }
      it { is_expected.not_to allow_value(nil).for(:search_max_shard_size_gb) }
      it { is_expected.not_to allow_value(1.1).for(:search_max_shard_size_gb) }
      it { is_expected.not_to allow_value(-1).for(:search_max_shard_size_gb) }

      it { is_expected.to allow_value(10).for(:search_max_docs_denominator) }
      it { is_expected.not_to allow_value(0).for(:search_max_docs_denominator) }
      it { is_expected.not_to allow_value(nil).for(:search_max_docs_denominator) }
      it { is_expected.not_to allow_value(1.1).for(:search_max_docs_denominator) }
      it { is_expected.not_to allow_value(-1).for(:search_max_docs_denominator) }

      it { is_expected.to allow_value(10).for(:search_min_docs_before_rollover) }
      it { is_expected.not_to allow_value(0).for(:search_min_docs_before_rollover) }
      it { is_expected.not_to allow_value(nil).for(:search_min_docs_before_rollover) }
      it { is_expected.not_to allow_value(1.1).for(:search_min_docs_before_rollover) }
      it { is_expected.not_to allow_value(-1).for(:search_min_docs_before_rollover) }

      it { is_expected.to allow_value(10).for(:elasticsearch_indexed_file_size_limit_kb) }
      it { is_expected.not_to allow_value(0).for(:elasticsearch_indexed_file_size_limit_kb) }
      it { is_expected.not_to allow_value(nil).for(:elasticsearch_indexed_file_size_limit_kb) }
      it { is_expected.not_to allow_value(1.1).for(:elasticsearch_indexed_file_size_limit_kb) }
      it { is_expected.not_to allow_value(-1).for(:elasticsearch_indexed_file_size_limit_kb) }

      it { is_expected.to allow_value(10).for(:elasticsearch_indexed_field_length_limit) }
      it { is_expected.to allow_value(0).for(:elasticsearch_indexed_field_length_limit) }
      it { is_expected.not_to allow_value(nil).for(:elasticsearch_indexed_field_length_limit) }
      it { is_expected.not_to allow_value(1.1).for(:elasticsearch_indexed_field_length_limit) }
      it { is_expected.not_to allow_value(-1).for(:elasticsearch_indexed_field_length_limit) }

      it { is_expected.to allow_value(25).for(:elasticsearch_max_bulk_size_mb) }
      it { is_expected.not_to allow_value(nil).for(:elasticsearch_max_bulk_size_mb) }
      it { is_expected.not_to allow_value(0).for(:elasticsearch_max_bulk_size_mb) }
      it { is_expected.not_to allow_value(1.1).for(:elasticsearch_max_bulk_size_mb) }
      it { is_expected.not_to allow_value(-1).for(:elasticsearch_max_bulk_size_mb) }

      it { is_expected.to allow_value(2).for(:elasticsearch_max_bulk_concurrency) }
      it { is_expected.not_to allow_value(nil).for(:elasticsearch_max_bulk_concurrency) }
      it { is_expected.not_to allow_value(0).for(:elasticsearch_max_bulk_concurrency) }
      it { is_expected.not_to allow_value(1.1).for(:elasticsearch_max_bulk_concurrency) }
      it { is_expected.not_to allow_value(-1).for(:elasticsearch_max_bulk_concurrency) }

      it { is_expected.to allow_value(30).for(:elasticsearch_client_request_timeout) }
      it { is_expected.to allow_value(0).for(:elasticsearch_client_request_timeout) }
      it { is_expected.not_to allow_value(nil).for(:elasticsearch_client_request_timeout) }
      it { is_expected.not_to allow_value(1.1).for(:elasticsearch_client_request_timeout) }
      it { is_expected.not_to allow_value(-1).for(:elasticsearch_client_request_timeout) }

      it { is_expected.to allow_value('').for(:elasticsearch_username) }
      it { is_expected.to allow_value('a' * 255).for(:elasticsearch_username) }
      it { is_expected.not_to allow_value('a' * 256).for(:elasticsearch_username) }

      it { is_expected.to allow_value(true).for(:security_policy_global_group_approvers_enabled) }
      it { is_expected.to allow_value(false).for(:security_policy_global_group_approvers_enabled) }
      it { is_expected.not_to allow_value(nil).for(:security_policy_global_group_approvers_enabled) }
    end

    describe 'future_subscriptions', feature_category: :subscription_management do
      it { is_expected.to allow_value([{}]).for(:future_subscriptions) }
      it { is_expected.not_to allow_value({}).for(:future_subscriptions) }
      it { is_expected.not_to allow_value(nil).for(:future_subscriptions) }
    end

    describe 'required_instance', feature_category: :pipeline_composition do
      it { is_expected.to allow_value(nil).for(:required_instance_ci_template) }
      it { is_expected.not_to allow_value("").for(:required_instance_ci_template) }
      it { is_expected.not_to allow_value("  ").for(:required_instance_ci_template) }
      it { is_expected.to allow_value("template_name").for(:required_instance_ci_template) }
    end

    describe 'max_personal_access_token', feature_category: :user_management do
      it { is_expected.to allow_value(1).for(:max_personal_access_token_lifetime) }
      it { is_expected.to allow_value(nil).for(:max_personal_access_token_lifetime) }
      it { is_expected.to allow_value(10).for(:max_personal_access_token_lifetime) }
      it { is_expected.to allow_value(365).for(:max_personal_access_token_lifetime) }
      it { is_expected.not_to allow_value("value").for(:max_personal_access_token_lifetime) }
      it { is_expected.not_to allow_value(2.5).for(:max_personal_access_token_lifetime) }
      it { is_expected.not_to allow_value(-5).for(:max_personal_access_token_lifetime) }
      it { is_expected.not_to allow_value(366).for(:max_personal_access_token_lifetime) }
    end

    describe 'new_user_signups', feature_category: :onboarding do
      it { is_expected.to allow_value(nil).for(:new_user_signups_cap) }
      it { is_expected.to allow_value(1).for(:new_user_signups_cap) }
      it { is_expected.to allow_value(10).for(:new_user_signups_cap) }
      it { is_expected.to allow_value("").for(:new_user_signups_cap) }
      it { is_expected.not_to allow_value("value").for(:new_user_signups_cap) }
      it { is_expected.not_to allow_value(-1).for(:new_user_signups_cap) }
      it { is_expected.not_to allow_value(2.5).for(:new_user_signups_cap) }
    end

    describe 'git_two_factor', feature_category: :system_access do
      it { is_expected.to allow_value(1).for(:git_two_factor_session_expiry) }
      it { is_expected.to allow_value(10).for(:git_two_factor_session_expiry) }
      it { is_expected.to allow_value(10079).for(:git_two_factor_session_expiry) }
      it { is_expected.to allow_value(10080).for(:git_two_factor_session_expiry) }
      it { is_expected.not_to allow_value(nil).for(:git_two_factor_session_expiry) }
      it { is_expected.not_to allow_value("value").for(:git_two_factor_session_expiry) }
      it { is_expected.not_to allow_value(2.5).for(:git_two_factor_session_expiry) }
      it { is_expected.not_to allow_value(-5).for(:git_two_factor_session_expiry) }
      it { is_expected.not_to allow_value(0).for(:git_two_factor_session_expiry) }
      it { is_expected.not_to allow_value(10081).for(:git_two_factor_session_expiry) }

      it { is_expected.to validate_numericality_of(:max_ssh_key_lifetime).is_greater_than(0).is_less_than_or_equal_to(365).allow_nil }
      it { is_expected.to validate_numericality_of(:deletion_adjourned_period).is_greater_than(0).is_less_than_or_equal_to(90) }
    end

    describe 'dashboard', feature_category: :metrics do
      it { is_expected.to validate_numericality_of(:dashboard_limit).only_integer.is_greater_than_or_equal_to(0) }
      it { is_expected.to validate_numericality_of(:dashboard_notification_limit).only_integer.is_greater_than_or_equal_to(0) }
      it { is_expected.to validate_numericality_of(:dashboard_enforcement_limit).only_integer.is_greater_than_or_equal_to(0) }
      it { is_expected.to allow_value(true).for(:dashboard_limit_enabled) }
      it { is_expected.to allow_value(false).for(:dashboard_limit_enabled) }
      it { is_expected.not_to allow_value(nil).for(:dashboard_limit_enabled) }
    end

    describe 'when additional email text is enabled', feature_category: :user_profile do
      before do
        stub_licensed_features(email_additional_text: true)
      end

      it { is_expected.to allow_value("a" * subject.email_additional_text_character_limit).for(:email_additional_text) }
      it { is_expected.not_to allow_value("a" * (subject.email_additional_text_character_limit + 1)).for(:email_additional_text) }
    end

    describe 'when secret detection token revocation is enabled', feature_category: :secret_detection do
      before do
        stub_application_setting(secret_detection_token_revocation_enabled: true)
      end

      it { is_expected.to allow_value("http://test.com").for(:secret_detection_token_revocation_url) }
      it { is_expected.to allow_value("AKVD34#$%56").for(:secret_detection_token_revocation_token) }
      it { is_expected.to allow_value("http://test.com").for(:secret_detection_revocation_token_types_url) }
    end

    context 'when validating geo_node_allowed_ips', feature_category: :geo_replication do
      where(:allowed_ips, :is_valid) do
        "192.1.1.1"                   | true
        "192.1.1.0/24"                | true
        "192.1.1.0/24, 192.1.20.23"   | true
        "192.1.1.0/24, 192.23.0.0/16" | true
        "192.1.1.0/34"                | false
        "192.1.1.257"                 | false
        "192.1.1.257, 192.1.1.1"      | false
        "300.1.1.0/34"                | false
      end

      with_them do
        specify do
          setting.update_column(:geo_node_allowed_ips, allowed_ips)

          expect(setting.reload.valid?).to eq(is_valid)
        end
      end
    end

    context 'when validating globally_allowed_ips', feature_category: :geo_replication do
      where(:allowed_ips, :is_valid) do
        "192.1.1.1"                   | true
        "192.1.1.0/24"                | true
        "192.1.1.0/24, 192.1.20.23"   | true
        "192.1.1.0/24, 192.23.0.0/16" | true
        "192.1.1.0/34"                | false
        "192.1.1.257"                 | false
        "192.1.1.257, 192.1.1.1"      | false
        "300.1.1.0/34"                | false
      end

      with_them do
        specify do
          setting.update_column(:globally_allowed_ips, allowed_ips)

          expect(setting.reload.valid?).to eq(is_valid)
        end
      end
    end

    context 'when validating elasticsearch_url', feature_category: :global_search do
      where(:elasticsearch_url, :is_valid) do
        "http://es.localdomain" | true
        "https://es.localdomain" | true
        "http://es.localdomain, https://es.localdomain " | true
        "http://10.0.0.1" | true
        "https://10.0.0.1" | true
        "http://10.0.0.1, https://10.0.0.1" | true
        "http://localhost" | true
        "http://127.0.0.1" | true

        "es.localdomain" | false
        "10.0.0.1" | false
        "http://es.localdomain, es.localdomain" | false
        "http://es.localdomain, 10.0.0.1" | false
        "this_isnt_a_url" | false
      end

      with_them do
        specify do
          setting.elasticsearch_url = elasticsearch_url

          expect(setting.valid?).to eq(is_valid)
        end
      end
    end

    context 'Sentry validations', feature_category: :error_tracking do
      context 'when Sentry is enabled' do
        before do
          setting.sentry_enabled = true
        end

        it { is_expected.to allow_value(false).for(:sentry_enabled) }
        it { is_expected.not_to allow_value(nil).for(:sentry_enabled) }

        it { is_expected.to allow_value('http://example.com').for(:sentry_dsn) }
        it { is_expected.not_to allow_value("http://#{'a' * 255}.com").for(:sentry_dsn) }
        it { is_expected.not_to allow_value('example').for(:sentry_dsn) }
        it { is_expected.not_to allow_value(nil).for(:sentry_dsn) }

        it { is_expected.to allow_value('http://example.com').for(:sentry_clientside_dsn) }
        it { is_expected.to allow_value(nil).for(:sentry_clientside_dsn) }
        it { is_expected.not_to allow_value('example').for(:sentry_clientside_dsn) }
        it { is_expected.not_to allow_value("http://#{'a' * 255}.com").for(:sentry_clientside_dsn) }

        it { is_expected.to allow_value('production').for(:sentry_environment) }
        it { is_expected.not_to allow_value(nil).for(:sentry_environment) }
        it { is_expected.not_to allow_value('a' * 256).for(:sentry_environment) }
      end

      context 'when Sentry is disabled' do
        before do
          setting.sentry_enabled = false
        end

        it { is_expected.not_to allow_value(nil).for(:sentry_enabled) }
        it { is_expected.to allow_value(nil).for(:sentry_dsn) }
        it { is_expected.to allow_value(nil).for(:sentry_clientside_dsn) }
        it { is_expected.to allow_value(nil).for(:sentry_environment) }
      end
    end

    describe 'git abuse rate limit validations', feature_category: :insider_threat do
      it { is_expected.to validate_numericality_of(:max_number_of_repository_downloads).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(10_000) }
      it { is_expected.to validate_numericality_of(:max_number_of_repository_downloads_within_time_period).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(10.days.to_i) }

      describe 'git_rate_limit_users_allowlist' do
        let_it_be(:user) { create(:user) }

        it { is_expected.to allow_value([]).for(:git_rate_limit_users_allowlist) }
        it { is_expected.to allow_value([user.username]).for(:git_rate_limit_users_allowlist) }
        it { is_expected.not_to allow_value(nil).for(:git_rate_limit_users_allowlist) }
        it { is_expected.not_to allow_value(['unknown_user']).for(:git_rate_limit_users_allowlist) }

        context 'when maximum length is exceeded' do
          it 'is not valid' do
            subject.git_rate_limit_users_allowlist = Array.new(101) { |i| "user#{i}" }

            expect(subject).not_to be_valid
            expect(subject.errors[:git_rate_limit_users_allowlist]).to include("exceeds maximum length (100 usernames)")
          end
        end

        context 'when attr is not changed' do
          before do
            subject.git_rate_limit_users_allowlist = [non_existing_record_id]
            subject.save!(validate: false)
          end

          it { is_expected.to be_valid }
        end
      end

      describe 'git_rate_limit_users_alertlist' do
        let_it_be(:user) { create(:user) }

        it { is_expected.to allow_value([]).for(:git_rate_limit_users_alertlist) }
        it { is_expected.to allow_value([user.id]).for(:git_rate_limit_users_alertlist) }
        it { is_expected.to allow_value(nil).for(:git_rate_limit_users_alertlist) }
        it { is_expected.not_to allow_value([non_existing_record_id]).for(:git_rate_limit_users_alertlist) }

        context 'when maximum length is exceeded' do
          it 'is not valid' do
            subject.git_rate_limit_users_alertlist = Array.new(101)

            expect(subject).not_to be_valid
            expect(subject.errors[:git_rate_limit_users_alertlist]).to include('exceeds maximum length (100 user ids)')
          end
        end

        context 'when attr is not changed' do
          before do
            subject.git_rate_limit_users_alertlist = [non_existing_record_id]
            subject.save!(validate: false)
          end

          it { is_expected.to be_valid }
        end

        context 'when empty' do
          let!(:active_admin) { create(:admin) }
          let!(:inactive_admin) { create(:admin, :deactivated) }

          it 'returns the user ids of the active admins' do
            expect(subject.git_rate_limit_users_alertlist).to contain_exactly(active_admin.id)
          end
        end

        context 'when not empty' do
          let(:alerted_user_ids) { [1, 2] }

          before do
            subject.update_attribute(:git_rate_limit_users_alertlist, alerted_user_ids)
          end

          it 'returns the set user ids' do
            expect(subject.git_rate_limit_users_alertlist).to eq(alerted_user_ids)
          end
        end
      end

      describe 'unique_project_download_limit_enabled' do
        context 'when max_number_of_repository_downloads is 0' do
          before do
            subject.max_number_of_repository_downloads = 0
            subject.max_number_of_repository_downloads_within_time_period = 300
            subject.save!
          end

          it 'allows project to be indexed' do
            expect(setting.unique_project_download_limit_enabled?).to be(false)
          end
        end

        context 'when max_number_of_repository_downloads_within_time_period is 0' do
          before do
            subject.max_number_of_repository_downloads = 1
            subject.max_number_of_repository_downloads_within_time_period = 0
            subject.save!
          end

          it 'allows project to be indexed' do
            expect(setting.unique_project_download_limit_enabled?).to be(false)
          end
        end

        context 'when neither are 0' do
          before do
            subject.max_number_of_repository_downloads = 1
            subject.max_number_of_repository_downloads_within_time_period = 300
            subject.save!
          end

          it 'allows project to be indexed' do
            expect(setting.unique_project_download_limit_enabled?).to be(true)
          end
        end
      end
    end

    describe 'when validating product analytics settings', feature_category: :product_analytics do
      context 'when product analytics is enabled' do
        before do
          setting.product_analytics_enabled = true
        end

        it { is_expected.to allow_value(false).for(:product_analytics_enabled) }
        it { is_expected.to allow_value("").for(:product_analytics_enabled) }

        it { is_expected.to allow_value("https://jitsu.gitlab.com").for(:jitsu_host) }
        it { is_expected.to allow_value("http://localhost:8000").for(:jitsu_host) }
        it { is_expected.not_to allow_value("invalid.host").for(:jitsu_host) }
        it { is_expected.not_to allow_value(nil).for(:jitsu_host) }
        it { is_expected.not_to allow_value("").for(:jitsu_host) }

        it { is_expected.to allow_value('g0maofw84gx5sjxgse2k').for(:jitsu_project_xid) }
        it { is_expected.not_to allow_value(nil).for(:jitsu_project_xid) }
        it { is_expected.not_to allow_value("").for(:jitsu_project_xid) }

        it { is_expected.to allow_value('jitsu.admin@gitlab.com').for(:jitsu_administrator_email) }
        it { is_expected.not_to allow_value('invalid_admin_email.com').for(:jitsu_administrator_email) }
        it { is_expected.not_to allow_value(nil).for(:jitsu_administrator_email) }
        it { is_expected.not_to allow_value("").for(:jitsu_administrator_email) }

        it { is_expected.to allow_value('xxxxxxxx').for(:jitsu_administrator_password) }
        it { is_expected.not_to allow_value(nil).for(:jitsu_administrator_password) }
        it { is_expected.not_to allow_value("").for(:jitsu_administrator_password) }

        it { is_expected.to allow_value('https://user:pass@clickhouse.gitlab.com:8123').for(:product_analytics_clickhouse_connection_string) }
        it { is_expected.not_to allow_value(nil).for(:product_analytics_clickhouse_connection_string) }
        it { is_expected.not_to allow_value("").for(:product_analytics_clickhouse_connection_string) }

        it { is_expected.to allow_value('https://cube.gitlab.com').for(:cube_api_base_url) }
        it { is_expected.to allow_value('https://localhost:4000').for(:cube_api_base_url) }
        it { is_expected.not_to allow_value(nil).for(:cube_api_base_url) }
        it { is_expected.not_to allow_value("").for(:cube_api_base_url) }

        it { is_expected.to allow_value('420d0e1b73b2ad4acd21c92e533be327').for(:cube_api_key) }
        it { is_expected.not_to allow_value(nil).for(:cube_api_key) }
        it { is_expected.not_to allow_value("").for(:cube_api_key) }

        it { is_expected.to allow_value("https://collector.gitlab.com").for(:product_analytics_data_collector_host) }
        it { is_expected.to allow_value("http://localhost:8000").for(:product_analytics_data_collector_host) }
        it { is_expected.not_to allow_value("invalid.host").for(:product_analytics_data_collector_host) }
        it { is_expected.not_to allow_value(nil).for(:product_analytics_data_collector_host) }
        it { is_expected.not_to allow_value("").for(:product_analytics_data_collector_host) }
      end

      context 'when product analytics is disabled' do
        before do
          setting.product_analytics_enabled = false
        end

        it { is_expected.to allow_value(nil).for(:jitsu_host) }
        it { is_expected.to allow_value(nil).for(:jitsu_project_xid) }
        it { is_expected.to allow_value(nil).for(:jitsu_administrator_email) }
        it { is_expected.to allow_value(nil).for(:jitsu_administrator_password) }
        it { is_expected.to allow_value(nil).for(:product_analytics_clickhouse_connection_string) }
        it { is_expected.to allow_value(nil).for(:cube_api_base_url) }
        it { is_expected.to allow_value(nil).for(:cube_api_key) }
        it { is_expected.to allow_value(nil).for(:product_analytics_data_collector_host) }
      end
    end

    describe 'package_metadata_purl_types', feature_category: :software_composition_analysis do
      it { is_expected.to allow_value(1).for(:package_metadata_purl_types) }
      it { is_expected.to allow_value(12).for(:package_metadata_purl_types) }
      it { is_expected.not_to allow_value(13).for(:package_metadata_purl_types) }
      it { is_expected.not_to allow_value(0).for(:package_metadata_purl_types) }
    end
  end

  describe 'search curation settings after .create_from_defaults', feature_category: :global_search do
    it { expect(setting.search_max_shard_size_gb).to eq(1) }
    it { expect(setting.search_max_docs_denominator).to eq(100) }
    it { expect(setting.search_min_docs_before_rollover).to eq(50) }

    context 'in production environments' do
      before do
        stub_rails_env "production"
      end

      it { expect(setting.search_max_shard_size_gb).to eq(50) }
      it { expect(setting.search_max_docs_denominator).to eq(5_000_000) }
      it { expect(setting.search_min_docs_before_rollover).to eq(100_000) }
    end
  end

  describe '#should_check_namespace_plan?', feature_category: :subgroups do
    before do
      stub_application_setting(check_namespace_plan: check_namespace_plan_column)
      allow(::Gitlab).to receive(:org_or_com?) { gl_com }

      # This stub was added in order to force a fallback to Gitlab.org_or_com?
      # call testing.
      # Gitlab.org_or_com? responds to `false` on test envs
      # and we want to make sure we're still testing
      # should_check_namespace_plan? method through the test-suite (see
      # https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/18461#note_69322821).
      allow(Rails).to receive_message_chain(:env, :development?).and_return(false)
      allow(Rails).to receive_message_chain(:env, :test?).and_return(false)
      allow(Rails).to receive_message_chain(:env, :production?).and_return(false)
    end

    subject { setting.should_check_namespace_plan? }

    context 'when check_namespace_plan true AND on GitLab.com' do
      let(:check_namespace_plan_column) { true }
      let(:gl_com) { true }

      it 'returns true' do
        is_expected.to eq(true)
      end
    end

    context 'when check_namespace_plan true AND NOT on GitLab.com' do
      let(:check_namespace_plan_column) { true }
      let(:gl_com) { false }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'when check_namespace_plan false AND on GitLab.com' do
      let(:check_namespace_plan_column) { false }
      let(:gl_com) { true }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end
  end

  describe '#repository_size_limit column', feature_category: :source_code_management do
    it 'support values up to 8 exabytes' do
      setting.update_column(:repository_size_limit, 8.exabytes - 1)

      setting.reload

      expect(setting.repository_size_limit).to eql(8.exabytes - 1)
    end
  end

  describe 'elasticsearch licensing', feature_category: :global_search do
    before do
      setting.elasticsearch_search = true
      setting.elasticsearch_indexing = true
    end

    def expect_is_es_licensed
      expect(License).to receive(:feature_available?).with(:elastic_search).at_least(:once)
    end

    it 'disables elasticsearch when unlicensed' do
      expect_is_es_licensed.and_return(false)

      expect(setting.elasticsearch_indexing?).to be_falsy
      expect(setting.elasticsearch_indexing).to be_falsy
      expect(setting.elasticsearch_search?).to be_falsy
      expect(setting.elasticsearch_search).to be_falsy
    end

    it 'enables elasticsearch when licensed' do
      expect_is_es_licensed.and_return(true)

      expect(setting.elasticsearch_indexing?).to be_truthy
      expect(setting.elasticsearch_indexing).to be_truthy
      expect(setting.elasticsearch_search?).to be_truthy
      expect(setting.elasticsearch_search).to be_truthy
    end
  end

  describe '#elasticsearch_pause_indexing', feature_category: :global_search do
    before do
      setting.elasticsearch_pause_indexing = true
    end

    it 'resumes indexing' do
      expect(ElasticIndexingControlWorker).to receive(:perform_async)

      setting.save!
      setting.elasticsearch_pause_indexing = false
      setting.save!
    end
  end

  describe '#elasticsearch_url', feature_category: :global_search do
    it 'presents a single URL as a one-element array' do
      setting.elasticsearch_url = 'http://example.com'

      expect(setting.elasticsearch_url).to match_array([URI.parse('http://example.com')])
    end

    it 'presents multiple URLs as a many-element array' do
      setting.elasticsearch_url = 'http://example.com,https://invalid.invalid:9200'

      expect(setting.elasticsearch_url).to match_array([URI.parse('http://example.com'), URI.parse('https://invalid.invalid:9200')])
    end

    it 'strips whitespace from around URLs' do
      setting.elasticsearch_url = ' http://example.com, https://invalid.invalid:9200 '

      expect(setting.elasticsearch_url).to match_array([URI.parse('http://example.com'), URI.parse('https://invalid.invalid:9200')])
    end

    it 'strips trailing slashes from URLs' do
      setting.elasticsearch_url = 'http://example.com/, https://example.com:9200/, https://example.com:9200/prefix//'

      expect(setting.elasticsearch_url).to match_array([URI.parse('http://example.com'), URI.parse('https://example.com:9200'), URI.parse('https://example.com:9200/prefix')])
    end
  end

  describe '#elasticsearch_url_with_credentials', feature_category: :global_search do
    let(:elasticsearch_url) { "#{host1},#{host2}" }
    let(:host1) { 'http://example.com' }
    let(:host2) { 'https://example.org:9200' }
    let(:elasticsearch_username) { 'elastic' }
    let(:elasticsearch_password) { 'password' }

    before do
      setting.elasticsearch_url = elasticsearch_url
      setting.elasticsearch_username = elasticsearch_username
      setting.elasticsearch_password = elasticsearch_password
    end

    context 'when credentials are embedded in url' do
      let(:elasticsearch_url) { 'http://username:password@example.com,https://test:test@example.org:9200' }

      it 'ignores them and uses elasticsearch_username and elasticsearch_password settings' do
        expect(setting.elasticsearch_url_with_credentials).to match_array(
          [
            { scheme: 'http', user: elasticsearch_username, password: elasticsearch_password, host: 'example.com', path: '', port: 80 },
            { scheme: 'https', user: elasticsearch_username, password: elasticsearch_password, host: 'example.org', path: '', port: 9200 }
          ])
      end
    end

    context 'when credential settings are blank' do
      let(:elasticsearch_username) { nil }
      let(:elasticsearch_password) { nil }

      it 'does not return credential info' do
        expect(setting.elasticsearch_url_with_credentials).to match_array(
          [
            { scheme: 'http', host: 'example.com', path: '', port: 80 },
            { scheme: 'https', host: 'example.org', path: '', port: 9200 }
          ])
      end

      context 'and url contains credentials' do
        let(:elasticsearch_url) { 'http://username:password@example.com,https://test:test@example.org:9200' }

        it 'returns credentials from url' do
          expect(setting.elasticsearch_url_with_credentials).to match_array(
            [
              { scheme: 'http', user: 'username', password: 'password', host: 'example.com', path: '', port: 80 },
              { scheme: 'https', user: 'test', password: 'test', host: 'example.org', path: '', port: 9200 }
            ])
        end
      end

      context 'and url contains credentials with special characters' do
        let(:elasticsearch_url) { 'http://admin:p%40ssword@localhost:9200/' }

        it 'returns decoded credentials from url' do
          expect(setting.elasticsearch_url_with_credentials).to match_array(
            [
              { scheme: 'http', user: 'admin', password: 'p@ssword', host: 'localhost', path: '', port: 9200 }
            ])
        end
      end
    end

    context 'when credentials settings have special characters' do
      let(:elasticsearch_username) { 'foo/admin' }
      let(:elasticsearch_password) { 'b@r+baz!$' }

      it 'returns the correct values' do
        expect(setting.elasticsearch_url_with_credentials).to match_array(
          [
            { scheme: 'http', user: elasticsearch_username, password: elasticsearch_password, host: 'example.com', path: '', port: 80 },
            { scheme: 'https', user: elasticsearch_username, password: elasticsearch_password, host: 'example.org', path: '', port: 9200 }
          ])
      end
    end
  end

  describe '#elasticsearch_password', feature_category: :global_search do
    it 'does not modify password if it is unchanged in the form' do
      setting.elasticsearch_password = 'foo'
      setting.elasticsearch_password = ApplicationSetting::MASK_PASSWORD

      expect(setting.elasticsearch_password).to eq('foo')
    end
  end

  describe '#elasticsearch_config', feature_category: :global_search do
    it 'places all elasticsearch configuration values into a hash' do
      setting.update!(
        elasticsearch_url: 'http://example.com:9200',
        elasticsearch_username: 'foo',
        elasticsearch_password: 'bar',
        elasticsearch_aws: false,
        elasticsearch_aws_region: 'test-region',
        elasticsearch_aws_access_key: 'test-access-key',
        elasticsearch_aws_secret_access_key: 'test-secret-access-key',
        elasticsearch_max_bulk_size_mb: 67,
        elasticsearch_max_bulk_concurrency: 8,
        elasticsearch_client_request_timeout: 30
      )

      expect(setting.elasticsearch_config).to eq(
        url: [Gitlab::Elastic::Helper.connection_settings(uri: URI.parse('http://foo:bar@example.com:9200'))],
        aws: false,
        aws_region: 'test-region',
        aws_access_key: 'test-access-key',
        aws_secret_access_key: 'test-secret-access-key',
        max_bulk_size_bytes: 67.megabytes,
        max_bulk_concurrency: 8,
        client_request_timeout: 30
      )

      setting.update!(
        elasticsearch_client_request_timeout: 0
      )

      expect(setting.elasticsearch_config).not_to include(:client_request_timeout)
    end

    context 'limiting namespaces and projects' do
      before do
        setting.update!(elasticsearch_indexing: true)
        setting.update!(elasticsearch_limit_indexing: true)
      end

      context 'namespaces' do
        context 'with personal namespaces' do
          let(:namespaces) { create_list(:namespace, 2) }
          let!(:indexed_namespace) { create :elasticsearch_indexed_namespace, namespace: namespaces.last }

          it 'tells you if a namespace is allowed to be indexed' do
            expect(setting.elasticsearch_indexes_namespace?(namespaces.last)).to be_truthy
            expect(setting.elasticsearch_indexes_namespace?(namespaces.first)).to be_falsey
          end
        end

        context 'with groups' do
          let(:groups) { create_list(:group, 2) }
          let!(:indexed_namespace) { create(:elasticsearch_indexed_namespace, namespace: groups.last) }
          let!(:child_group) { create(:group, parent: groups.first) }
          let!(:child_group_indexed_through_parent) { create(:group, parent: groups.last) }

          specify do
            create(:elasticsearch_indexed_namespace, namespace: child_group)

            expect(setting.elasticsearch_limited_namespaces).to match_array(
              [groups.last, child_group, child_group_indexed_through_parent])
            expect(setting.elasticsearch_limited_namespaces(true)).to match_array(
              [groups.last, child_group])
          end
        end

        describe '#elasticsearch_indexes_project?' do
          shared_examples 'whether the project is indexed' do
            context 'when project is in a subgroup' do
              let(:root_group) { create(:group) }
              let(:subgroup) { create(:group, parent: root_group) }
              let(:project) { create(:project, group: subgroup) }

              before do
                create(:elasticsearch_indexed_namespace, namespace: root_group)
              end

              it 'allows project to be indexed' do
                expect(setting.elasticsearch_indexes_project?(project)).to be(true)
              end
            end

            context 'when project is in a namespace' do
              let(:namespace) { create(:namespace) }
              let(:project) { create(:project, namespace: namespace) }

              before do
                create(:elasticsearch_indexed_namespace, namespace: namespace)
              end

              it 'allows project to be indexed' do
                expect(setting.elasticsearch_indexes_project?(project)).to be(true)
              end
            end
          end

          it_behaves_like 'whether the project is indexed'
        end
      end

      context 'projects' do
        let(:projects) { create_list(:project, 2) }
        let!(:indexed_project) { create :elasticsearch_indexed_project, project: projects.last }

        it 'tells you if a project is allowed to be indexed' do
          expect(setting.elasticsearch_indexes_project?(projects.last)).to be(true)
          expect(setting.elasticsearch_indexes_project?(projects.first)).to be(false)
        end

        it 'returns projects that are allowed to be indexed' do
          project_indexed_through_namespace = create(:project)
          create :elasticsearch_indexed_namespace, namespace: project_indexed_through_namespace.namespace

          expect(setting.elasticsearch_limited_projects).to match_array(
            [projects.last, project_indexed_through_namespace])
        end

        it 'uses the ElasticsearchEnabledCache cache' do
          expect(::Gitlab::Elastic::ElasticsearchEnabledCache).to receive(:fetch).and_return(true)

          expect(setting.elasticsearch_indexes_project?(projects.first)).to be(true)
        end
      end
    end
  end

  describe '#invalidate_elasticsearch_indexes_cache', feature_category: :global_search do
    it 'deletes the ElasticsearchEnabledCache for projects and namespaces' do
      expect(::Gitlab::Elastic::ElasticsearchEnabledCache).to receive(:delete).with(:project)
      expect(::Gitlab::Elastic::ElasticsearchEnabledCache).to receive(:delete).with(:namespace)

      setting.invalidate_elasticsearch_indexes_cache!
    end
  end

  describe '#invalidate_elasticsearch_indexes_cache_for_project!', feature_category: :global_search do
    it 'deletes the ElasticsearchEnabledCache for a single project' do
      project_id = 1
      expect(::Gitlab::Elastic::ElasticsearchEnabledCache).to receive(:delete_record).with(:project, project_id)

      setting.invalidate_elasticsearch_indexes_cache_for_project!(project_id)
    end
  end

  describe '#invalidate_elasticsearch_indexes_cache_for_namespace!', feature_category: :global_search do
    it 'deletes the ElasticsearchEnabledCache for a namespace' do
      namespace_id = 1
      expect(::Gitlab::Elastic::ElasticsearchEnabledCache).to receive(:delete_record).with(:namespace, namespace_id)

      setting.invalidate_elasticsearch_indexes_cache_for_namespace!(namespace_id)
    end
  end

  describe '#search_using_elasticsearch?', feature_category: :global_search do
    # Constructs a truth table to run the specs against
    where(indexing: [true, false], searching: [true, false], limiting: [true, false], advanced_global_search_for_limited_indexing: [true, false])

    with_them do
      let_it_be(:included_project_container) { create(:elasticsearch_indexed_project) }
      let_it_be(:included_namespace_container) { create(:elasticsearch_indexed_namespace) }

      let_it_be(:included_project) { included_project_container.project }
      let_it_be(:included_namespace) { included_namespace_container.namespace }

      let_it_be(:excluded_project) { create(:project) }
      let_it_be(:excluded_namespace) { create(:namespace) }

      let(:only_when_enabled_globally) { indexing && searching && !limiting }

      subject { setting.search_using_elasticsearch?(scope: scope) }

      before do
        setting.update!(
          elasticsearch_indexing: indexing,
          elasticsearch_search: searching,
          elasticsearch_limit_indexing: limiting
        )

        stub_feature_flags(advanced_global_search_for_limited_indexing: advanced_global_search_for_limited_indexing)
      end

      context 'global scope' do
        let(:scope) { nil }

        it { is_expected.to eq(indexing && searching && (!limiting || advanced_global_search_for_limited_indexing)) }
      end

      context 'namespace (in scope)' do
        let(:scope) { included_namespace }

        it { is_expected.to eq(indexing && searching) }
      end

      context 'namespace (not in scope)' do
        let(:scope) { excluded_namespace }

        it { is_expected.to eq(only_when_enabled_globally) }
      end

      context 'project (in scope)' do
        let(:scope) { included_project }

        it { is_expected.to eq(indexing && searching) }
      end

      context 'project (not in scope)' do
        let(:scope) { excluded_project }

        it { is_expected.to eq(only_when_enabled_globally) }
      end

      context 'array of projects (all in scope)' do
        let(:scope) { [included_project] }

        it { is_expected.to eq(indexing && searching) }
      end

      context 'array of projects (all not in scope)' do
        let(:scope) { [excluded_project] }

        it { is_expected.to eq(only_when_enabled_globally) }
      end

      context 'array of projects (some in scope)' do
        let(:scope) { [included_project, excluded_project] }

        it { is_expected.to eq(indexing && searching) }
      end
    end
  end

  describe 'custom project templates', feature_category: :projects do
    let(:group) { create(:group) }
    let(:projects) { create_list(:project, 3, namespace: group) }

    before do
      setting.update_column(:custom_project_templates_group_id, group.id)

      setting.reload
    end

    context 'when custom_project_templates feature is enabled' do
      before do
        stub_licensed_features(custom_project_templates: true)
      end

      describe '#custom_project_templates_enabled?' do
        it 'returns true' do
          expect(setting.custom_project_templates_enabled?).to be_truthy
        end
      end

      describe '#custom_project_template_id' do
        it 'returns group id' do
          expect(setting.custom_project_templates_group_id).to eq group.id
        end
      end

      describe '#available_custom_project_templates' do
        it 'returns group projects' do
          expect(setting.available_custom_project_templates).to match_array(projects)
        end

        it 'returns an empty array if group is not set' do
          allow(setting).to receive(:custom_project_template_id).and_return(nil)

          expect(setting.available_custom_project_templates).to eq []
        end
      end
    end

    context 'when custom_project_templates feature is disabled' do
      before do
        stub_licensed_features(custom_project_templates: false)
      end

      describe '#custom_project_templates_enabled?' do
        it 'returns false' do
          expect(setting.custom_project_templates_enabled?).to be false
        end
      end

      describe '#custom_project_template_id' do
        it 'returns false' do
          expect(setting.custom_project_templates_group_id).to be false
        end
      end

      describe '#available_custom_project_templates' do
        it 'returns an empty relation' do
          expect(setting.available_custom_project_templates).to be_empty
        end
      end
    end
  end

  describe '#instance_review_permitted?', feature_category: :onboarding do
    subject { setting.instance_review_permitted? }

    context 'for instances with a valid license' do
      before do
        license = create(:license, plan: ::License::PREMIUM_PLAN)
        allow(License).to receive(:current).and_return(license)
      end

      it 'is not permitted' do
        expect(subject).to be_falsey
      end
    end

    context 'for instances without a valid license' do
      before do
        allow(License).to receive(:current).and_return(nil)
        expect(Rails.cache).to receive(:fetch).and_return(
          ::ApplicationSetting::INSTANCE_REVIEW_MIN_USERS + users_over_minimum
        )
      end

      where(users_over_minimum: [-1, 0, 1])

      with_them do
        it { is_expected.to be(users_over_minimum >= 0) }
      end
    end
  end

  describe '#max_personal_access_token_lifetime_from_now', feature_category: :user_management do
    subject { setting.max_personal_access_token_lifetime_from_now }

    let(:days_from_now) { nil }

    before do
      stub_application_setting(max_personal_access_token_lifetime: days_from_now)
    end

    context 'when max_personal_access_token_lifetime is defined' do
      let(:days_from_now) { 30 }

      it 'is a date time' do
        expect(subject).to be_a Time
      end

      it 'is in the future' do
        expect(subject).to be > Time.zone.now
      end

      it 'is in days_from_now' do
        expect((subject.to_date - Date.current).to_i).to eq days_from_now
      end
    end

    context 'when max_personal_access_token_lifetime is nil' do
      it 'is nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe 'updates to max_personal_access_token_lifetime', feature_category: :user_management do
    context 'without personal_access_token_expiration_policy licensed' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: false)
      end

      it "doesn't call the update lifetime service" do
        expect(::PersonalAccessTokens::Instance::UpdateLifetimeService).not_to receive(:new)

        setting.save!
      end
    end

    context 'with personal_access_token_expiration_policy licensed' do
      before do
        setting.max_personal_access_token_lifetime = 30
        stub_licensed_features(personal_access_token_expiration_policy: true)
      end

      it 'executes the update lifetime service' do
        expect_next_instance_of(::PersonalAccessTokens::Instance::UpdateLifetimeService) do |service|
          expect(service).to receive(:execute)
        end

        setting.save!
      end
    end
  end

  describe '#compliance_frameworks', feature_category: :compliance_management do
    it 'sorts the list' do
      setting.compliance_frameworks = [5, 4, 1, 3, 2]

      expect(setting.compliance_frameworks).to eq([1, 2, 3, 4, 5])
    end

    it 'removes duplicates' do
      setting.compliance_frameworks = [1, 2, 2, 3, 3, 3]

      expect(setting.compliance_frameworks).to eq([1, 2, 3])
    end

    it 'sets empty values' do
      setting.compliance_frameworks = [""]

      expect(setting.compliance_frameworks).to eq([])
    end
  end

  describe '#should_apply_user_signup_cap?', feature_category: :onboarding do
    subject { setting.should_apply_user_signup_cap? }

    before do
      allow(Gitlab::CurrentSettings).to receive(:new_user_signups_cap).and_return(new_user_signups_cap)
    end

    context 'when new_user_signups_cap setting is nil' do
      let(:new_user_signups_cap) { nil }

      it { is_expected.to be false }
    end

    context 'when new_user_signups_cap setting is set to any number' do
      let(:new_user_signups_cap) { 10 }

      it { is_expected.to be true }
    end
  end

  describe 'maintenance mode setting', feature_category: :geo_replication do
    it 'defaults to false' do
      expect(subject.maintenance_mode).to be false
    end
  end

  describe "#max_ssh_key_lifetime_from_now", :freeze_time, feature_category: :system_access do
    subject { setting.max_ssh_key_lifetime_from_now }

    let(:days_from_now) { nil }

    before do
      stub_application_setting(max_ssh_key_lifetime: days_from_now)
    end

    context 'when max_ssh_key_lifetime is defined' do
      let(:days_from_now) { 30 }

      it 'is a date time' do
        expect(subject).to be_a Time
      end

      it 'is in the future' do
        expect(subject).to be > Time.zone.now
      end

      it 'is in days_from_now' do
        expect(subject.to_date - Date.today).to eq days_from_now
      end
    end

    context 'when max_ssh_key_lifetime is nil' do
      it 'is nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe 'delayed deletion', feature_category: :subgroups do
    context 'when delayed_group_deletion is set to false' do
      before do
        setting.update!(delayed_group_deletion: false)
      end

      it 'unlocks the delayed_project_removal setting' do
        expect(setting.lock_delayed_project_removal).to be true
      end

      it { is_expected.not_to allow_value(true).for(:delayed_project_removal) }
      it { is_expected.to allow_value(false).for(:delayed_project_removal) }
    end

    context 'when delayed_group_deletion is set to true' do
      before do
        setting.update!(delayed_group_deletion: true)
      end

      it 'locks the delayed_project_removal setting' do
        expect(setting.lock_delayed_project_removal).to be false
      end

      it { is_expected.to allow_value(false).for(:delayed_project_removal) }
      it { is_expected.to allow_value(true).for(:delayed_project_removal) }
    end
  end

  describe '#personal_access_tokens_disabled?', feature_category: :user_management do
    subject { setting.personal_access_tokens_disabled? }

    context 'when disable_personal_access_tokens feature is available' do
      before do
        stub_licensed_features(disable_personal_access_tokens: true)
      end

      context 'when personal access tokens are disabled' do
        before do
          stub_application_setting(disable_personal_access_tokens: true)
        end

        it { is_expected.to eq(true) }
      end

      context 'when personal access tokens are not disabled' do
        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#disable_feed_token', feature_category: :user_management do
    subject { setting.disable_feed_token }

    before do
      setting.update!(disable_feed_token: false)
    end

    context 'when personal access tokens are disabled' do
      before do
        stub_licensed_features(disable_personal_access_tokens: true)
        stub_application_setting(disable_personal_access_tokens: true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when personal access tokens are enabled' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#jitsu_administrator_password', feature_category: :build do
    it 'does not modify password if it is unchanged in the form' do
      setting.jitsu_administrator_password = 'foo'
      setting.jitsu_administrator_password = ApplicationSetting::MASK_PASSWORD

      expect(setting.jitsu_administrator_password).to eq('foo')
    end
  end
end
