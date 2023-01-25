import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import ColumnChart from 'ee/analytics/contribution_analytics/components/column_chart.vue';
import PushesChart from 'ee/analytics/contribution_analytics/components/pushes_chart.vue';
import { MOCK_PUSHES } from '../mock_data';

describe('Contribution Analytics Pushes Chart', () => {
  let wrapper;

  const findDescription = () => wrapper.findByTestId('description').text();
  const findChart = () => wrapper.findComponent(ColumnChart);

  const createWrapper = (pushes) => {
    wrapper = mountExtended(PushesChart, {
      propsData: {
        pushes,
      },
      stubs: {
        ColumnChart: stubComponent(ColumnChart, {
          props: ['chartData'],
        }),
      },
    });
  };

  it('renders the empty description when there is no table data', () => {
    createWrapper([]);
    expect(findDescription()).toBe(wrapper.vm.$options.i18n.emptyDescription);
  });

  it('renders the description based on the table data', () => {
    createWrapper(MOCK_PUSHES);
    expect(findDescription()).toBe('55 pushes by 3 contributors.');
  });

  it('sorts the chart by push count in descending order', () => {
    createWrapper(MOCK_PUSHES);
    expect(findChart().props('chartData')).toEqual([
      ['nami', 21],
      ['zoro', 19],
      ['luffy', 15],
    ]);
  });
});
