# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FilterableByTestReports do
  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = 'issues'

      include FilterableByTestReports
    end
  end

  describe '.test_reports_join_column' do
    it 'raises error if method is not implemented on container class' do
      expect { test_class.with_last_test_report_state('opened') }
        .to raise_error(NotImplementedError)
    end
  end
end
