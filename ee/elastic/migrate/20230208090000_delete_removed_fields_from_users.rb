# frozen_string_literal: true

class DeleteRemovedFieldsFromUsers < Elastic::Migration
  include Elastic::MigrationRemoveFieldsHelper

  batched!
  throttle_delay 1.minute

  private

  def index_name
    User.__elasticsearch__.index_name
  end

  def document_type
    'user'
  end

  def fields_to_remove
    %w[two_factor_enabled has_projects]
  end
end
