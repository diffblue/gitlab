import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ReportHeader from 'ee/compliance_dashboard/components/shared/report_header.vue';

describe('ReportHeader component', () => {
  let wrapper;

  const findHeading = () => wrapper.findByTestId('heading');
  const findSubheading = () => wrapper.findByTestId('subheading');

  const createComponent = (props = {}) => {
    return extendedWrapper(
      shallowMount(ReportHeader, {
        propsData: {
          ...props,
        },
      }),
    );
  };

  describe('default behavior', () => {
    beforeEach(() => {
      wrapper = createComponent({
        heading: 'some heading',
        subheading: 'wow amazing subheading',
        documentationPath: 'https://example.com/foo/bar',
      });
    });

    it('renders the heading', () => {
      expect(findHeading().text()).toContain('some heading');
    });

    it('renders the subheading', () => {
      expect(findSubheading().text()).toContain('wow amazing subheading');
    });

    it(`renders the subheading's help link`, () => {
      const helpLink = findSubheading().findComponent(GlLink);

      expect(helpLink.text()).toBe('Learn more.');
      expect(helpLink.attributes('href')).toBe('https://example.com/foo/bar');
    });
  });
});
