import { GlPopover, GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import component from 'ee/approvals/components/approval_check_popover.vue';
import { TEST_HOST } from 'helpers/test_constants';

describe('Approval Check Popover', () => {
  let wrapper;

  const title = 'Title';
  const popoverId = 'reportInfo-Title';

  const createComponent = (props = {}) => {
    wrapper = shallowMount(component, {
      propsData: { title, popoverId, ...props },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('with a documentation link', () => {
    const documentationLink = `${TEST_HOST}/documentation`;
    beforeEach(async () => {
      wrapper.setProps({
        documentationLink,
      });
      await nextTick();
    });

    it('should render the documentation link', () => {
      expect(wrapper.findComponent(GlPopover).findComponent(GlLink).attributes('href')).toBe(
        documentationLink,
      );
    });
  });

  describe('without a documentation link', () => {
    it('should not render the documentation link', () => {
      expect(wrapper.findComponent(GlPopover).findComponent(GlLink).exists()).toBe(false);
    });
  });

  it('renders an Icon with an id that matches the Popover target', () => {
    expect(wrapper.findComponent(GlPopover).props().target).toBe(
      wrapper.findComponent(GlIcon).element.getAttribute('id'),
    );
  });

  it('should render gl-popover with correct props', () => {
    expect(wrapper.findComponent(GlPopover).props()).toMatchObject({
      title,
      target: `reportInfo-${title}`,
      placement: 'top',
    });
  });

  it('renders the default icon', () => {
    expect(wrapper.findComponent(GlIcon).props('name')).toBe('question-o');
  });

  describe('with a name for icon', () => {
    const expectedIconName = 'question-o';

    beforeEach(() => {
      createComponent({ iconName: expectedIconName });
    });

    it('renders icon with correct props', () => {
      expect(wrapper.findComponent(GlIcon).props('name')).toBe(expectedIconName);
    });
  });
});
