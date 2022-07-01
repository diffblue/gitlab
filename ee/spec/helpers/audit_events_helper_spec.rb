# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEventsHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#admin_audit_event_tokens' do
    it 'returns the available tokens' do
      available_tokens = [
        { type: AuditEventsHelper::FILTER_TOKEN_TYPES[:user] },
        { type: AuditEventsHelper::FILTER_TOKEN_TYPES[:group] },
        { type: AuditEventsHelper::FILTER_TOKEN_TYPES[:project] }
      ]
      expect(admin_audit_event_tokens).to eq(available_tokens)
    end
  end

  describe '#group_audit_event_tokens' do
    let(:group_id) { 1 }

    it 'returns the available tokens' do
      available_tokens = [{ type: AuditEventsHelper::FILTER_TOKEN_TYPES[:member], group_id: group_id }]
      expect(group_audit_event_tokens(group_id)).to eq(available_tokens)
    end
  end

  describe '#project_audit_event_tokens' do
    let(:project_path) { '/abc' }

    it 'returns the available tokens' do
      available_tokens = [{ type: AuditEventsHelper::FILTER_TOKEN_TYPES[:member], project_path: project_path }]
      expect(project_audit_event_tokens(project_path)).to eq(available_tokens)
    end
  end

  describe '#export_url' do
    subject { export_url }

    it { is_expected.to eq('http://test.host/admin/audit_log_reports.csv') }
  end

  describe '#show_streams_for_group?' do
    let_it_be(:group) { build(:group) }
    let_it_be(:subgroup) { build(:group, :nested) }
    let_it_be(:current_user) { build(:user) }

    it 'returns false if the group is a subgroup' do
      expect(helper.show_streams_for_group?(subgroup)).to eq(false)
    end

    where(has_permission?: [true, false])

    with_them do
      before do
        allow(helper).to receive(:current_user).and_return(current_user)
        allow(helper)
          .to receive(:can?)
          .with(current_user, :admin_external_audit_events, group)
          .and_return(has_permission?)
      end

      it "returns #{params[:has_permission?]}" do
        expect(helper.show_streams_for_group?(group)).to eq(has_permission?)
      end
    end
  end

  describe '#show_streams_headers?' do
    let_it_be(:group) { build(:group) }
    let_it_be(:subgroup) { build(:group, :nested) }
    let_it_be(:current_user) { build(:user) }

    it 'returns false if the group is a subgroup' do
      expect(helper.show_streams_for_group?(subgroup)).to eq(false)
    end

    where(:has_permission?, :feature_enabled?, :result) do
      false | false | false
      true | false | false
      false | true | false
      true | true | true
    end

    with_them do
      before do
        allow(helper).to receive(:current_user).and_return(current_user)
        allow(helper)
          .to receive(:can?)
                .with(current_user, :admin_external_audit_events, group)
                .and_return(has_permission?)
        stub_feature_flags(custom_headers_streaming_audit_events_ui: feature_enabled?)
      end

      it "returns #{params[:result]}" do
        expect(helper.show_streams_headers?(group)).to eq(result)
      end
    end
  end
end
