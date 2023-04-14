import { mount, shallowMount } from '@vue/test-utils';
import ExpandableSection from 'ee/security_configuration/components/expandable_section.vue';
import { stubTransition } from 'helpers/stub_transition';

describe('ExpandableSection component', () => {
  let wrapper;

  const createComponent = (options, mountFn = shallowMount) => {
    wrapper = mountFn(ExpandableSection, {
      stubs: { transition: stubTransition() },
      ...options,
    });
  };

  const findHeading = () => wrapper.find('[data-testid="heading"]');
  const findSubHeading = () => wrapper.find('[data-testid="sub-heading"]');
  const findContent = () => wrapper.find('[data-testid="content"]');

  describe('headingTag', () => {
    it('defaults to h3', () => {
      createComponent();

      expect(findHeading().element.tagName).toBe('H3');
    });

    it('uses the given the heading tag name', () => {
      const headingTag = 'h6';

      createComponent({
        propsData: { headingTag },
      });

      expect(findHeading().element.tagName).toBe(headingTag.toUpperCase());
    });
  });

  describe('heading slot', () => {
    beforeEach(() => {
      createComponent({
        slots: { heading: 'some heading' },
      });
    });

    it('renders the given heading content', () => {
      expect(findHeading().html()).toContain('some heading');
    });
  });

  describe('subheading slot', () => {
    beforeEach(() => {
      createComponent({
        slots: { 'sub-heading': 'some subheading' },
      });
    });

    it('renders the given subheading content', () => {
      expect(findSubHeading().html()).toContain('some subheading');
    });
  });

  describe('default slot', () => {
    beforeEach(() => {
      createComponent({
        slots: { default: 'some content' },
      });
    });

    it('renders the given content', () => {
      expect(findContent().html()).toContain('some content');
    });
  });

  describe('expand/collapse behavior', () => {
    it('hides the content by default', () => {
      createComponent({}, mount);

      expect(findContent().isVisible()).toBe(false);
    });
  });
});
