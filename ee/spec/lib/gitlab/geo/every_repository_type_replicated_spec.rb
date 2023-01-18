# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every GitLab repository type', feature_category: :geo_replication do
  context 'for Geo replication' do
    # rubocop:disable Layout/LineLength
    it 'has Geo self-service framework support' do
      missing_data_types = repository_types - replicated_types - types_to_ignore

      expect(missing_data_types)
        .to be_empty, "New repository type detected: #{missing_data_types.to_a.inspect}. " \
                      "Additional work may be needed to add Geo support. Geo support is " \
                      "a part of the definition of done, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97172. " \
                      "Please visit https://docs.gitlab.com/ee/development/geo.html#ensuring-a-new-feature-has-geo-support " \
                      "for details. If work is not needed, add the type to to types_to_ignore and get a review " \
                      "by a Geo team member."
    end
    # rubocop:enable Layout/LineLength

    def repository_replicators
      Gitlab::Geo::REPLICATOR_CLASSES.select { |replicator| replicator.data_type == 'repository' }
    end

    def replicated_types
      repository_replicators.map do |replicator|
        replicator.name.demodulize.sub('RepositoryReplicator', '').underscore
      end
    end

    def repository_types
      Gitlab::GlRepository::TYPES.keys
    end

    def types_to_ignore
      [
        "project", # implemented, legacy Geo framework
        "wiki", # implemented, legacy Geo framework
        "design" # implemented, legacy Geo framework
      ]
    end
  end
end
