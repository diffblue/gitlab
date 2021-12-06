import { GlButton } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import BridgeSidebar from '~/jobs/bridge/components/sidebar.vue';
import { BUILD_NAME } from '../mock_data';

describe('Bridge Sidebar', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(BridgeSidebar, {
      provide: {
        buildName: BUILD_NAME,
      },
    });
  };

  const findSidebar = () => wrapper.find('aside');
  const findRetryDropdown = () => wrapper.find('[data-testid="retry-dropdown"]');
  const findToggle = () => wrapper.find(GlButton);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders retry dropdown', () => {
      expect(findRetryDropdown().exists()).toBe(true);
    });
  });

  describe('sidebar expansion', () => {
    beforeEach(() => {
      createComponent();
    });

    it('toggles expansion on button click', async () => {
      expect(findSidebar().classes()).toContain('right-sidebar-expanded');
      expect(findSidebar().classes()).not.toContain('right-sidebar-collapsed');

      findToggle().vm.$emit('click');
      await nextTick();

      expect(findSidebar().classes()).toContain('right-sidebar-collapsed');
      expect(findSidebar().classes()).not.toContain();
    });

    describe('on resize', () => {
      it.each`
        breakpoint | isSidebarExpanded
        ${'xs'}    | ${false}
        ${'sm'}    | ${false}
        ${'md'}    | ${true}
        ${'lg'}    | ${true}
        ${'xl'}    | ${true}
      `(
        'sets isSidebarExpanded to `$isSidebarExpanded` when the breakpoint is "$breakpoint"',
        async ({ breakpoint, isSidebarExpanded }) => {
          jest.spyOn(GlBreakpointInstance, 'getBreakpointSize').mockReturnValue(breakpoint);
          const sidebarClass = isSidebarExpanded
            ? 'right-sidebar-expanded'
            : 'right-sidebar-collapsed';

          wrapper.vm.onResize();
          await nextTick();

          expect(findSidebar().classes()).toContain(sidebarClass);
        },
      );
    });
  });
});
