# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::Trials::CreateService, feature_category: :purchase do
  let_it_be(:user) { create(:user) }
  let(:step) { 'lead' }

  describe '#execute' do
    let(:trial_user_params) do
      { trial_user: lead_params(user) }
    end

    subject(:execute) do
      described_class.new(step: step, lead_params: lead_params(user), trial_params: {}, user: user).execute
    end

    context 'when on the lead step' do
      context 'when lead creation is successful' do
        context 'when there is only one trial eligible namespace' do
          let_it_be(:group) { create(:group, name: 'gitlab').tap { |record| record.add_owner(user) } }

          it 'starts a trial and tracks the event' do
            expect_create_lead_success(trial_user_params)
            expect_apply_trial_success(user, group)

            expect(execute).to be_success
            expect(execute.payload).to eq({ namespace: group })
            expect_snowplow_event(category: described_class.name, action: 'create_trial', namespace: group, user: user)
          end

          it 'errors when trying to apply a trial' do
            expect_create_lead_success(trial_user_params)
            expect_apply_trial_fail(user, group)

            expect(execute).to be_error
            expect(execute.reason).to eq(:trial_failed)
            expect(execute.payload).to eq({ namespace_id: group.id })
            expect_no_snowplow_event(
              category: described_class.name, action: 'create_trial', namespace: group, user: user
            )
          end
        end

        context 'when there are no trial eligible namespaces' do
          it 'does not create a trial and returns that there is no namespace' do
            expect_create_lead_success(trial_user_params)
            expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

            expect(execute).to be_error
            expect(execute.reason).to eq(:no_namespace)
          end
        end

        context 'when there are multiple trial eligible namespaces' do
          let_it_be(:group) do
            create(:group).tap { |record| record.add_owner(user) }
            create(:group, name: 'gitlab').tap { |record| record.add_owner(user) }
          end

          it 'does not create a trial and returns that there is no namespace' do
            expect_create_lead_success(trial_user_params)
            expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

            expect(execute).to be_error
            expect(execute.reason).to eq(:no_namespace)
          end
        end
      end

      context 'when lead creation fails' do
        it 'returns and error indicating lead failed' do
          expect_create_lead_fail(trial_user_params)
          expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

          expect(execute).to be_error
          expect(execute.reason).to eq(:lead_failed)
        end
      end
    end

    context 'with an unknown step' do
      let(:step) { 'bogus' }

      it 'returns an error of not_found and does not create lead or apply a trial' do
        expect(GitlabSubscriptions::CreateLeadService).not_to receive(:new)
        expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

        expect(execute).to be_error
        expect(execute.reason).to eq(:not_found)
      end
    end

    context 'with no step' do
      let(:step) { nil }

      it 'returns an error of not_found and does not create lead or apply a trial' do
        expect(GitlabSubscriptions::CreateLeadService).not_to receive(:new)
        expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

        expect(execute).to be_error
        expect(execute.reason).to eq(:not_found)
      end
    end
  end

  def expect_create_lead(trial_user_params, success: true)
    response = if success
                 ServiceResponse.success
               else
                 ServiceResponse.error(message: '_lead_fail_')
               end

    expect_next_instance_of(GitlabSubscriptions::CreateLeadService) do |instance|
      expect(instance).to receive(:execute).with(trial_user_params).and_return(response)
    end
  end
  alias_method :expect_create_lead_success, :expect_create_lead

  def expect_create_lead_fail(trial_user_params)
    expect_create_lead(trial_user_params, success: false)
  end

  def expect_apply_trial(user, group, success: true)
    response = if success
                 ServiceResponse.success
               else
                 ServiceResponse.error(message: '_trial_fail_')
               end

    expect_next_instance_of(GitlabSubscriptions::Trials::ApplyTrialService, trial_params(user, group)) do |instance|
      expect(instance).to receive(:execute).and_return(response)
    end
  end
  alias_method :expect_apply_trial_success, :expect_apply_trial

  def expect_apply_trial_fail(user, group)
    expect_apply_trial(user, group, success: false)
  end

  def trial_params(user, group)
    trial_user_params = {
      namespace_id: group.id,
      gitlab_com_trial: true,
      sync_to_gl: true,
      namespace: group.slice(:id, :name, :path, :kind, :trial_ends_on)
    }

    {
      trial_user_information: trial_user_params,
      uid: user.id
    }
  end

  def lead_params(user)
    {
      company_name: 'GitLab',
      company_size: '1-99',
      first_name: user.first_name,
      last_name: user.last_name,
      phone_number: '+1 23 456-78-90',
      country: 'US',
      work_email: user.email,
      uid: user.id,
      setup_for_company: user.setup_for_company,
      skip_email_confirmation: true,
      gitlab_com_trial: true,
      provider: 'gitlab',
      newsletter_segment: user.email_opted_in,
      state: 'CA'
    }
  end
end
