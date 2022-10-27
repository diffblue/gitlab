import { mount } from '@vue/test-utils';
import Component from 'ee/analytics/contribution_analytics/components/column_chart.vue';

const mockChartData = [
  ['root', 100],
  ['desiree', 30],
  ['katlyn', 70],
  ['myrtis', 0],
];

describe('Contribution Analytics Column Chart', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(Component, {
      propsData: {
        chartData: mockChartData,
        xAxisTitle: 'Username',
        yAxisTitle: 'Pushes',
      },
      stubs: {
        'gl-column-chart': true,
      },
    });
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
