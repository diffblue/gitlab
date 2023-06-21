# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::Levels::Group, feature_category: :audit_events do
  describe '#apply' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:subproject) { create(:project, namespace: subgroup) }

    let_it_be(:project_audit_event) { create(:project_audit_event, entity_id: project.id) }
    let_it_be(:subproject_audit_event) { create(:project_audit_event, entity_id: subproject.id) }
    let_it_be(:group_audit_event) { create(:group_audit_event, entity_id: group.id) }

    subject { described_class.new(group: group).apply }

    it 'finds all group events' do
      expect(subject).to contain_exactly(group_audit_event)
    end
  end
end
