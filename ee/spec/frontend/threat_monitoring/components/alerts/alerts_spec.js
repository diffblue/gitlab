import { shallowMount } from '@vue/test-utils';
import Alerts from 'ee/threat_monitoring/components/alerts/alerts.vue';
import AlertsList from 'ee/threat_monitoring/components/alerts/alerts_list.vue';

describe('Alerts component', () => {
  let wrapper;

  const findAlertsList = () => wrapper.findComponent(AlertsList);

  const createWrapper = () => {
    wrapper = shallowMount(Alerts);
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows threat monitoring alerts list', () => {
      expect(findAlertsList().exists()).toBe(true);
    });
  });
});
