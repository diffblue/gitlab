# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::ResourcesHelper, feature_category: :pipeline_composition do
  let_it_be(:project) { build(:project) }

  describe '#can_view_private_catalog?' do
    subject { helper.can_view_private_catalog?(project) }

    context 'when FF `ci_private_catalog_beta` is disabled' do
      before do
        stub_feature_flags(ci_private_catalog_beta: false)
        stub_licensed_features(ci_namespace_catalog: true)
        allow(helper).to receive(:can_collaborate_with_project?).and_return(true)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when user has no permissions to collaborate' do
      before do
        allow(helper).to receive(:can_collaborate_with_project?).and_return(false)
      end

      context 'when license for namespace catalog is enabled' do
        before do
          stub_licensed_features(ci_namespace_catalog: true)
        end

        it 'returns false' do
          expect(subject).to be false
        end
      end

      context 'when license for namespace catalog is not enabled' do
        before do
          stub_licensed_features(ci_namespace_catalog: false)
        end

        it 'returns false' do
          expect(subject).to be false
        end
      end
    end

    context 'when user has permissions to collaborate' do
      before do
        allow(helper).to receive(:can_collaborate_with_project?).and_return(true)
      end

      context 'when license for namespace catalog is enabled' do
        before do
          stub_licensed_features(ci_namespace_catalog: true)
        end

        it 'returns true' do
          expect(subject).to be true
        end
      end

      context 'when license for namespace catalog is not enabled' do
        before do
          stub_licensed_features(ci_namespace_catalog: false)
        end

        it 'returns false' do
          expect(subject).to be false
        end
      end
    end
  end

  describe '#js_ci_catalog_data' do
    subject { helper.js_ci_catalog_data(project) }

    context 'without the right permissions' do
      before do
        stub_licensed_features(ci_namespace_catalog: false)
      end

      it 'does not return the EE specific attributes' do
        expect(subject.keys).not_to include('ci_catalog_path')
      end
    end

    context 'with the right permissions' do
      before do
        stub_licensed_features(ci_namespace_catalog: true)
        allow(helper).to receive(:can_collaborate_with_project?).and_return(true)
      end

      it 'returns both the super and EE specific properties' do
        expect(subject).to eq(
          "ci_catalog_path" => "/#{project.full_path}/-/ci/catalog/resources"
        )
      end
    end
  end
end
