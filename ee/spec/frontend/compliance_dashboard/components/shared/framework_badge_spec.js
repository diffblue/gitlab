import { GlLabel, GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import FrameworkBadge from 'ee/compliance_dashboard/components/shared/framework_badge.vue';

import { complianceFramework } from '../../mock_data';

describe('FrameworkBadge component', () => {
  let wrapper;

  const findLabel = () => wrapper.findComponent(GlLabel);
  const findDefaultBadge = () => wrapper.findComponent(GlBadge);

  const createComponent = (props = {}) => {
    return shallowMount(FrameworkBadge, {
      propsData: {
        ...props,
      },
    });
  };

  describe('default behavior', () => {
    it('renders the framework label', () => {
      wrapper = createComponent({ framework: complianceFramework });

      expect(findLabel().props()).toMatchObject({
        backgroundColor: '#009966',
        description: 'General Data Protection Regulation',
        title: 'GDPR',
      });
    });

    it('renders the default badge when the framework is default', () => {
      wrapper = createComponent({ framework: { ...complianceFramework, default: true } });

      expect(findDefaultBadge().exists()).toBe(true);
      expect(findDefaultBadge().text()).toBe('default');
    });

    it('does not render the default badge when the framework is default but component is configured to hide the badge', () => {
      wrapper = createComponent({
        framework: { ...complianceFramework, default: true },
        showDefault: false,
      });

      expect(findDefaultBadge().exists()).toBe(false);
    });

    it('does not render the default badge when the framework is not default', () => {
      wrapper = createComponent({ framework: complianceFramework });

      expect(findDefaultBadge().exists()).toBe(false);
    });

    it('renders closeable label when closeable is true', () => {
      wrapper = createComponent({ framework: complianceFramework, closeable: true });

      expect(findLabel().props('showCloseButton')).toBe(true);
    });
  });
});
