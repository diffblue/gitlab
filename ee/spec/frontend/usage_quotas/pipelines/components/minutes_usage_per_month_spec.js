import { cloneDeep } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MinutesUsagePerMonth from 'ee/usage_quotas/pipelines/components/minutes_usage_per_month.vue';
import NoMinutesAlert from 'ee/usage_quotas/pipelines/components/no_minutes_alert.vue';
import { mockGetCiMinutesUsageNamespace } from '../mock_data';

describe('MinutesUsagePerMonth', () => {
  let wrapper;
  const defaultProps = {
    ciMinutesUsage: cloneDeep(mockGetCiMinutesUsageNamespace.data.ciMinutesUsage.nodes),
    selectedYear: 2022,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(MinutesUsagePerMonth, {
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

  it('does not render NoMinutesAlert if there are compute minutes', () => {
    expect(findNoMinutesAlert().exists()).toBe(false);
  });

  describe('with no compute minutes', () => {
    beforeEach(() => {
      const props = {
        ...defaultProps,
        ciMinutesUsage: defaultProps.ciMinutesUsage.map((usage) => ({
          ...usage,
          minutes: 0,
        })),
      };

      createComponent({ props });
    });

    it('does not render compute charts', () => {
      expect(findMinutesByNamespace().exists()).toBe(false);
    });

    it('renders Shared Runners charts', () => {
      expect(findSharedRunnerByNamespace().exists()).toBe(true);
    });
  });

  describe('with no shared runners', () => {
    beforeEach(() => {
      const props = {
        ...defaultProps,
        ciMinutesUsage: defaultProps.ciMinutesUsage.map((usage) => ({
          ...usage,
          sharedRunnersDuration: 0,
        })),
      };

      createComponent({ props });
    });

    it('renders compute charts', () => {
      expect(findMinutesByNamespace().exists()).toBe(true);
    });

    it('does not render Shared Runners charts', () => {
      expect(findSharedRunnerByNamespace().exists()).toBe(false);
    });
  });
});
