import { shallowMount } from '@vue/test-utils';
import EnvironmentPicker from 'ee/threat_monitoring/components/environment_picker.vue';
import ThreatMonitoringFilters from 'ee/threat_monitoring/components/threat_monitoring_filters.vue';
import createStore from 'ee/threat_monitoring/store';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import { timeRanges, defaultTimeRange } from '~/vue_shared/constants';
import { mockEnvironmentsResponse } from '../mocks/mock_data';

const mockEnvironments = mockEnvironmentsResponse.environments;
const currentEnvironment = mockEnvironments[1];

describe('ThreatMonitoringFilters component', () => {
  let store;
  let wrapper;

  const factory = (state) => {
    store = createStore();
    store.replaceState({
      ...store.state,
      threatMonitoring: {
        ...store.state.threatMonitoring,
        currentEnvironmentId: currentEnvironment.id,
        environments: mockEnvironments,
        hasEnvironment: true,
        ...state,
      },
    });

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(ThreatMonitoringFilters, {
      store,
    });
  };

  const findEnvironmentsPicker = () => wrapper.findComponent(EnvironmentPicker);
  const findShowLastDropdown = () => wrapper.findComponent(DateTimePicker);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('has environments', () => {
    beforeEach(() => {
      factory();
    });

    it('renders EnvironmentPicker', () => {
      expect(findEnvironmentsPicker().exists()).toBe(true);
    });

    it('renders the "Show last" dropdown correctly', () => {
      expect(findShowLastDropdown().attributes().disabled).toBe(undefined);
      expect(findShowLastDropdown().vm.value.label).toBe(defaultTimeRange.label);
    });

    it('has dropdown items for each time window', () => {
      const dropdownOptions = findShowLastDropdown().props('options');
      Object.entries(timeRanges).forEach(([index, timeWindow]) => {
        const dropdownOption = dropdownOptions[index];
        expect(dropdownOption.interval).toBe(timeWindow.interval);
        expect(dropdownOption.duration.seconds).toBe(timeWindow.duration.seconds);
      });
    });
  });

  describe.each`
    context                                 | status        | isLoadingEnvironments | environments        | disabled
    ${'environments are initially loading'} | ${'does'}     | ${true}               | ${[]}               | ${'true'}
    ${'more environments are loading'}      | ${'does not'} | ${true}               | ${mockEnvironments} | ${undefined}
    ${'there are no environments'}          | ${'does'}     | ${false}              | ${[]}               | ${'true'}
  `('when $context', ({ isLoadingEnvironments, environments, disabled, status }) => {
    beforeEach(() => {
      factory({ environments, isLoadingEnvironments });
    });

    it(`${status} disable the "Show last" dropdown`, () => {
      expect(findShowLastDropdown().attributes('disabled')).toBe(disabled);
    });
  });
});
