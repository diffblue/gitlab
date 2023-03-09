import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Cookies from '~/lib/utils/cookies';
import ResolutionAlert, { COOKIE_NAME } from 'ee/vulnerabilities/components/resolution_alert.vue';

describe('Vulnerability list component', () => {
  let wrapper;
  const defaultBranchName = 'not-always-main';
  const vulnerabilityId = 61;

  const createWrapper = (options = {}) => {
    wrapper = shallowMount(ResolutionAlert, options);
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  afterEach(() => {
    Cookies.remove(COOKIE_NAME);
  });

  describe('with a default branch name passed to it', () => {
    beforeEach(() => {
      createWrapper({
        propsData: { defaultBranchName, vulnerabilityId },
      });
    });

    it('should render the default branch name in the alert title', () => {
      expect(findAlert().attributes().title).toMatch(defaultBranchName);
    });

    it('should call the dismiss method when dismissed', () => {
      expect(wrapper.vm.isVisible).toBe(true);
      wrapper.vm.dismiss();
      expect(wrapper.vm.isVisible).toBe(false);
    });
  });

  describe('when already dismissed', () => {
    beforeEach(() => {
      Cookies.set(COOKIE_NAME, JSON.stringify([vulnerabilityId]));
      createWrapper({
        propsData: { defaultBranchName, vulnerabilityId },
      });
    });

    it('should not display the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('with no default branch name', () => {
    beforeEach(() => {
      createWrapper({ propsData: { vulnerabilityId } });
    });

    it('should render the fallback in the alert title', () => {
      expect(findAlert().attributes('title')).toMatch('in the default branch');
    });
  });
});
