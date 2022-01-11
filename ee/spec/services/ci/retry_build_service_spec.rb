# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::RetryBuildService do
  let_it_be(:user) { create(:user) }

  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }

  subject(:service) { described_class.new(project, user) }

  before do
    stub_not_protect_default_branch

    project.add_developer(user)
  end

  it_behaves_like 'restricts access to protected environments'

  describe '#clone!' do
    context 'when user has ability to execute build' do
      let_it_be(:namespace) { create(:namespace) }

      let(:project) { create(:project, namespace: namespace, creator: user) }

      let(:new_build) do
        travel_to(1.second.from_now) do
          service.clone!(build)
        end
      end

      context 'dast' do
        let(:dast_site_profile) { create(:dast_site_profile, project: project) }
        let(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

        before do
          build.update!(dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile)
        end

        it 'clones the profile associations', :aggregate_failures do
          ::Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.allow_cross_database_modification_within_transaction(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/350051') do
            expect(new_build.dast_site_profile).to eq(dast_site_profile)
            expect(new_build.dast_scanner_profile).to eq(dast_scanner_profile)
          end
        end
      end

      context 'when build has secrets' do
        let(:secrets) do
          {
            'DATABASE_PASSWORD' => {
              'vault' => {
                'engine' => { 'name' => 'kv-v2', 'path' => 'kv-v2' },
                'path' => 'production/db',
                'field' => 'password'
              }
            }
          }
        end

        before do
          build.update!(secrets: secrets)
        end

        it 'clones secrets' do
          expect(new_build.secrets).to eq(secrets)
        end
      end

      describe 'credit card requirement' do
        shared_examples 'creates a retried build' do
          it 'creates a retried build' do
            build

            expect { new_build }.to change { Ci::Build.count }.by(1)

            expect(new_build.name).to eq build.name
            expect(new_build).to be_latest
            expect(build).to be_retried
            expect(build).to be_processed
          end
        end

        context 'when credit card is required', :saas do
          let_it_be(:ultimate_plan) { create(:ultimate_plan) }
          let_it_be(:plan_limits) { create(:plan_limits, plan: ultimate_plan) }

          before do
            create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan)
          end

          context 'when project is on free plan' do
            before do
              namespace.gitlab_subscription.update!(hosted_plan: create(:free_plan))
              user.created_at = ::Users::CreditCardValidation::RELEASE_DAY
            end

            context 'when user has credit card' do
              before do
                allow(user).to receive(:credit_card_validated_at).and_return(Time.current)
              end

              it_behaves_like 'creates a retried build'
            end

            context 'when user does not have credit card' do
              it 'raises an exception', :aggregate_failures do
                expect { new_build }.to raise_error Gitlab::Access::AccessDeniedError
              end

              context 'when feature flag is disabled' do
                before do
                  stub_feature_flags(ci_require_credit_card_on_free_plan: false)
                end

                it_behaves_like 'creates a retried build'
              end
            end
          end
        end

        context 'when credit card is not required' do
          it_behaves_like 'creates a retried build'
        end
      end
    end
  end

  describe '#execute' do
    let(:new_build) do
      travel_to(1.second.from_now) do
        service.execute(build)
      end
    end

    context 'when the CI quota is exceeded' do
      let_it_be(:namespace) { create(:namespace, :with_used_build_minutes_limit) }
      let_it_be(:project) { create(:project, namespace: namespace, creator: user) }

      context 'when there are no runners available' do
        it { expect(new_build).not_to be_failed }
      end

      context 'when shared runners are available' do
        let_it_be(:runner) { create(:ci_runner, :instance, :online) }

        it 'fails the build' do
          expect(new_build).to be_failed
          expect(new_build.failure_reason).to eq('ci_quota_exceeded')
        end

        context 'with private runners' do
          let_it_be(:private_runner) do
            create(:ci_runner, :project, :online, projects: [project])
          end

          it { expect(new_build).not_to be_failed }
        end
      end
    end
  end
end
