# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuableExportCsvWorker, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, creator: user) }

  let(:params) { {} }

  subject { described_class.new.perform(issuable_type, user.id, project.id, params) }

  context 'when issuable type is :requirement' do
    let(:issuable_type) { 'requirement' }

    it 'emails a CSV' do
      expect { subject }.to change(ActionMailer::Base.deliveries, :size).by(1)
    end

    it 'calls the Requirements export service' do
      expect(RequirementsManagement::ExportCsvService)
        .to receive(:new).with(anything, project, []).once.and_call_original

      subject
    end

    it 'calls the Work Items finder' do
      expect(WorkItems::WorkItemsFinder).to receive(:new)
        .with(user, { "project_id" => project.id, "issue_types" => [:requirement] })
        .once
        .and_call_original

      subject
    end

    context 'with selected fields are present' do
      let(:selected_fields) { %w(Title Description State') }

      it 'calls the Requirements export service with selected fields' do
        params[:selected_fields] = selected_fields

        expect(RequirementsManagement::ExportCsvService)
          .to receive(:new).with(anything, project, selected_fields).once.and_call_original

        subject
      end
    end

    context 'with record not found' do
      let(:logger) { described_class.new.send(:logger) }

      it 'an error is logged if user not found' do
        message = "Failed to export CSV (current_user_id:#{non_existing_record_id}, "\
          "project_id:#{project.id}): Couldn't find User with 'id'=#{non_existing_record_id}"

        expect(logger).to receive(:error).with(message).once

        described_class.new.perform(issuable_type, non_existing_record_id, project.id, params)
      end

      it 'an error is logged if project not found' do
        message = "Failed to export CSV (current_user_id:#{user.id}, "\
          "project_id:#{non_existing_record_id}): Couldn't find Project with 'id'=#{non_existing_record_id}"

        expect(logger).to receive(:error).with(message).once

        described_class.new.perform(issuable_type, user.id, non_existing_record_id, params)
      end
    end
  end

  context 'when issuable type is :issue' do
    let(:issuable_type) { :issue }

    context 'when issuable type is :issue' do
      it 'calls Issues::ExportCsvService with specific parameters' do
        expect(Issues::ExportCsvService)
          .to receive(:new).with(anything, project, user).once.and_call_original

        subject
      end
    end
  end

  context 'when issuable type is not :requirement' do
    context 'with a valid type' do
      let(:issuable_type) { :merge_request }

      it 'does not raise an exception' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with an invalid type' do
      let(:issuable_type) { :test }

      it 'raises an exception with expected message' do
        expect { subject }.to raise_error(
          ArgumentError,
          'Type parameter must be :issue, :merge_request, :work_item or :requirement, it was test'
        )
      end
    end
  end
end
