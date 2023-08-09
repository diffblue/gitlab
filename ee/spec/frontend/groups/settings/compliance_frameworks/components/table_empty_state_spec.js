import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import TableEmptyState from 'ee/groups/settings/compliance_frameworks/components/table_empty_state.vue';

describe('TableEmptyState', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

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
      svgPath: 'dir/image.svg',
      svgHeight: 100,
    });
  });

  it('displays the correct title', () => {
    expect(findEmptyState().find('h6').text()).toBe('No compliance frameworks are set up yet');
  });

  it('displays the correct description', () => {
    expect(findEmptyState().find('p').text()).toBe(
      'Frameworks that have been added will appear here, start by creating a new one above.',
    );
  });
});
