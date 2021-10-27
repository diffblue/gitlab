import { shallowMount } from '@vue/test-utils';
import ThreatMonitoringAlerts from 'ee/threat_monitoring/components/alerts/alerts.vue';
import ThreatMonitoringApp from 'ee/threat_monitoring/components/app.vue';
import NoEnvironmentEmptyState from 'ee/threat_monitoring/components/no_environment_empty_state.vue';
import ThreatMonitoringFilters from 'ee/threat_monitoring/components/threat_monitoring_filters.vue';
import createStore from 'ee/threat_monitoring/store';
import { TEST_HOST } from 'helpers/test_constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const documentationPath = '/docs';
const newPolicyPath = '/policy/new';
const networkPolicyNoDataSvgPath = '/network-policy-no-data-svg';
const environmentsEndpoint = `${TEST_HOST}/environments`;
const hasEnvironment = true;
const networkPolicyStatisticsEndpoint = `${TEST_HOST}/network_policy`;

describe('ThreatMonitoringApp component', () => {
  let store;
  let wrapper;

  const factory = ({ propsData, state, stubs = {} } = {}) => {
    store = createStore();
    Object.assign(store.state.threatMonitoring, {
      environmentsEndpoint,
      hasEnvironment,
      networkPolicyStatisticsEndpoint,
      ...state,
    });

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = extendedWrapper(
      shallowMount(ThreatMonitoringApp, {
        propsData: {
          networkPolicyNoDataSvgPath,
          newPolicyPath,
          ...propsData,
        },
        provide: {
          documentationPath,
        },
        store,
        stubs,
      }),
    );
  };

  const findAlertsView = () => wrapper.findComponent(ThreatMonitoringAlerts);
  const findFilters = () => wrapper.findComponent(ThreatMonitoringFilters);
  const findStatisticsSection = () => wrapper.findByTestId('threat-monitoring-statistics-section');
  const findNoEnvironmentEmptyState = () => wrapper.findComponent(NoEnvironmentEmptyState);
  const findAlertTab = () => wrapper.findByTestId('threat-monitoring-alerts-tab');
  const findStatisticsTab = () => wrapper.findByTestId('threat-monitoring-statistics-tab');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('given there are environments present', () => {
    beforeEach(() => {
      factory();
    });

    it.each`
      component                         | status                | findComponent                  | state
      ${'"no environment" empty state'} | ${'does not display'} | ${findNoEnvironmentEmptyState} | ${false}
      ${'alert tab'}                    | ${'does display'}     | ${findAlertTab}                | ${true}
      ${'statistics tab'}               | ${'does display'}     | ${findStatisticsTab}           | ${true}
      ${'statistics filter section'}    | ${'does display'}     | ${findFilters}                 | ${true}
      ${'statistics section'}           | ${'does display'}     | ${findStatisticsSection}       | ${true}
    `('$status the $component', async ({ findComponent, state }) => {
      expect(findComponent().exists()).toBe(state);
    });

    it('passes the statistics section the correct information', () => {
      expect(findStatisticsSection().element).toMatchSnapshot();
    });
  });

  describe('given there are no environments present', () => {
    beforeEach(() => {
      factory({ state: { hasEnvironment: false }, stubs: { GlTabs: false } });
    });

    it.each`
      component                         | status                | findComponent                  | state
      ${'"no environment" empty state'} | ${'does display'}     | ${findNoEnvironmentEmptyState} | ${true}
      ${'statistics filter section'}    | ${'does not display'} | ${findFilters}                 | ${false}
      ${'statistics section'}           | ${'does not display'} | ${findStatisticsSection}       | ${false}
    `('$status the $component', async ({ findComponent, state }) => {
      expect(findComponent().exists()).toBe(state);
    });
  });

  describe('alerts tab', () => {
    beforeEach(() => {
      factory();
    });
    it('shows the alerts tab', () => {
      expect(findAlertTab().exists()).toBe(true);
    });
    it('shows the default alerts component', () => {
      expect(findAlertsView().exists()).toBe(true);
    });
  });
});
