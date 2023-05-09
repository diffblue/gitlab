# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::ResourcesHelper, feature_category: :pipeline_composition do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { create_default(:project) }
  let_it_be(:user) { create_default(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#can_view_namespace_catalog?' do
    subject { helper.can_view_namespace_catalog?(project) }

    context 'when FF `ci_namespace_catalog_experimental` is disabled' do
      before do
        stub_feature_flags(ci_namespace_catalog_experimental: false)
        stub_licensed_features(ci_namespace_catalog: true)

        project.add_owner(user)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when user has no permissions to collaborate' do
      before do
        stub_licensed_features(ci_namespace_catalog: true)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when user has permissions to collaborate' do
      before do
        project.add_owner(user)
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

        project.add_owner(user)
      end

      it 'returns both the super and EE specific properties' do
        expect(subject).to eq(
          "ci_catalog_path" => "/#{project.full_path}/-/ci/catalog/resources",
          "project_full_path" => project.full_path
        )
      end
    end
  end
end
