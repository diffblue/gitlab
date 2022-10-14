# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectStatistics do
  let_it_be(:project) { create :project }
  let_it_be(:statistics) { project.statistics }
  let_it_be(:other_sizes) { 3 }
  let_it_be(:uploads_size) { 5 }

  describe '#update_storage_size' do
    context 'when should_check_namespace_plan? returns true' do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      it "sums the relevant storage counters without uploads_size" do
        statistics.update!(
          repository_size: other_sizes,
          wiki_size: other_sizes,
          lfs_objects_size: other_sizes,
          snippets_size: other_sizes,
          pipeline_artifacts_size: other_sizes,
          build_artifacts_size: other_sizes,
          packages_size: other_sizes,
          uploads_size: uploads_size
        )

        statistics.reload

        expect(statistics.storage_size).to eq(other_sizes * 7)
      end
    end

    context 'when should_check_namespace_plan? returns false' do
      it "sums the relevant storage counters along with uploads_size" do
        statistics.update!(
          repository_size: other_sizes,
          wiki_size: other_sizes,
          lfs_objects_size: other_sizes,
          snippets_size: other_sizes,
          pipeline_artifacts_size: other_sizes,
          build_artifacts_size: other_sizes,
          packages_size: other_sizes,
          uploads_size: uploads_size
        )

        statistics.reload

        expect(statistics.storage_size).to eq(other_sizes * 7 + uploads_size)
      end
    end
  end
end
