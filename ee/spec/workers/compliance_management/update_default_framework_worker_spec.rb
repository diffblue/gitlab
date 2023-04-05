# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::UpdateDefaultFrameworkWorker, feature_category: :compliance_management do
  let_it_be(:worker) { described_class.new }
  let_it_be(:user) { create(:user) }
  let_it_be(:admin_bot) { create(:user, :admin_bot, :admin) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:framework) { create(:compliance_framework, namespace: group, name: 'GDPR') }

  let(:job_args) { [user.id, project.id, framework.id] }

  describe "#perform" do
    before do
      group.add_developer(user)
      group.add_owner(admin_bot)
      stub_licensed_features(custom_compliance_frameworks: true, compliance_framework: true)
    end

    it 'invokes Projects::UpdateService' do
      params = [project, admin_bot, { compliance_framework_setting_attributes: { framework: framework.id } }]

      expect_next_instance_of(::Projects::UpdateService, *params) do |project_update_service|
        expect(project_update_service).to receive(:execute).and_call_original
      end

      worker.perform(*job_args)
    end

    it 'updates the compliance framework for the project' do
      expect(project.compliance_management_framework).to eq(nil)

      worker.perform(*job_args)

      expect(project.reload.compliance_management_framework).to eq(framework)
    end

    it_behaves_like 'an idempotent worker'

    it 'rescues and logs the exception if project does not exist' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(instance_of(ActiveRecord::RecordNotFound))

      worker.perform(user.id, non_existing_record_id, framework.id)
    end
  end
end
