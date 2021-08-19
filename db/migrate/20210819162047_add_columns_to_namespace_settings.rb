# frozen_string_literal: true

class AddColumnsToNamespaceSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :namespace_settings, :setup_for_company, :boolean
    add_column :namespace_settings, :jobs_to_be_done, :smallint
  end
end
