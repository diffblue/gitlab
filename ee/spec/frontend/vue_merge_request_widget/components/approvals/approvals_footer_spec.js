import { mount } from '@vue/test-utils';
import ApprovalsFooter from 'ee/vue_merge_request_widget/components/approvals/approvals_footer.vue';
import ApprovalsList from 'ee/vue_merge_request_widget/components/approvals/approvals_list.vue';
import stubChildren from 'helpers/stub_children';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';

const testSuggestedApprovers = () => Array.from({ length: 11 }, (_, i) => i).map((id) => ({ id }));
const testApprovalRules = () => [{ name: 'Lorem' }, { name: 'Ipsum' }];

describe('EE MRWidget approvals footer', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(ApprovalsFooter, {
      propsData: {
        suggestedApprovers: testSuggestedApprovers(),
        approvalRules: testApprovalRules(),
        projectPath: 'gitlab-org/gitlab',
        iid: '1',
        ...props,
      },
      stubs: {
        ...stubChildren(ApprovalsFooter),
        GlButton: false,
      },
    });
  };

  const findList = () => wrapper.findComponent(ApprovalsList);
  const findAvatars = () => wrapper.findComponent(UserAvatarList);

  describe('and has rules', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders approvals list', () => {
      const list = findList();

      expect(list.exists()).toBe(true);
    });

    it('does not render user avatar list', () => {
      expect(findAvatars().exists()).toBe(false);
    });
  });
});
