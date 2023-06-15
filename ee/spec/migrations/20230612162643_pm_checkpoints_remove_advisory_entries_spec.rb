# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe PmCheckpointsRemoveAdvisoryEntries, feature_category: :software_composition_analysis do
  describe '#up' do
    before do
      PackageMetadata::Checkpoint.create!(data_type: Enums::PackageMetadata::DATA_TYPES[:advisories],
        purl_type: 'npm', version_format: 'v1', sequence: 100, chunk: 100)
      PackageMetadata::Checkpoint.create!(data_type: Enums::PackageMetadata::DATA_TYPES[:licenses],
        purl_type: 'npm', version_format: 'v1', sequence: 1, chunk: 1)
      PackageMetadata::Checkpoint.create!(data_type: Enums::PackageMetadata::DATA_TYPES[:licenses],
        purl_type: 'npm', version_format: 'v2', sequence: 50, chunk: 50)
    end

    it 'updates checkpoint mislabeled as advisories' do
      expect { migrate! }
        .to change {
          checkpoint = PackageMetadata::Checkpoint.find_by(
            version_format: 'v1', data_type: Enums::PackageMetadata::DATA_TYPES[:licenses])
          [checkpoint.sequence, checkpoint.chunk]
        }
        .from([1, 1])
        .to([100, 100])
    end

    it 'removes all checkpoints with advisory data_type' do
      expect { migrate! }
        .to change {
          PackageMetadata::Checkpoint.where(
            version_format: 'v1', data_type: Enums::PackageMetadata::DATA_TYPES[:advisories]).size
        }
        .from(1)
        .to(0)
    end

    it 'does not change checkpoints with version_formats other than v1' do
      expect { migrate! }
        .to not_change {
          PackageMetadata::Checkpoint.where(version_format: 'v2').size
        }
    end
  end
end
