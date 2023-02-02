import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Approvals from 'ee/vue_merge_request_widget/components/approvals/approvals.vue';
import ApprovalsAuth from 'ee/vue_merge_request_widget/components/approvals/approvals_auth.vue';
import ApprovalsFooter from 'ee/vue_merge_request_widget/components/approvals/approvals_footer.vue';
import { createAlert } from '~/flash';
import ApprovalsFoss from '~/vue_merge_request_widget/components/approvals/approvals.vue';
import ApprovalsSummary from '~/vue_merge_request_widget/components/approvals/approvals_summary.vue';
import ApprovalsSummaryOptional from '~/vue_merge_request_widget/components/approvals/approvals_summary_optional.vue';

import {
  FETCH_LOADING,
  FETCH_ERROR,
  APPROVE_ERROR,
  UNAPPROVE_ERROR,
} from '~/vue_merge_request_widget/components/approvals/messages';
import MrWidgetContainer from '~/vue_merge_request_widget/components/mr_widget_container.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';

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
const testApprovalRulesResponse = () => ({ rules: [{ id: 2 }] });

jest.mock('~/flash');

describe('EE MRWidget approvals', () => {
  let wrapper;
  let service;
  let mr;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(Approvals, {
      propsData: {
        mr,
        service,
        ...props,
      },
      stubs: {
        approvals: ApprovalsFoss,
        MrWidgetContainer,
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
  const findSummary = () => wrapper.findComponent(ApprovalsSummary);
  const findOptionalSummary = () => wrapper.findComponent(ApprovalsSummaryOptional);
  const findFooter = () => wrapper.findComponent(ApprovalsFooter);

  beforeEach(() => {
    service = {
      ...{
        fetchApprovals: jest.fn().mockResolvedValue(testApprovals()),
        fetchApprovalSettings: jest.fn().mockResolvedValue(testApprovalRulesResponse()),
        approveMergeRequest: jest.fn().mockResolvedValue(testApprovals()),
        unapproveMergeRequest: jest.fn().mockResolvedValue(testApprovals()),
        approveMergeRequestWithAuth: jest.fn().mockResolvedValue(testApprovals()),
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
      approvalsWidgetType: 'full',
      targetProjectFullPath: 'gitlab-org/gitlab',
      iid: '1',
    };

    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when created', () => {
    beforeEach(() => {
      jest.spyOn(service, 'fetchApprovals').mockResolvedValue(testApprovals());
      createComponent();
    });

    it('shows loading message', async () => {
      wrapper.findComponent(ApprovalsFoss).setData({ fetchingApprovals: true });

      await nextTick();
      expect(wrapper.text()).toContain(FETCH_LOADING);
    });

    it('fetches approvals', () => {
      expect(service.fetchApprovals).toHaveBeenCalled();
    });
  });

  describe('when fetch approvals success', () => {
    beforeEach(async () => {
      jest.spyOn(service, 'fetchApprovals').mockResolvedValue();
      createComponent();

      await nextTick();
    });

    it('hides loading message', () => {
      expect(createAlert).not.toHaveBeenCalled();
      expect(wrapper.text()).not.toContain(FETCH_LOADING);
    });
  });

  describe('when fetch approvals error', () => {
    beforeEach(async () => {
      jest.spyOn(service, 'fetchApprovals').mockRejectedValue();
      createComponent();

      await nextTick();
    });

    it('still shows loading message', () => {
      expect(wrapper.text()).toContain(FETCH_LOADING);
    });

    it('flashes error', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: FETCH_ERROR });
    });
  });

  describe('action button', () => {
    beforeEach(() => {
      jest.spyOn(service, 'fetchApprovals').mockResolvedValue(testApprovals());
    });

    describe('when mr is closed', () => {
      beforeEach(async () => {
        mr.isOpen = false;
        mr.approvals.user_has_approved = false;
        mr.approvals.user_can_approve = true;

        createComponent();

        await nextTick();
      });

      it('action is not rendered', () => {
        expect(findActionData()).toBe(null);
      });
    });

    describe('when user cannot approve', () => {
      beforeEach(async () => {
        mr.approvals.user_has_approved = false;
        mr.approvals.user_can_approve = false;

        createComponent();

        await nextTick();
      });

      it('action is not rendered', () => {
        expect(findActionData()).toBe(null);
      });
    });

    describe('when user can approve', () => {
      beforeEach(() => {
        mr.approvals.user_has_approved = false;
        mr.approvals.user_can_approve = true;
      });

      describe('and MR is unapproved', () => {
        beforeEach(async () => {
          createComponent();

          await nextTick();
        });

        it('approve action is rendered', () => {
          expect(findActionData()).toEqual({
            variant: 'confirm',
            text: 'Approve',
            category: 'primary',
          });
        });
      });

      describe('and MR is approved', () => {
        beforeEach(() => {
          mr.approvals.approved = true;
        });

        describe('with no approvers', () => {
          beforeEach(async () => {
            mr.approvals.approved_by = [];
            createComponent();

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

        describe('with approvers', () => {
          beforeEach(async () => {
            mr.approvals.approved_by = [{ user: { id: 7 } }];
            createComponent();

            await nextTick();
          });

          it('approve additionally action is rendered', () => {
            expect(findActionData()).toEqual({
              variant: 'confirm',
              text: 'Approve additionally',
              category: 'secondary',
            });
          });
        });
      });

      describe('when approve action is clicked', () => {
        beforeEach(async () => {
          createComponent();

          await nextTick();
        });

        it('shows loading icon', async () => {
          jest.spyOn(service, 'approveMergeRequest').mockReturnValue(new Promise(() => {}));
          const action = findAction();

          expect(action.props('loading')).toBe(false);

          action.vm.$emit('click');

          await nextTick();
          expect(action.props('loading')).toBe(true);
        });

        describe('and after loading', () => {
          beforeEach(async () => {
            findAction().vm.$emit('click');

            await nextTick();
          });

          it('calls service approve', () => {
            expect(service.approveMergeRequest).toHaveBeenCalled();
          });

          it('emits to eventHub', () => {
            expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
          });

          it('calls store setApprovals', () => {
            expect(mr.setApprovals).toHaveBeenCalledWith(testApprovals());
          });

          it('refetches the rules', () => {
            expect(service.fetchApprovalSettings).toHaveBeenCalled();
          });
        });

        describe('and error', () => {
          beforeEach(async () => {
            jest.spyOn(service, 'approveMergeRequest').mockRejectedValue();
            findAction().vm.$emit('click');

            await nextTick();
          });

          it('flashes error message', () => {
            expect(createAlert).toHaveBeenCalledWith({ message: APPROVE_ERROR });
          });
        });
      });

      describe('when project requires password to approve', () => {
        beforeEach(async () => {
          mr.approvals.require_password_to_approve = true;
          createComponent();

          await nextTick();
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

            it('shows flash if general error', () => {
              expect(createAlert).toHaveBeenCalledWith({ message: APPROVE_ERROR });
            });
          });
        });
      });
    });

    describe('when user has approved', () => {
      beforeEach(async () => {
        mr.approvals.user_has_approved = true;
        mr.approvals.user_can_approve = false;

        createComponent();

        await nextTick();
      });

      it('revoke action is rendered', () => {
        expect(findActionData()).toEqual({
          category: 'primary',
          variant: 'default',
          text: 'Revoke approval',
        });
      });

      describe('when revoke action is clicked', () => {
        describe('and successful', () => {
          beforeEach(async () => {
            findAction().vm.$emit('click');

            await nextTick();
          });

          it('calls service unapprove', () => {
            expect(service.unapproveMergeRequest).toHaveBeenCalled();
          });

          it('emits to eventHub', () => {
            expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
          });

          it('calls store setApprovals', () => {
            expect(mr.setApprovals).toHaveBeenCalledWith(testApprovals());
          });

          it('refetches the rules', () => {
            expect(service.fetchApprovalSettings).toHaveBeenCalled();
          });
        });

        describe('and error', () => {
          beforeEach(async () => {
            jest.spyOn(service, 'unapproveMergeRequest').mockRejectedValue();
            findAction().vm.$emit('click');

            await nextTick();
          });

          it('flashes error message', () => {
            expect(createAlert).toHaveBeenCalledWith({ message: UNAPPROVE_ERROR });
          });
        });
      });
    });
  });

  describe('approvals optional summary', () => {
    describe('when no approvals required and no approvers', () => {
      beforeEach(() => {
        jest.spyOn(service, 'fetchApprovals').mockResolvedValue(testApprovals());
        mr.approvals.approved_by = [];
        mr.approvals.approvals_required = 0;
        mr.approvals.user_has_approved = false;
      });

      describe('and can approve', () => {
        beforeEach(async () => {
          mr.approvals.user_can_approve = true;

          createComponent();

          await nextTick();
        });

        it('is shown', () => {
          expect(findSummary().exists()).toBe(false);
          expect(findOptionalSummary().props()).toEqual({
            canApprove: true,
            helpPath: TEST_HELP_PATH,
          });
        });
      });

      describe('and cannot approve', () => {
        beforeEach(async () => {
          mr.approvals.user_can_approve = false;

          createComponent();

          await nextTick();
        });

        it('is shown', () => {
          expect(findSummary().exists()).toBe(false);
          expect(findOptionalSummary().props()).toEqual({
            canApprove: false,
            helpPath: TEST_HELP_PATH,
          });
        });
      });
    });
  });

  describe('approvals summary', () => {
    beforeEach(async () => {
      jest.spyOn(service, 'fetchApprovals').mockResolvedValue(testApprovals());
      createComponent();

      await nextTick();
    });

    it('is rendered with props', () => {
      const summary = findSummary();

      expect(findOptionalSummary().exists()).toBe(false);
      expect(summary.exists()).toBe(true);
      expect(summary.props()).toMatchObject({
        projectPath: 'gitlab-org/gitlab',
        iid: '1',
        updatedCount: 0,
      });
    });
  });

  describe('footer', () => {
    let footer;

    beforeEach(async () => {
      jest.spyOn(service, 'fetchApprovals').mockResolvedValue(testApprovals());
      createComponent();

      await nextTick();
    });

    beforeEach(() => {
      footer = findFooter();
    });

    it('is rendered with props', () => {
      expect(footer.exists()).toBe(true);
      expect(footer.props()).toMatchObject({
        value: false,
        suggestedApprovers: mr.approvals.suggested_approvers,
        approvalRules: mr.approvalRules,
        isLoadingRules: false,
      });
    });

    describe('when opened', () => {
      describe('and loading', () => {
        beforeEach(async () => {
          jest.spyOn(service, 'fetchApprovalSettings').mockReturnValue(new Promise(() => {}));
          footer.vm.$emit('input', true);

          await nextTick();
        });

        it('calls service fetch approval rules', () => {
          expect(service.fetchApprovalSettings).toHaveBeenCalled();
        });

        it('is loading rules', () => {
          expect(wrapper.vm.isLoadingRules).toBe(true);
          expect(footer.props('isLoadingRules')).toBe(true);
        });
      });

      describe('and finished loading', () => {
        beforeEach(async () => {
          footer.vm.$emit('input', true);

          await nextTick();
        });

        it('sets approval rules', () => {
          expect(mr.setApprovalRules).toHaveBeenCalledWith(testApprovalRulesResponse());
        });

        it('shows footer', () => {
          expect(footer.props('value')).toBe(true);
        });

        describe('and closed', () => {
          beforeEach(async () => {
            service.fetchApprovalSettings.mockClear();
            footer.vm.$emit('input', false);

            await nextTick();
          });

          it('does not call service fetch approval rules', () => {
            expect(service.fetchApprovalSettings).not.toHaveBeenCalled();
          });

          it('hides approval rules', () => {
            expect(footer.props('value')).toBe(false);
          });
        });
      });
    });
  });
});
