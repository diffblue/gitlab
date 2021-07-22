import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import MinutesUsageProjectChart from 'ee/ci_minutes_usage/components/minutes_usage_project_chart.vue';
import { ciMinutesUsageMockData } from '../mock_data';

describe('Minutes usage by project chart component', () => {
  let wrapper;

  const findColumnChart = () => wrapper.findComponent(GlColumnChart);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

  const createComponent = () => {
    return shallowMount(MinutesUsageProjectChart, {
      propsData: {
        minutesUsageData: ciMinutesUsageMockData.data.ciMinutesUsage.nodes,
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a column chart component with axis legends', () => {
    expect(findColumnChart().exists()).toBe(true);
    expect(findColumnChart().props('xAxisTitle')).toBe('Projects');
    expect(findColumnChart().props('yAxisTitle')).toBe('Minutes');
  });

  it('renders a dropdown component', () => {
    expect(findDropdown().exists()).toBe(true);
    expect(findDropdown().props('text')).toBe(
      ciMinutesUsageMockData.data.ciMinutesUsage.nodes[0].month,
    );
  });

  it('renders the same amount of dropdown components as the backend response', () => {
    expect(findAllDropdownItems().length).toBe(
      ciMinutesUsageMockData.data.ciMinutesUsage.nodes.length,
    );
  });
});
