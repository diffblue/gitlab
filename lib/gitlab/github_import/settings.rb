# frozen_string_literal: true

module Gitlab
  module GithubImport
    class Settings
      OPTIONAL_STAGES = {
        single_endpoint_issue_events_import: {
          label: 'Import Issue/MR events',
          details: <<-TEXT.split("\n").map(&:strip).join(' ')
            Such as opened/closed, renamed, labeled/unlabeled etc.
            Extra time of importing events commonly depends on how many issues/mr-s your project has.
          TEXT
        },
        single_endpoint_notes_import: {
          label: 'Thorough Notes import',
          details: <<-TEXT.split("\n").map(&:strip).join(' ')
            When GitHub Importer runs on extremely large projects (e.g. nodejs/node repository)
            not all notes & diff notes are being imported.
          TEXT
        },
        attachments_import: {
          label: 'Import Markdown attachments',
          details: <<-TEXT.split("\n").map(&:strip).join(' ')
            Repository's comments, release posts, MR-s/Issues description could include some images,
            text or binary attachments. The text of mentioned entities contains markdown with links to
            those files on GitHub. If you decide not to import them - all of the links will become broken
            with some time if you remove repository from GitHub.
          TEXT
        }
      }.freeze

      def self.stages_array
        OPTIONAL_STAGES.map do |stage_name, data|
          {
            name: stage_name.to_s,
            label: s_(format("GitHubImport|%{text}", text: data[:label])),
            details: s_(format("GitHubImport|%{text}", text: data[:details]))
          }
        end
      end

      def initialize(project)
        @project = project
      end

      def write(user_settings)
        user_settings = user_settings.to_h.with_indifferent_access

        optional_stages = fetch_stages_from_params(user_settings)
        import_data = project.create_or_update_import_data(data: { optional_stages: optional_stages })
        import_data.save!
      end

      def enabled?(stage_name)
        project.import_data&.data&.dig('optional_stages', stage_name.to_s) || false
      end

      def disabled?(stage_name)
        !enabled?(stage_name)
      end

      private

      attr_reader :project

      def fetch_stages_from_params(user_settings)
        OPTIONAL_STAGES.keys.to_h do |stage_name|
          enabled = Gitlab::Utils.to_boolean(user_settings[stage_name], default: false)
          [stage_name, enabled]
        end
      end
    end
  end
end
