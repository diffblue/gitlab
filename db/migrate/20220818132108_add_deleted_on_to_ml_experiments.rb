# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDeletedOnToMlExperiments < Gitlab::Database::Migration[2.0]
  def change
    add_column :ml_experiments, :deleted_on, :datetime_with_timezone, index: true
  end
end
