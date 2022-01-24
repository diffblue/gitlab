import { GlPopover, GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import component from 'ee/approvals/components/approval_check_popover.vue';
import { TEST_HOST } from 'helpers/test_constants';

describe('Approval Check Popover', () => {
  let wrapper;

  const title = 'Title';

  beforeEach(() => {
    wrapper = shallowMount(component, {
      propsData: { title },
    });
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
      expect(wrapper.find(GlPopover).find(GlLink).attributes('href')).toBe(documentationLink);
    });
  });

  describe('without a documentation link', () => {
    it('should not render the documentation link', () => {
      expect(wrapper.find(GlPopover).find(GlLink).exists()).toBeFalsy();
    });
  });

  it('renders an Icon with an id that matches the Popover target', () => {
    expect(wrapper.find(GlPopover).props().target).toBe(
      wrapper.find(GlIcon).element.getAttribute('id'),
    );
  });

  it('should render gl-popover with correct props', () => {
    expect(wrapper.find(GlPopover).props()).toMatchObject({
      title,
      target: `reportInfo-${title}`,
      placement: 'top',
    });
  });
});
