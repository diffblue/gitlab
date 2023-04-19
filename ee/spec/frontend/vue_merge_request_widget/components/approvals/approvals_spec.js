import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlSprintf } from '@gitlab/ui';
import approvedByCurrentUser from 'test_fixtures/graphql/merge_requests/approvals/approvals.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import Approvals from 'ee/vue_merge_request_widget/components/approvals/approvals.vue';
import ApprovalsAuth from 'ee/vue_merge_request_widget/components/approvals/approvals_auth.vue';
import ApprovalsFoss from '~/vue_merge_request_widget/components/approvals/approvals.vue';
import { APPROVE_ERROR } from '~/vue_merge_request_widget/components/approvals/messages';
import eventHub from '~/vue_merge_request_widget/event_hub';
import approvedByQuery from 'ee/vue_merge_request_widget/components/approvals/queries/approvals.query.graphql';
import { createCanApproveResponse } from 'jest/approvals/mock_data';

Vue.use(VueApollo);

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

const INVALID_TEST_RULE = {
  id: 1,
  type: 'REPORT_APPROVER',
  approved: true,
  approvalsRequired: 1,
  name: 'test_rule',
  invalid: true,
  allowMergeWhenInvalid: true,
};
const TEST_HELP_PATH = 'help/path';
const TEST_PASSWORD = 'password';
const testApprovedBy = () => [1, 7, 10].map((id) => ({ id }));
const testApprovals = () => ({
  approved: false,
  approved_by: testApprovedBy().map((user) => ({ user })),
  approval_rules_left: [],
  approvals_left: 4,
  suggested_approvers: [],
  user_can_approve: true,
  user_has_approved: true,
  require_password_to_approve: false,
  invalid_approvers_rules: [],
});

describe('MRWidget approvals', () => {
  let wrapper;
  let service;
  let mr;

  const createComponent = (props = {}, response = approvedByCurrentUser) => {
    const requestHandlers = [[approvedByQuery, jest.fn().mockResolvedValue(response)]];
    const apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountExtended(Approvals, {
      apolloProvider,
      propsData: {
        mr,
        service,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findAction = () => wrapper.findComponent(GlButton);
  const findActionData = () => {
    const action = findAction();

    return !action.exists()
      ? null
      : {
          variant: action.props('variant'),
          category: action.props('category'),
          text: action.text(),
        };
  };
  const findInvalidRules = () => wrapper.findByTestId('invalid-rules');

  beforeEach(() => {
    service = {
      ...{
        approveMergeRequest: jest.fn().mockReturnValue(Promise.resolve(testApprovals())),
        unapproveMergeRequest: jest.fn().mockReturnValue(Promise.resolve(testApprovals())),
        approveMergeRequestWithAuth: jest.fn().mockReturnValue(Promise.resolve(testApprovals())),
      },
    };
    mr = {
      ...{
        setApprovals: jest.fn(),
        setApprovalRules: jest.fn(),
      },
      approvalsHelpPath: TEST_HELP_PATH,
      approvals: testApprovals(),
      approvalRules: [],
      isOpen: true,
      state: 'open',
      targetProjectFullPath: 'gitlab-org/gitlab',
      iid: '1',
    };

    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

    gon.current_user_id = getIdFromGraphQLId(
      approvedByCurrentUser.data.project.mergeRequest.approvedBy.nodes[0].id,
    );
  });

  describe('action button', () => {
    describe('when user can approve', () => {
      let canApproveResponse;

      beforeEach(() => {
        canApproveResponse = createCanApproveResponse();
      });

      describe('and MR is approved', () => {
        beforeEach(() => {
          canApproveResponse.data.project.mergeRequest.approved = true;
        });

        describe('with no approvers', () => {
          beforeEach(async () => {
            canApproveResponse.data.project.mergeRequest.approvedBy.nodes = [];
            createComponent({}, canApproveResponse);
            await nextTick();
          });

          it('approve action (with inverted style) is rendered', () => {
            expect(findActionData()).toEqual({
              variant: 'confirm',
              text: 'Approve',
              category: 'secondary',
            });
          });
        });
      });

      describe('when approve action is clicked', () => {
        describe('when project requires password to approve', () => {
          beforeEach(async () => {
            mr.requirePasswordToApprove = true;
            createComponent({}, canApproveResponse);
            await waitForPromises();
          });

          describe('when approve is clicked', () => {
            beforeEach(async () => {
              findAction().vm.$emit('click');

              await nextTick();
            });

            describe('when emits approve', () => {
              const findApprovalsAuth = () => wrapper.findComponent(ApprovalsAuth);

              beforeEach(async () => {
                jest.spyOn(service, 'approveMergeRequestWithAuth').mockRejectedValue();
                jest.spyOn(service, 'approveMergeRequest').mockReturnValue(new Promise(() => {}));

                findApprovalsAuth().vm.$emit('approve', TEST_PASSWORD);

                await nextTick();
              });

              it('calls service when emits approve', () => {
                expect(service.approveMergeRequestWithAuth).toHaveBeenCalledWith(TEST_PASSWORD);
              });

              it('sets isApproving', async () => {
                wrapper.findComponent(ApprovalsFoss).setData({ isApproving: true });

                await nextTick();
                expect(findApprovalsAuth().props('isApproving')).toBe(true);
              });

              it('sets hasError when auth fails', async () => {
                wrapper.findComponent(ApprovalsFoss).setData({ hasApprovalAuthError: true });

                await nextTick();
                expect(findApprovalsAuth().props('hasError')).toBe(true);
              });

              it('shows alert if general error', () => {
                expect(createAlert).toHaveBeenCalledWith({ message: APPROVE_ERROR });
              });
            });
          });
        });
      });
    });
  });

  describe('footer', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('opens footer when toggle is clicked', async () => {
      wrapper.findByTestId('widget-toggle').vm.$emit('click');

      await nextTick();

      expect(wrapper.findByTestId('approvals-footer').exists()).toBe(true);
    });
  });

  describe('invalid rules', () => {
    beforeEach(() => {
      mr.mergeRequestApproversAvailable = true;
    });

    it('does not render related components', async () => {
      createComponent();

      await waitForPromises();

      expect(findInvalidRules().exists()).toBe(false);
    });

    describe('when invalid rules are present', () => {
      it.each`
        allowMergeWhenInvalidList | expectedText
        ${[true]}                 | ${'1 invalid rule has been approved automatically.'}
        ${[true, true]}           | ${'2 invalid rules have been approved automatically.'}
        ${[false]}                | ${"1 rule can't be approved."}
        ${[false, false]}         | ${"2 rules can't be approved."}
        ${[true, true, false]}    | ${"1 rule can't be approved, 2 invalid rules have been approved automatically."}
        ${[true, false, false]}   | ${"2 rules can't be approved, 1 invalid rule has been approved automatically."}
      `(
        'renders related components ($allowMergeWhenInvalid, $expectedText)',
        async ({ allowMergeWhenInvalidList, expectedText }) => {
          const response = JSON.parse(JSON.stringify(approvedByCurrentUser));
          response.data.project.mergeRequest.approvalState.rules = allowMergeWhenInvalidList.map(
            (allowMergeWhenInvalid, idx) => ({
              ...INVALID_TEST_RULE,
              id: idx,
              allowMergeWhenInvalid,
            }),
          );
          createComponent({}, response);

          await waitForPromises();

          const invalidRules = findInvalidRules();

          expect(invalidRules.exists()).toBe(true);

          const invalidRulesText = invalidRules.text();

          expect(invalidRulesText).toContain(expectedText);
        },
      );
    });
  });
});
