# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::ProjectFeatureChangesAuditor do
  describe '#execute' do
    let!(:user) { create(:user) }
    let!(:project) { create(:project, :pages_enabled, visibility_level: 0) }
    let(:features) { project.project_feature }
    let(:foo_instance) { described_class.new(user, features, project) }

    before do
      stub_licensed_features(extended_audit_events: true)
    end

    it 'creates an event when any project feature level changes' do
      columns = project.project_feature.attributes.keys.select { |attr| attr.end_with?('level') }

      columns.each do |column|
        previous_value = features.method(column).call
        new_value = if previous_value == ProjectFeature::DISABLED
                      ProjectFeature::ENABLED
                    else
                      ProjectFeature::DISABLED
                    end

        features.update_attribute(column, new_value)
        expect { foo_instance.execute }.to change(AuditEvent, :count).by(1)

        event = AuditEvent.last
        expect(event.details[:from]).to eq ::Gitlab::VisibilityLevel.level_name(previous_value)
        expect(event.details[:to]).to eq ::Gitlab::VisibilityLevel.level_name(new_value)
        expect(event.details[:change]).to eq column
      end
    end
  end
end
