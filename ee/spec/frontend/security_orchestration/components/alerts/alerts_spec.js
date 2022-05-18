import { shallowMount } from '@vue/test-utils';
import AlertsList from 'ee/security_orchestration/components/alerts/alerts_list.vue';
import Alerts from 'ee/security_orchestration/components/alerts/alerts.vue';

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
