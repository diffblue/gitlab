import { GlButton, GlEmptyState } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';

import TableEmptyState from 'ee/groups/settings/compliance_frameworks/components/table_empty_state.vue';

describe('TableEmptyState', () => {
  let wrapper;
  const addFrameworkPath = 'group/framework/new';

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findAddFrameworkButton = () => wrapper.findComponent(GlButton);

  const createComponent = (props = {}, glFeatures = {}, mountFn = shallowMount) => {
    wrapper = mountFn(TableEmptyState, {
      propsData: {
        imagePath: 'dir/image.svg',
        addFrameworkPath,
        ...props,
      },
      provide: {
        glFeatures,
      },
    });
  };

  it('has the correct props', () => {
    createComponent();

    expect(findEmptyState().props()).toMatchObject({
      description: 'Frameworks that have been added will appear here.',
      svgPath: 'dir/image.svg',
      svgHeight: 100,
      compact: true,
    });
  });

  it('displays the correct title', () => {
    createComponent();

    expect(findEmptyState().find('h5').text()).toBe('No compliance frameworks are set up yet');
  });

  it('has an add framework action', () => {
    createComponent();
    const button = findAddFrameworkButton();

    expect(button.text()).toBe('Add framework');
  });

  describe('"manageComplianceFrameworksModalsRefactor" feature flag', () => {
    it('emits the expected event when flag is enabled and add framework button is clicked', () => {
      createComponent({}, { manageComplianceFrameworksModalsRefactor: true });

      const clickEvent = new Event('click');
      findAddFrameworkButton().vm.$emit('click', clickEvent);

      expect(wrapper.emitted('addFramework')).toHaveLength(1);
      expect(wrapper.emitted('addFramework')[0][0]).toBe(clickEvent);
    });

    it('does not emit events when flag is disabled and add framework button is clicked', () => {
      createComponent({}, { manageComplianceFrameworksModalsRefactor: false });

      findAddFrameworkButton().vm.$emit('click', new Event('click'));

      expect(wrapper.emitted('addFramework')).toBeUndefined();
    });

    it('renders a button when the flag is enabled', () => {
      createComponent({}, { manageComplianceFrameworksModalsRefactor: true }, mount);
      const btn = findAddFrameworkButton();

      expect(btn.find('button').exists()).toBe(true);
      expect(btn.find('a').exists()).toBe(false);
    });

    it('renders a link when the flag is disabled', () => {
      createComponent({}, { manageComplianceFrameworksModalsRefactor: false }, mount);
      const btn = findAddFrameworkButton();

      expect(btn.find('a').exists()).toBe(true);
      expect(btn.find('button').exists()).toBe(false);
    });
  });
});
