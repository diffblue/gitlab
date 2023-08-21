# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Max Limits Module', feature_category: :team_planning do
  let(:clazz) do
    Class.new do
      include EE::Boards::Lists::MaxLimits

      attr_reader :params

      def initialize(params)
        @params = params
      end
    end
  end

  describe 'max limits query methods' do
    where(
      :params,
      :expected_max_issue_count?,
      :expected_max_issue_weight?,
      :expected_max_issue_count_by_params,
      :expected_max_issue_weight_by_params,
      :expected_list_attributes
    ) do
      [
        [{ max_issue_count: 0 }, true, false, 0, 0, { max_issue_count: 0 }],
        [{ max_issue_count: nil }, false, false, 0, 0, {}],
        [{ max_issue_count: -1 }, true, false, -1, 0, { max_issue_count: -1 }],
        [{ max_issue_count: 1 }, true, false, 1, 0, { max_issue_count: 1 }],
        [{ max_issue_count: '1' }, true, false, 1, 0, { max_issue_count: 1 }],

        [{ max_issue_weight: 0 }, false, true, 0, 0, { max_issue_weight: 0 }],
        [{ max_issue_weight: nil }, false, false, 0, 0, {}],
        [{ max_issue_weight: -1 }, false, true, 0, -1, { max_issue_weight: -1 }],
        [{ max_issue_weight: 1 }, false, true, 0, 1, { max_issue_weight: 1 }],
        [{ max_issue_weight: '1' }, false, true, 0, 1, { max_issue_weight: 1 }],

        [{ max_issue_count: 1, max_issue_weight: 1 }, true, true, 1, 1, { max_issue_count: 1, max_issue_weight: 1 }],

        [{ max_issue_count: '1', max_issue_weight: 1 }, true, true, 1, 1, { max_issue_count: 1, max_issue_weight: 1 }],
        [{ max_issue_count: 1, max_issue_weight: '1' }, true, true, 1, 1, { max_issue_count: 1, max_issue_weight: 1 }],

        [{ max_issue_count: nil, max_issue_weight: '1' }, false, true, 0, 1, { max_issue_weight: 1 }],

        [{ max_issue_count: 1, max_issue_weight: 2 }, true, true, 1, 2, { max_issue_count: 1, max_issue_weight: 2 }],

        [{ max_issue_count: 0, max_issue_weight: 3 }, true, true, 0, 3, { max_issue_count: 0, max_issue_weight: 3 }],
        [{ max_issue_count: nil, max_issue_weight: 3 }, false, true, 0, 3, { max_issue_weight: 3 }],
        [{ max_issue_count: -1, max_issue_weight: 3 }, true, true, -1, 3, { max_issue_count: -1, max_issue_weight: 3 }],

        [{ max_issue_count: nil, max_issue_weight: nil }, false, false, 0, 0, {}],

        [{ max_issue_count: -1, max_issue_weight: -1 }, true, true, -1, -1, { max_issue_count: -1, max_issue_weight: -1 }],

        [{ max_issue_count: 1, max_issue_weight: 'hello' }, true, true, 1, 0, { max_issue_count: 1, max_issue_weight: 0 }],

        [{ max_issue_count: '2', max_issue_weight: '9' }, true, true, 2, 9, { max_issue_count: 2, max_issue_weight: 9 }],

        [{ max_issue_weight: '9' }, false, true, 0, 9, { max_issue_weight: 9 }],

        [{ max_issue_count: 'hello1', max_issue_weight: 'hello2' }, true, true, 0, 0, { max_issue_count: 0, max_issue_weight: 0 }]
      ]
    end

    with_them do
      it 'returns the expected values' do
        instance = clazz.new(params)

        expect(instance.max_issue_count?).to eq(expected_max_issue_count?)
        expect(instance.max_issue_weight?).to eq(expected_max_issue_weight?)

        expect(instance.max_issue_count_by_params).to eq(expected_max_issue_count_by_params)
        expect(instance.max_issue_weight_by_params).to eq(expected_max_issue_weight_by_params)

        expect(instance.list_max_limit_attributes_by_params).to eq(expected_list_attributes)
      end
    end
  end
end
