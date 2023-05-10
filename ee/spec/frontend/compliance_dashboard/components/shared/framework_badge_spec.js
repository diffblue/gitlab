import { GlLabel, GlButton, GlBadge, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import FrameworkBadge from 'ee/compliance_dashboard/components/shared/framework_badge.vue';

import { complianceFramework } from '../../mock_data';

describe('FrameworkBadge component', () => {
  let wrapper;

  const findLabel = () => wrapper.findComponent(GlLabel);
  const findTooltip = () => wrapper.findComponent(GlPopover);
  const findDefaultBadge = () => wrapper.findComponent(GlBadge);
  const findEditButton = () => wrapper.findComponent(GlPopover).findComponent(GlButton);

  const createComponent = (props = {}) => {
    return shallowMount(FrameworkBadge, {
      propsData: {
        ...props,
      },
    });
  };

  describe('default behavior', () => {
    it('renders edit link', () => {
      wrapper = createComponent({ framework: complianceFramework });

      expect(findEditButton().exists()).toBe(true);
    });

    it('emits edit event when edit link is clicked', async () => {
      wrapper = createComponent({ framework: complianceFramework });

      await findEditButton().vm.$emit('click', new MouseEvent('click'));
      expect(wrapper.emitted('edit')).toHaveLength(1);
    });

    it('renders the framework label', () => {
      wrapper = createComponent({ framework: complianceFramework });

      expect(findLabel().props()).toMatchObject({
        backgroundColor: '#009966',
        title: complianceFramework.name,
      });
      expect(findTooltip().text()).toContain(complianceFramework.description);
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
