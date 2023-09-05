# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resource, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:ci_catalog_resource) { build(:ci_catalog_resource, project: project) }

  describe 'elasticsearch indexing' do
    before do
      allow(project).to receive(:maintaining_elasticsearch?).and_return(true)
    end

    context 'when updating a catalog resource' do
      it 'calls maintain_elasticsearch_update' do
        expect(project).to receive(:maintain_elasticsearch_update)

        ci_catalog_resource.save!
      end
    end
  end
end
