# frozen_string_literal: true

module EE
  module DbCleaner
    extend ::Gitlab::Utils::Override

    override :deletion_except_tables
    def deletion_except_tables
      super << 'licenses'
    end
  end
end
