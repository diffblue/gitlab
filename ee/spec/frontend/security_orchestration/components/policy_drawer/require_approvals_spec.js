import { mount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import RequireApprovals from 'ee/security_orchestration/components/policy_drawer/require_approvals.vue';
import { createRequiredApprovers } from '../../mocks/mock_scan_result_policy_data';

describe('RequireApprovals component', () => {
  let wrapper;

  const findApprovers = () => wrapper.findAll('[data-testid]');
  const findLinks = () => wrapper.findAllComponents(GlLink);

  const factory = (propsData) => {
    wrapper = mount(RequireApprovals, {
      propsData,
    });
  };

  describe.each`
    approvalsRequired | approvers                     | expectedTestIds                                                                                                                                                                                 | expectedApprovalText | expectedApproverText
    ${1}              | ${createRequiredApprovers(1)} | ${[['data-testid', 'gid://gitlab/Group/1']]}                                                                                                                                                    | ${'approval'}        | ${/grouppath1/}
    ${3}              | ${createRequiredApprovers(1)} | ${[['data-testid', 'gid://gitlab/Group/1']]}                                                                                                                                                    | ${'approvals'}       | ${/grouppath1/}
    ${1}              | ${createRequiredApprovers(2)} | ${[['data-testid', 'gid://gitlab/Group/1'], ['data-testid', 'gid://gitlab/User/2']]}                                                                                                            | ${'approval'}        | ${/grouppath1[^]*and[^]*username2/}
    ${1}              | ${createRequiredApprovers(3)} | ${[['data-testid', 'gid://gitlab/Group/1'], ['data-testid', 'gid://gitlab/User/2'], ['data-testid', 'Owner']]}                                                                                  | ${'approval'}        | ${/grouppath1[^]*,[^]*username2[^]*and[^]*Owner[^]/}
    ${1}              | ${createRequiredApprovers(5)} | ${[['data-testid', 'gid://gitlab/Group/1'], ['data-testid', 'gid://gitlab/User/2'], ['data-testid', 'Owner'], ['data-testid', 'gid://gitlab/Group/4'], ['data-testid', 'gid://gitlab/User/5']]} | ${'approval'}        | ${/grouppath1[^]*,[^]*username2[^]*,[^]*Owner[^]*and 2 more/}
  `(
    'with $approvalsRequired approval required and $approvers.length approvers',
    ({
      approvalsRequired,
      approvers,
      expectedApprovalText,
      expectedApproverText,
      expectedTestIds,
    }) => {
      beforeEach(() => {
        const action = { approvals_required: approvalsRequired };
        factory({ action, approvers });
      });

      it('renders the complete text', () => {
        const text = wrapper.text();

        expect(text).toContain(expectedApprovalText);
        expect(text).toMatch(expectedApproverText);
      });

      it('includes popover related info to all links', () => {
        const expectedClasses = ['gl-link', 'gfm', 'gfm-project_member', 'js-user-link'];

        findLinks().wrappers.forEach((link) => {
          expect(link.classes()).toStrictEqual(expect.arrayContaining(expectedClasses));
        });
      });

      it('renders link with proper attributes for all approvers', () => {
        findApprovers().wrappers.forEach((link, index) => {
          const expectedAttribute = expectedTestIds[index][0];
          const expectedValue = expectedTestIds[index][1];
          expect(link.attributes(expectedAttribute)).toBe(expectedValue);
        });
      });
    },
  );
});
