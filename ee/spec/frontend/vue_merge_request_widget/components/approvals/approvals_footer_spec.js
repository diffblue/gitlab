import { GlButton, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ApprovalsFooter from 'ee/vue_merge_request_widget/components/approvals/approvals_footer.vue';
import ApprovalsList from 'ee/vue_merge_request_widget/components/approvals/approvals_list.vue';
import stubChildren from 'helpers/stub_children';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';

const testSuggestedApprovers = () => Array.from({ length: 11 }, (_, i) => i).map((id) => ({ id }));
const testApprovalRules = () => [{ name: 'Lorem' }, { name: 'Ipsum' }];
const testInvalidApprovalRules = () => testApprovalRules().slice(0, 1);

describe('EE MRWidget approvals footer', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(ApprovalsFooter, {
      propsData: {
        suggestedApprovers: testSuggestedApprovers(),
        approvalRules: testApprovalRules(),
        invalidApproversRules: testInvalidApprovalRules(),
        ...props,
      },
      stubs: {
        ...stubChildren(ApprovalsFooter),
        GlButton: false,
      },
    });
  };

  const findToggle = () => wrapper.findComponent(GlButton);
  const findToggleIcon = () => findToggle().findComponent(GlIcon);
  const findToggleLoadingIcon = () => findToggle().findComponent(GlLoadingIcon);
  const findExpandButton = () => wrapper.find('[data-testid="approvers-expand-button"]');
  const findCollapseButton = () => wrapper.find('[data-testid="approvers-collapse-button"]');
  const findList = () => wrapper.findComponent(ApprovalsList);
  const findAvatars = () => wrapper.findComponent(UserAvatarList);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when expanded', () => {
    describe('and has rules', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders approvals list', () => {
        const list = findList();

        expect(list.exists()).toBe(true);
        expect(list.props()).toEqual(
          expect.objectContaining({
            approvalRules: testApprovalRules(),
            invalidApproversRules: testInvalidApprovalRules(),
          }),
        );
      });

      it('does not render user avatar list', () => {
        expect(findAvatars().exists()).toBe(false);
      });

      describe('toggle button', () => {
        it('renders', () => {
          const button = findToggle();

          expect(button.exists()).toBe(true);
          expect(button.attributes('aria-label')).toEqual('Collapse approvers');
        });

        it('renders icon', () => {
          const icon = findToggleIcon();

          expect(icon.exists()).toBe(true);
          expect(icon.props()).toEqual(
            expect.objectContaining({
              name: 'chevron-down',
            }),
          );
        });
      });

      describe('collapse button', () => {
        it('renders', () => {
          const button = findCollapseButton();

          expect(button.exists()).toBe(true);
          expect(button.text()).toEqual('Collapse');
        });

        it('when clicked, collapses the view', () => {
          findCollapseButton().trigger('click');

          expect(wrapper.vm.isCollapsed).toEqual(false);
        });
      });
    });

    describe('and loading', () => {
      beforeEach(() => {
        createComponent({ isLoadingRules: true });
      });

      it('does not render icon in toggle button', () => {
        expect(findToggleIcon().exists()).toBe(false);
      });

      it('renders loading in toggle button', () => {
        expect(findToggleLoadingIcon().exists()).toBe(true);
      });
    });

    describe('and rules empty', () => {
      beforeEach(() => {
        createComponent({ approvalRules: [] });
      });

      it('does not render approvals list', () => {
        expect(findList().exists()).toBe(false);
      });
    });
  });

  describe('when collapsed', () => {
    beforeEach(() => {
      createComponent({ value: false });
    });

    describe('toggle button', () => {
      it('renders', () => {
        const button = findToggle();

        expect(button.exists()).toBe(true);
        expect(button.attributes('aria-label')).toEqual('Expand approvers');
      });

      it('renders icon', () => {
        const icon = findToggleIcon();

        expect(icon.exists()).toBe(true);
        expect(icon.props('name')).toEqual('chevron-right');
      });

      it('expands when clicked', async () => {
        const button = findToggle();

        button.vm.$emit('click');

        await nextTick();
        expect(wrapper.emitted().input).toEqual([[true]]);
      });
    });

    it('renders avatar list', () => {
      const avatars = findAvatars();

      expect(avatars.exists()).toBe(true);
      expect(avatars.props()).toEqual(
        expect.objectContaining({
          items: testSuggestedApprovers().filter((x, idx) => idx < 5),
          breakpoint: 0,
          emptyText: '',
        }),
      );
    });

    it('does not render collapsed text', () => {
      expect(wrapper.text()).not.toContain('Collapse');
    });

    it('does not render approvals list', () => {
      expect(findList().exists()).toBe(false);
    });

    describe('expand button', () => {
      let button;

      beforeEach(() => {
        button = findExpandButton();
      });

      it('renders', () => {
        expect(button.exists()).toBe(true);
        expect(button.text()).toBe('View eligible approvers');
      });

      it('expands when clicked', async () => {
        expect(wrapper.props('value')).toBe(false);

        button.vm.$emit('click');

        await nextTick();
        expect(wrapper.emitted().input).toEqual([[true]]);
      });
    });
  });
});
