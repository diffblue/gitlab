import { mount, shallowMount } from '@vue/test-utils';
import TasksByTypeChart from 'ee/analytics/cycle_analytics/components/tasks_by_type/tasks_by_type_chart.vue';
import { tasksByTypeData } from '../../mock_data';

const { groupBy, data, seriesNames } = tasksByTypeData;

function createComponent({ props = {}, shallow = true, stubs = {} }) {
  const fn = shallow ? shallowMount : mount;
  return fn(TasksByTypeChart, {
    propsData: {
      groupBy,
      data,
      seriesNames,
      ...props,
    },
    stubs: {
      'gl-stacked-column-chart': true,
      'tasks-by-type-filters': true,
      ...stubs,
    },
  });
}

describe('TasksByTypeChart', () => {
  let wrapper = null;

  describe('with data available', () => {
    beforeEach(() => {
      wrapper = createComponent({});
    });

    it('should render the loading chart', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });

  describe('no data available', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: {
          groupBy: [],
          data: [],
          seriesNames: [],
        },
      });
    });

    it('should render the no data available message', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });
});
