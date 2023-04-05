import { cloneDeep } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MinutesUsageCharts from 'ee/usage_quotas/pipelines/components/minutes_usage_charts.vue';
import NoMinutesAlert from 'ee/usage_quotas/pipelines/components/no_minutes_alert.vue';
import { mockGetCiMinutesUsageNamespace } from '../mock_data';

describe('MinutesUsageCharts', () => {
  let wrapper;
  const defaultProps = {
    ciMinutesUsage: cloneDeep(mockGetCiMinutesUsageNamespace.data.ciMinutesUsage.nodes),
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(MinutesUsageCharts, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findNoMinutesAlert = () => wrapper.findComponent(NoMinutesAlert);
  const findMinutesByNamespace = () => wrapper.findByTestId('minutes-by-namespace');
  const findSharedRunnerByNamespace = () => wrapper.findByTestId('shared-runner-by-namespace');
  const findMinutesByProject = () => wrapper.findByTestId('minutes-by-project');
  const findSharedRunnerByProject = () => wrapper.findByTestId('shared-runner-by-project');
  const findYearDropdown = () => wrapper.findByTestId('minutes-usage-year-dropdown');

  it('does not render NoMinutesAlert if there are minutes', () => {
    expect(findNoMinutesAlert().exists()).toBe(false);
  });

  it('should contain a year dropdown', () => {
    expect(findYearDropdown().exists()).toBe(true);
  });

  describe('with no minutes', () => {
    beforeEach(() => {
      const props = {
        ...defaultProps,
        ciMinutesUsage: defaultProps.ciMinutesUsage.map((usage) => ({
          ...usage,
          minutes: 0,
          projects: {
            ...usage.projects,
            nodes: usage.projects.nodes.map((project) => ({
              ...project,
              minutes: 0,
            })),
          },
        })),
      };

      createComponent({ props });
    });

    it('does not render CI minutes charts', () => {
      expect(findMinutesByNamespace().exists()).toBe(false);
      expect(findMinutesByProject().exists()).toBe(false);
    });

    it('renders Shared Runners charts', () => {
      expect(findSharedRunnerByNamespace().exists()).toBe(true);
      expect(findSharedRunnerByProject().exists()).toBe(true);
    });
  });

  describe('with no shared runners', () => {
    beforeEach(() => {
      const props = {
        ...defaultProps,
        ciMinutesUsage: defaultProps.ciMinutesUsage.map((usage) => ({
          ...usage,
          sharedRunnersDuration: 0,
          projects: {
            ...usage.projects,
            nodes: usage.projects.nodes.map((project) => ({
              ...project,
              sharedRunnersDuration: 0,
            })),
          },
        })),
      };

      createComponent({ props });
    });

    it('renders CI minutes charts', () => {
      expect(findMinutesByNamespace().exists()).toBe(true);
      expect(findMinutesByProject().exists()).toBe(true);
    });

    it('does not render Shared Runners charts', () => {
      expect(findSharedRunnerByNamespace().exists()).toBe(false);
      expect(findSharedRunnerByProject().exists()).toBe(false);
    });
  });
});
