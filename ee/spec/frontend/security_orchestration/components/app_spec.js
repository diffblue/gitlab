import { shallowMount } from '@vue/test-utils';
import ThreatMonitoringAlerts from 'ee/security_orchestration/components/alerts/alerts.vue';
import ThreatMonitoringApp from 'ee/security_orchestration/components/app.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const documentationPath = '/docs';

describe('ThreatMonitoringApp component', () => {
  let wrapper;

  const factory = () => {
    wrapper = extendedWrapper(
      shallowMount(ThreatMonitoringApp, {
        provide: {
          documentationPath,
        },
      }),
    );
  };

  const findAlertsView = () => wrapper.findComponent(ThreatMonitoringAlerts);
  const findAlertTab = () => wrapper.findByTestId('threat-monitoring-alerts-tab');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
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
