import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import ColumnChart from 'ee/analytics/contribution_analytics/components/column_chart.vue';
import IssuesChart from 'ee/analytics/contribution_analytics/components/issues_chart.vue';
import { MOCK_ISSUES } from '../mock_data';

describe('Contribution Analytics Issues Chart', () => {
  let wrapper;

  const findDescription = () => wrapper.findByTestId('description').text();
  const findChart = () => wrapper.findComponent(ColumnChart);

  const createWrapper = (issues) => {
    wrapper = mountExtended(IssuesChart, {
      propsData: {
        issues,
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
    createWrapper(MOCK_ISSUES);
    expect(findDescription()).toBe('31 created, 36 closed.');
  });

  it('sorts the chart by closed issues in descending order', () => {
    createWrapper(MOCK_ISSUES);
    expect(findChart().props('chartData')).toEqual([
      ['nami', 27],
      ['luffy', 7],
      ['zoro', 2],
    ]);
  });
});
