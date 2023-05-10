# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::Trials::CreateService, feature_category: :purchase do
  let_it_be(:user, reload: true) { create(:user) }
  let(:step) { 'lead' }

  describe '#execute' do
    let(:trial_params) { {} }
    let(:trial_user_params) do
      { trial_user: lead_params(user) }
    end

    subject(:execute) do
      described_class.new(step: step, lead_params: lead_params(user), trial_params: trial_params, user: user).execute
    end

    context 'when on the lead step' do
      context 'when lead creation is successful' do
        context 'when there is only one trial eligible namespace' do
          let_it_be(:group) { create(:group, name: 'gitlab').tap { |record| record.add_owner(user) } }

          it 'starts a trial and tracks the event' do
            expect_create_lead_success(trial_user_params)
            expect_apply_trial_success(user, group, extra_params: existing_group_attrs(group))

            expect(execute).to be_success
            expect(execute.payload).to eq({ namespace: group })
            expect_snowplow_event(category: described_class.name, action: 'create_trial', namespace: group, user: user)
          end

          it 'errors when trying to apply a trial' do
            expect_create_lead_success(trial_user_params)
            expect_apply_trial_fail(user, group, extra_params: existing_group_attrs(group))

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
            expect(execute.reason).to eq(:no_single_namespace)
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
            expect(execute.reason).to eq(:no_single_namespace)
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

    context 'when on trial step' do
      let(:step) { 'trial' }

      context 'in the existing namespace flow' do
        let_it_be(:group) { create(:group, name: 'gitlab').tap { |record| record.add_owner(user) } }
        let(:namespace_id) { group.id.to_s }
        let(:extra_params) { { trial_entity: '_entity_' } }
        let(:trial_params) { { namespace_id: namespace_id }.merge(extra_params) }

        context 'when trial creation is successful' do
          it 'starts a trial' do
            expect_apply_trial_success(user, group, extra_params: extra_params.merge(existing_group_attrs(group)))

            expect(execute).to be_success
            expect(execute.payload).to eq({ namespace: group })
          end

          context 'when a valid namespace_id of non zero and new_group_name is present' do
            # This can *currently* happen on validation failure for creating
            # a new namespace.
            let(:trial_params) { { new_group_name: 'gitlab', namespace_id: group.id, trial_entity: '_entity_' } }

            it 'starts a trial using the namespace_id' do
              expect_apply_trial_success(user, group, extra_params: extra_params.merge(existing_group_attrs(group)))

              expect(execute).to be_success
              expect(execute.payload).to eq({ namespace: group })
            end
          end
        end

        context 'when trial creation is not successful' do
          it 'returns an error indicating trial failed' do
            expect_apply_trial_fail(user, group, extra_params: extra_params.merge(existing_group_attrs(group)))

            expect(execute).to be_error
            expect(execute.reason).to eq(:trial_failed)
          end
        end

        context 'when the user does not have access to the namespace' do
          let(:namespace_id) { create(:group).id.to_s }

          it 'returns an error of not_found and does not apply a trial' do
            expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

            expect(execute).to be_error
            expect(execute.reason).to eq(:not_found)
          end
        end

        context 'when the user is not an owner of the namespace' do
          let(:namespace_id) { create(:group).tap { |record| record.add_developer(user) }.id.to_s }

          it 'returns an error of not_found and does not apply a trial' do
            expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

            expect(execute).to be_error
            expect(execute.reason).to eq(:not_found)
          end
        end

        context 'when there is no namespace with the namespace_id' do
          let(:namespace_id) { non_existing_record_id.to_s }

          it 'returns an error of not_found and does not apply a trial' do
            expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

            expect(execute).to be_error
            expect(execute.reason).to eq(:not_found)
          end
        end
      end

      context 'in the create group flow' do
        let(:extra_params) { { trial_entity: '_entity_' } }
        let(:trial_params) { { new_group_name: 'gitlab', namespace_id: '0' }.merge(extra_params) }

        context 'when group is successfully created' do
          context 'when trial creation is successful' do
            it 'return success with the namespace' do
              expect_next_instance_of(GitlabSubscriptions::Trials::ApplyTrialService) do |instance|
                expect(instance).to receive(:execute).and_return(ServiceResponse.success)
              end

              expect { execute }.to change { Group.count }.by(1)

              expect(execute).to be_success
              expect(execute.payload).to eq({ namespace: Group.last })
            end
          end

          context 'when trial creation fails' do
            it 'returns an error indicating trial failed' do
              stub_apply_trial(
                user, namespace_id: anything, success: false, extra_params: extra_params.merge(new_group_attrs)
              )

              expect { execute }.to change { Group.count }.by(1)

              expect(execute).to be_error
              expect(execute.payload).to eq({ namespace_id: Group.last.id })
            end
          end

          context 'when group name needs sanitized' do
            it 'return success with the namespace path sanitized for duplication' do
              create(:group, name: 'gitlab')

              stub_apply_trial(
                user, namespace_id: anything, success: true,
                extra_params: extra_params.merge(new_group_attrs(path: 'gitlab1'))
              )

              expect { execute }.to change { Group.count }.by(1)

              expect(execute).to be_success
              expect(execute.payload[:namespace].path).to eq('gitlab1')
            end
          end
        end

        context 'when user is not allowed to create groups' do
          before do
            user.can_create_group = false
          end

          it 'returns not_found' do
            expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

            expect { execute }.not_to change { Group.count }
            expect(execute).to be_error
            expect(execute.reason).to eq(:not_found)
          end
        end

        context 'when group creation had an error' do
          let(:trial_params) { { new_group_name: ' _invalid_ ', namespace_id: '0' } }

          it 'returns not_found' do
            expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

            expect { execute }.not_to change { Group.count }
            expect(execute).to be_error
            expect(execute.reason).to eq(:namespace_create_failed)
            expect(execute.message.to_sentence).to match(/^Group URL must not start or end with a special character/)
            expect(execute.payload[:namespace_id]).to eq('0')
          end
        end
      end

      context 'when namespace_id is 0 without a new_group_name' do
        let(:trial_params) { { namespace_id: '0' } }

        it 'returns an error of not_found and does not apply a trial' do
          expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

          expect(execute).to be_error
          expect(execute.reason).to eq(:not_found)
        end
      end

      context 'when neither new group name or namespace_id is present' do
        let(:trial_params) { {} }

        it 'returns an error of not_found and does not apply a trial' do
          expect(GitlabSubscriptions::Trials::ApplyTrialService).not_to receive(:new)

          expect(execute).to be_error
          expect(execute.reason).to eq(:not_found)
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

  def expect_apply_trial_success(user, group, extra_params: {})
    stub_apply_trial(user, namespace_id: group.id, success: true, extra_params: extra_params)
  end

  def expect_apply_trial_fail(user, group, extra_params: {})
    stub_apply_trial(user, namespace_id: group.id, success: false, extra_params: extra_params)
  end

  def existing_group_attrs(group)
    { namespace: group.slice(:id, :name, :path, :kind, :trial_ends_on) }
  end

  def new_group_attrs(path: 'gitlab')
    {
      namespace: {
        id: anything,
        path: path,
        name: 'gitlab',
        kind: 'group',
        trial_ends_on: nil
      }
    }
  end

  def stub_apply_trial(user, namespace_id: anything, success: true, extra_params: {})
    trial_user_params = {
      namespace_id: namespace_id,
      gitlab_com_trial: true,
      sync_to_gl: true
    }.merge(extra_params)

    service_params = {
      trial_user_information: trial_user_params,
      uid: user.id
    }

    trial_success = if success
                      ServiceResponse.success
                    else
                      ServiceResponse.error(message: '_trial_fail_')
                    end

    expect_next_instance_of(GitlabSubscriptions::Trials::ApplyTrialService, service_params) do |instance|
      expect(instance).to receive(:execute).and_return(trial_success)
    end
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
