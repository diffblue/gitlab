# frozen_string_literal: true

class CreateEpicIndex < Elastic::Migration
  include Elastic::MigrationCreateIndex

  retry_on_failure

  def document_type
    :epic
  end

  def target_class
    Epic
  end
end
