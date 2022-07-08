# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ingestion::BulkInsertableTask do
  describe '.unique_by' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:identifier_1) { create(:vulnerabilities_identifier) }
    let(:identifier_2) { create(:vulnerabilities_identifier) }
    let(:finding) { create(:vulnerabilities_finding) }
    let(:identifier_ids) { [identifier_1.id, identifier_1.id, identifier_2.id] }
    let(:finding_map) { create(:finding_map, finding: finding, identifier_ids: identifier_ids) }
    let(:task) do
      Class.new(Security::Ingestion::AbstractTask) do
        include Gitlab::Ingestion::BulkInsertableTask

        self.model = Class.new(ApplicationRecord) { self.table_name = 'vulnerability_occurrence_identifiers' }
        self.unique_by = %i[occurrence_id identifier_id].freeze

        def attributes
          finding_maps.flat_map do |finding_map|
            finding_map.identifier_ids.map do |identifier_id|
              {
                occurrence_id: finding_map.finding_id,
                identifier_id: identifier_id
              }
            end
          end
        end
      end
    end

    let(:service_object) { task.new(pipeline, [finding_map]) }

    it 'does not try to create/update duplicate records' do
      expect { service_object.execute }.to change { finding.identifiers.count }.by(2)
    end
  end
end
