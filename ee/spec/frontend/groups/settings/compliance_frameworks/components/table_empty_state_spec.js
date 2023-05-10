import { GlButton, GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import TableEmptyState from 'ee/groups/settings/compliance_frameworks/components/table_empty_state.vue';

describe('TableEmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findAddFrameworkButton = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    wrapper = shallowMount(TableEmptyState, {
      propsData: {
        imagePath: 'dir/image.svg',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('has the correct props', () => {
    expect(findEmptyState().props()).toMatchObject({
      description: 'Frameworks that have been added will appear here.',
      svgPath: 'dir/image.svg',
      svgHeight: 100,
      compact: true,
    });
  });

  it('displays the correct title', () => {
    expect(findEmptyState().find('h5').text()).toBe('No compliance frameworks are set up yet');
  });

  it('has an add framework action', () => {
    const button = findAddFrameworkButton();

    expect(button.text()).toBe('Add framework');
  });

  it('emits the expected event when the add framework button is clicked', () => {
    const clickEvent = new Event('click');
    findAddFrameworkButton().vm.$emit('click', clickEvent);

    expect(wrapper.emitted('addFramework')).toHaveLength(1);
    expect(wrapper.emitted('addFramework')[0][0]).toBe(clickEvent);
  });
});
