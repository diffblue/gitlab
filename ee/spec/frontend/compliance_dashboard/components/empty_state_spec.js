import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import EmptyState from 'ee/compliance_dashboard/components/empty_state.vue';

const IMAGE_PATH = 'empty.svg';

describe('EmptyState component', () => {
  let wrapper;

  const emptyStateProp = (prop) => wrapper.find(GlEmptyState).props(prop);

  const createComponent = (props = {}) => {
    return shallowMount(EmptyState, {
      propsData: {
        imagePath: IMAGE_PATH,
        ...props,
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('behaviour', () => {
    it('sets the empty SVG path', () => {
      expect(emptyStateProp('svgPath')).toBe(IMAGE_PATH);
    });

    it('sets the description', () => {
      expect(emptyStateProp('description')).toBe(
        'The compliance report captures merged changes that violate compliance best practices.',
      );
    });
  });
});
