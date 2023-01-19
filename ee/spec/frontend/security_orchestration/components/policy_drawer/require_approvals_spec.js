import { mount } from '@vue/test-utils';
import RequireApprovals from 'ee/security_orchestration/components/policy_drawer/require_approvals.vue';
import { createRequiredApprovers } from '../../mocks/mock_scan_result_policy_data';

describe('RequireApprovals component', () => {
  let wrapper;

  const findLinks = () => wrapper.findAll('a');

  const factory = (propsData) => {
    wrapper = mount(RequireApprovals, {
      propsData,
    });
  };

  describe.each`
    approvalsRequired | approvers                     | expectedAttributes                                                                                         | expectedApprovalText | expectedApproverText
    ${1}              | ${createRequiredApprovers(1)} | ${[['data-group', '1']]}                                                                                   | ${'approval'}        | ${/grouppath1/}
    ${3}              | ${createRequiredApprovers(1)} | ${[['data-group', '1']]}                                                                                   | ${'approvals'}       | ${/grouppath1/}
    ${1}              | ${createRequiredApprovers(2)} | ${[['data-group', '1'], ['data-user', '2']]}                                                               | ${'approval'}        | ${/grouppath1[^]*and[^]*username2/}
    ${1}              | ${createRequiredApprovers(3)} | ${[['data-group', '1'], ['data-user', '2'], ['data-group', '3']]}                                          | ${'approval'}        | ${/grouppath1[^]*,[^]*username2[^]*and[^]*grouppath3[^]/}
    ${1}              | ${createRequiredApprovers(5)} | ${[['data-group', '1'], ['data-user', '2'], ['data-group', '3'], ['data-user', '4'], ['data-group', '5']]} | ${'approval'}        | ${/grouppath1[^]*,[^]*username2[^]*,[^]*grouppath3[^]*and 2 more/}
  `(
    'with $approvalsRequired approval required and $approvers.length approvers',
    ({
      approvalsRequired,
      approvers,
      expectedAttributes,
      expectedApprovalText,
      expectedApproverText,
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
          expect(link.classes()).toStrictEqual(expectedClasses);
        });
      });

      it('renders link with proper attributes for all approvers', () => {
        findLinks().wrappers.forEach((link, index) => {
          const expectedAttribute = expectedAttributes[index][0];
          const expectedValue = expectedAttributes[index][1];
          expect(link.attributes(expectedAttribute)).toBe(expectedValue);
        });
      });
    },
  );
});
