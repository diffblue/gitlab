import { mount } from '@vue/test-utils';
import AutoFixHelpText from 'ee/security_dashboard/components/shared/auto_fix_help_text.vue';

const TEST_MERGE_REQUEST_DATA = {
  webUrl: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/48820',
  state: 'merged',
  securityAutoFix: true,
  iid: 48820,
};

describe('AutoFix Help Text component', () => {
  let wrapper;
  const createWrapper = ({ props = {} } = {}) => {
    return mount(AutoFixHelpText, {
      propsData: {
        mergeRequest: TEST_MERGE_REQUEST_DATA,
        ...props,
      },
      stubs: {
        GlPopover: true,
      },
    });
  };

  beforeEach(() => {
    wrapper = createWrapper();
  });

  const findByTestId = (id) => wrapper.find(`[data-testid="${id}"]`);

  it('popover should have wrapping div as target', () => {
    expect(
      findByTestId('vulnerability-solutions-popover')
        .props()
        .target()
        .isSameNode(wrapper.find('[data-testid="vulnerability-solutions-bulb"]').element),
    ).toBe(true);
  });

  it('popover should contain Icon with passed status', () => {
    expect(findByTestId('vulnerability-solutions-popover-icon').props().name).toBe('merge');
  });

  it('popover should contain Link with passed href', () => {
    expect(findByTestId('vulnerability-solutions-popover-link').attributes('href')).toBe(
      TEST_MERGE_REQUEST_DATA.webUrl,
    );
  });

  it('popover should contain passed MergeRequest ID', () => {
    expect(findByTestId('vulnerability-solutions-popover-link-id').text()).toContain(
      `!${TEST_MERGE_REQUEST_DATA.iid}`,
    );
  });

  it('popover should contain Autofix Indicator when available', () => {
    expect(findByTestId('vulnerability-solutions-popover-link-autofix').text()).toBe(': Auto-fix');
  });

  describe('with autofix not available', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        props: {
          mergeRequest: {
            ...TEST_MERGE_REQUEST_DATA,
            securityAutoFix: false,
          },
        },
      });
    });

    it('popover should not contain Autofix Indicator', () => {
      expect(findByTestId('vulnerability-solutions-popover-link-autofix').exists()).toBe(false);
    });
  });
});
