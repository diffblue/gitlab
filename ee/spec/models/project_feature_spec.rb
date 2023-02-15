# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectFeature do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  describe 'default values' do
    subject { Project.new.project_feature }

    specify { expect(subject.requirements_access_level).to eq(Featurable::ENABLED) }
  end

  describe '#feature_available?' do
    let(:features) { %w(issues wiki builds merge_requests snippets repository pages) }

    context 'when features are enabled only for team members' do
      it "returns true if user is an auditor" do
        user.update_attribute(:auditor, true)

        features.each do |feature|
          project.project_feature.update_attribute("#{feature}_access_level".to_sym, ProjectFeature::PRIVATE)
          expect(project.feature_available?(:issues, user)).to eq(true)
        end
      end
    end
  end

  describe 'project visibility changes' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(project).to receive(:maintaining_elasticsearch?).and_return(true)
    end

    where(:feature, :worker_expected, :associations) do
      'issues'                      | true        | %w[issues notes]
      'wiki'                        | false       | nil
      'builds'                      | false       | nil
      'merge_requests'              | true        | %w[merge_requests notes]
      'repository'                  | true        | %w[notes]
      'snippets'                    | true        | %w[notes]
      'operations'                  | false       | nil
      'security_and_compliance'     | false       | nil
      'pages'                       | false       | nil
    end

    with_them do
      it 're-indexes project and project associations on update' do
        expect(project).to receive(:maintain_elasticsearch_update)

        if worker_expected
          expect(ElasticAssociationIndexerWorker).to receive(:perform_async).with('Project', project.id, associations)
        else
          expect(ElasticAssociationIndexerWorker).not_to receive(:perform_async)
        end

        project.project_feature.update_attribute("#{feature}_access_level".to_sym, ProjectFeature::DISABLED)
      end
    end
  end

  it_behaves_like 'access level validation', ProjectFeature::EE_FEATURES do
    let(:container_features) { project.project_feature }
  end
end
