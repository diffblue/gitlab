import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import ApproversList from 'ee/approvals/components/approvers_list.vue';
import ApproversSelect from 'ee/approvals/components/approvers_select.vue';
import RuleForm, { READONLY_NAMES } from 'ee/approvals/components/rule_form.vue';
import { TYPE_USER, TYPE_GROUP, TYPE_HIDDEN_GROUPS } from 'ee/approvals/constants';
import { createStoreOptions } from 'ee/approvals/stores';
import projectSettingsModule from 'ee/approvals/stores/modules/project_settings';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  ALL_BRANCHES,
  ALL_PROTECTED_BRANCHES,
} from 'ee/vue_shared/components/branches_selector/constants';
import {
  TEST_RULE,
  TEST_PROTECTED_BRANCHES,
  TEST_RULE_WITH_PROTECTED_BRANCHES,
  TEST_RULE_WITH_ALL_BRANCHES,
  TEST_RULE_WITH_ALL_PROTECTED_BRANCHES,
} from '../mocks';

const TEST_PROJECT_ID = '7';
const TEST_APPROVERS = [{ id: 7, type: TYPE_USER }];
const TEST_APPROVALS_REQUIRED = 3;
const TEST_FALLBACK_RULE = {
  approvalsRequired: 1,
  isFallback: true,
};
const TEST_LOCKED_RULE_NAME = 'LOCKED_RULE';
const nameTakenError = {
  response: {
    data: {
      message: {
        name: ['has already been taken'],
      },
    },
  },
};

Vue.use(Vuex);

const addType = (type) => (x) => Object.assign(x, { type });

describe('EE Approvals RuleForm', () => {
  let wrapper;
  let store;
  let actions;

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(RuleForm, {
        propsData: props,
        store: new Vuex.Store(store),
        stubs: {
          GlFormGroup: stubComponent(GlFormGroup, {
            props: ['state', 'invalidFeedback'],
          }),
          GlFormInput: stubComponent(GlFormInput, {
            props: ['state', 'disabled', 'value'],
            template: `<input />`,
          }),
          BranchesSelect: stubComponent(ProtectedBranchesSelector),
        },
      }),
    );
  };

  const findForm = () => wrapper.find('form');
  const findNameInput = () => wrapper.findByTestId('name');
  const findNameValidation = () => wrapper.findByTestId('name-group');
  const findApprovalsRequiredInput = () => wrapper.findByTestId('approvals-required');
  const findApprovalsRequiredValidation = () => wrapper.findByTestId('approvals-required-group');
  const findApproversSelect = () => wrapper.findComponent(ApproversSelect);
  const findApproversValidation = () => wrapper.findByTestId('approvers-group');
  const findApproversList = () => wrapper.findComponent(ApproversList);
  const findProtectedBranchesSelector = () => wrapper.findComponent(ProtectedBranchesSelector);
  const findBranchesValidation = () => wrapper.findByTestId('branches-group');

  const inputsAreValid = (inputs) => inputs.every((x) => x.props('state'));

  const findValidations = () => [
    findNameValidation(),
    findApprovalsRequiredValidation(),
    findApproversValidation(),
  ];

  const findValidationsWithBranch = () => [
    findNameValidation(),
    findApprovalsRequiredValidation(),
    findApproversValidation(),
    findBranchesValidation(),
  ];

  beforeEach(() => {
    store = createStoreOptions(
      { approvals: projectSettingsModule() },
      { projectId: TEST_PROJECT_ID },
    );

    ['postRule', 'putRule', 'deleteRule', 'putFallbackRule'].forEach((actionName) => {
      jest.spyOn(store.modules.approvals.actions, actionName).mockImplementation(() => {});
    });

    ({ actions } = store.modules.approvals);
  });

  describe('when allow multiple rules', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = true;
    });

    describe('when has protected branch feature', () => {
      describe('with initial rule', () => {
        it('on load, it populates initial protected branch ids', () => {
          createComponent({
            isMrEdit: false,
            initRule: TEST_RULE_WITH_PROTECTED_BRANCHES,
          });

          expect(findProtectedBranchesSelector().props('selectedBranches')).toStrictEqual(
            TEST_PROTECTED_BRANCHES,
          );
        });
      });

      describe('with initial all branches rule', () => {
        it('on load, it populates initial protected branch ids', () => {
          createComponent({
            isMrEdit: false,
            initRule: TEST_RULE_WITH_ALL_BRANCHES,
          });

          expect(findProtectedBranchesSelector().props('selectedBranches')).toStrictEqual([
            ALL_BRANCHES,
          ]);
        });
      });

      describe('with initial all protected branches rule', () => {
        beforeEach(() => {
          store.state.settings.allowAllProtectedBranchesOption = true;
        });

        it('on load, it populates initial protected branch ids', () => {
          createComponent({
            isMrEdit: false,
            initRule: TEST_RULE_WITH_ALL_PROTECTED_BRANCHES,
          });

          expect(findProtectedBranchesSelector().props('allowAllProtectedBranchesOption')).toBe(
            true,
          );
          expect(findProtectedBranchesSelector().props('selectedBranches')).toStrictEqual([
            ALL_PROTECTED_BRANCHES,
          ]);
        });
      });

      describe('without initRule', () => {
        const users = [1, 2];
        const groups = [2, 3];
        const userRecords = users.map((id) => ({ id, type: TYPE_USER }));
        const groupRecords = groups.map((id) => ({ id, type: TYPE_GROUP }));
        const ruleData = (attributes = {}) => ({
          id: null,
          name: 'Lorem',
          approvalsRequired: 2,
          users,
          groups,
          userRecords,
          groupRecords,
          removeHiddenGroups: false,
          protectedBranchIds: [],
          appliesToAllProtectedBranches: false,
          ...attributes,
        });

        beforeEach(() => {
          store.state.settings.protectedBranches = TEST_PROTECTED_BRANCHES;
        });

        it('at first, shows no validation', () => {
          createComponent({
            isMrEdit: false,
          });

          expect(inputsAreValid(findValidationsWithBranch())).toBe(true);
        });

        it('on submit, shows branches validation', async () => {
          createComponent({
            isMrEdit: false,
          });

          await findProtectedBranchesSelector().vm.$emit('input', '3');
          await findForm().trigger('submit');
          await nextTick();

          const branchesGroup = findBranchesValidation();
          expect(branchesGroup.props('state')).toBe(false);
          expect(branchesGroup.props('invalidFeedback')).toBe(
            'Please select a valid target branch',
          );
        });

        it('on submit with data, posts rule', async () => {
          createComponent({
            isMrEdit: false,
          });

          const branches = [TEST_PROTECTED_BRANCHES[0]];
          const expected = ruleData({ protectedBranchIds: branches.map((x) => x.id) });

          await findNameInput().vm.$emit('input', expected.name);
          await findApprovalsRequiredInput().vm.$emit('input', expected.approvalsRequired);
          await findApproversList().vm.$emit('input', [...groupRecords, ...userRecords]);
          await findProtectedBranchesSelector().vm.$emit('input', branches[0]);
          await findForm().trigger('submit');

          expect(actions.postRule).toHaveBeenCalledWith(expect.anything(), expected);
        });

        it('on submit with all branches, posts rule', async () => {
          createComponent({
            isMrEdit: false,
          });

          const expected = ruleData();

          await findNameInput().vm.$emit('input', expected.name);
          await findApprovalsRequiredInput().vm.$emit('input', expected.approvalsRequired);
          await findApproversList().vm.$emit('input', [...groupRecords, ...userRecords]);
          await findProtectedBranchesSelector().vm.$emit('input', ALL_BRANCHES);
          await findForm().trigger('submit');

          expect(actions.postRule).toHaveBeenCalledWith(expect.anything(), expected);
        });

        describe('with all protected branches allowed', () => {
          beforeEach(() => {
            store.state.settings.allowAllProtectedBranchesOption = true;
          });

          it('on submit with all protected branches, posts rule', async () => {
            createComponent({
              isMrEdit: false,
            });

            const expected = ruleData({ appliesToAllProtectedBranches: true });

            await findNameInput().vm.$emit('input', expected.name);
            await findApprovalsRequiredInput().vm.$emit('input', expected.approvalsRequired);
            await findApproversList().vm.$emit('input', [...groupRecords, ...userRecords]);
            await findProtectedBranchesSelector().vm.$emit('input', ALL_PROTECTED_BRANCHES);
            await findForm().trigger('submit');

            expect(actions.postRule).toHaveBeenCalledWith(expect.anything(), expected);
          });
        });
      });
    });

    describe('without initRule', () => {
      beforeEach(() => {
        createComponent({ isMrEdit: false });
      });

      it('at first, shows no validation', () => {
        expect(inputsAreValid(findValidationsWithBranch())).toBe(true);
      });

      it('on submit, does not dispatch action', async () => {
        await findForm().trigger('submit');

        expect(actions.postRule).not.toHaveBeenCalled();
      });

      it('on submit, shows name validation', async () => {
        findNameInput().setValue('');

        await findForm().trigger('submit');
        await nextTick();

        const nameGroup = findNameValidation();
        expect(nameGroup.props('state')).toBe(false);
        expect(nameGroup.props('invalidFeedback')).toBe('Please provide a name');
      });

      it('on submit, shows approvalsRequired validation', async () => {
        await findApprovalsRequiredInput().vm.$emit('input', -1);
        await findForm().trigger('submit');
        await nextTick();

        const approvalsRequiredGroup = findApprovalsRequiredValidation();
        expect(approvalsRequiredGroup.props('state')).toBe(false);
        expect(approvalsRequiredGroup.props('invalidFeedback')).toBe(
          'Please enter a non-negative number',
        );
      });

      it('on submit, shows approvers validation', async () => {
        await findApproversList().vm.$emit('input', []);
        await findForm().trigger('submit');
        await nextTick();

        const approversGroup = findApproversValidation();
        expect(approversGroup.props('state')).toBe(false);
        expect(approversGroup.props('invalidFeedback')).toBe('Please select and add a member');
      });

      describe('with valid data', () => {
        const users = [1, 2];
        const groups = [2, 3];
        const userRecords = users.map((id) => ({ id, type: TYPE_USER }));
        const groupRecords = groups.map((id) => ({ id, type: TYPE_GROUP }));
        const branches = [TEST_PROTECTED_BRANCHES[0]];
        const expected = {
          id: null,
          name: 'Lorem',
          approvalsRequired: 2,
          users,
          groups,
          userRecords,
          groupRecords,
          removeHiddenGroups: false,
          protectedBranchIds: branches.map((x) => x.id),
          appliesToAllProtectedBranches: false,
        };

        beforeEach(async () => {
          await findNameInput().vm.$emit('input', expected.name);
          await findApprovalsRequiredInput().vm.$emit('input', expected.approvalsRequired);
          await findApproversList().vm.$emit('input', [...groupRecords, ...userRecords]);
          await findProtectedBranchesSelector().vm.$emit('input', branches[0]);
        });

        it('on submit, posts rule', async () => {
          await findForm().trigger('submit');

          expect(actions.postRule).toHaveBeenCalledWith(expect.anything(), expected);
        });

        it('when submitted with a duplicate name, shows the "taken name" validation', async () => {
          store.state.settings.prefix = 'project-settings';
          actions.postRule.mockRejectedValueOnce(nameTakenError);

          await findForm().trigger('submit');
          await nextTick();
          // We have to wait for two ticks because the promise needs to resolve
          // AND the result has to update into the UI
          await nextTick();

          const nameGroup = findNameValidation();
          expect(nameGroup.props('state')).toBe(false);
          expect(nameGroup.props('invalidFeedback')).toBe('Rule name is already taken.');
        });
      });

      it('adds selected approvers on selection', async () => {
        const orig = [{ id: 7, type: TYPE_GROUP }];
        const selected = [{ id: 2, type: TYPE_USER }];
        const expected = [...orig, ...selected];

        await findApproversSelect().vm.$emit('input', orig);
        await findApproversSelect().vm.$emit('input', selected);

        expect(findApproversList().props('value')).toEqual(expected);
      });
    });

    describe('with initRule', () => {
      beforeEach(() => {
        createComponent({
          initRule: TEST_RULE,
          isMrEdit: false,
        });
      });

      it('does not disable the name text field', () => {
        expect(findNameInput().attributes('disabled')).toBe(undefined);
      });

      it('shows approvers', () => {
        const list = findApproversList();

        expect(list.props('value')).toEqual([
          ...TEST_RULE.groups.map(addType(TYPE_GROUP)),
          ...TEST_RULE.users.map(addType(TYPE_USER)),
        ]);
      });

      describe('with valid data', () => {
        const userRecords = TEST_RULE.users.map((x) => ({ ...x, type: TYPE_USER }));
        const groupRecords = TEST_RULE.groups.map((x) => ({ ...x, type: TYPE_GROUP }));
        const users = userRecords.map((x) => x.id);
        const groups = groupRecords.map((x) => x.id);

        const expected = {
          ...TEST_RULE,
          users,
          groups,
          userRecords,
          groupRecords,
          removeHiddenGroups: false,
          protectedBranchIds: [],
          appliesToAllProtectedBranches: false,
        };

        it('on submit, puts rule', async () => {
          await findForm().trigger('submit');

          expect(actions.putRule).toHaveBeenCalledWith(expect.anything(), expected);
        });

        it('when submitted with a duplicate name, shows the "taken name" validation', async () => {
          store.state.settings.prefix = 'project-settings';
          actions.putRule.mockRejectedValueOnce(nameTakenError);

          await findForm().trigger('submit');
          await waitForPromises();

          const nameGroup = findNameValidation();
          expect(nameGroup.props('state')).toBe(false);
          expect(nameGroup.props('invalidFeedback')).toBe('Rule name is already taken.');
        });
      });
    });

    describe('with init fallback rule', () => {
      beforeEach(() => {
        createComponent({
          initRule: TEST_FALLBACK_RULE,
        });

        findNameInput().vm.$emit('input', '');
        findApprovalsRequiredInput().vm.$emit('input', TEST_APPROVALS_REQUIRED);
        findApproversList().vm.$emit('input', []);
      });

      describe('with empty name and empty approvers', () => {
        beforeEach(() => {
          findForm().trigger('submit');
        });

        it('does not post rule', () => {
          expect(actions.postRule).not.toHaveBeenCalled();
        });

        it('puts fallback rule', () => {
          expect(actions.putFallbackRule).toHaveBeenCalledWith(expect.anything(), {
            approvalsRequired: TEST_APPROVALS_REQUIRED,
          });
        });

        it('does not show any validation errors', () => {
          expect(inputsAreValid(findValidations())).toBe(true);
        });
      });

      describe('with name and empty approvers', () => {
        beforeEach(() => {
          findNameInput().vm.$emit('input', 'Lorem');
          findForm().trigger('submit');
        });

        it('does not put fallback rule', () => {
          expect(actions.putFallbackRule).not.toHaveBeenCalled();
        });

        it('shows approvers validation error', () => {
          expect(findApproversValidation().props('state')).toBe(false);
        });
      });

      describe('with empty name and approvers', () => {
        beforeEach(() => {
          findApproversList().vm.$emit('input', TEST_APPROVERS);
          findForm().trigger('submit');
        });

        it('does not put fallback rule', () => {
          expect(actions.putFallbackRule).not.toHaveBeenCalled();
        });

        it('shows name validation error', () => {
          expect(findNameValidation().props('state')).toBe(false);
        });
      });

      describe('with name and approvers', () => {
        beforeEach(() => {
          findApproversList().vm.$emit('input', [{ id: 7, type: TYPE_USER }]);
          findNameInput().vm.$emit('input', 'Lorem');
          findForm().trigger('submit');
        });

        it('does not put fallback rule', () => {
          expect(actions.putFallbackRule).not.toHaveBeenCalled();
        });

        it('posts new rule', () => {
          expect(actions.postRule).toHaveBeenCalled();
        });
      });
    });

    describe('with hidden groups rule', () => {
      beforeEach(() => {
        createComponent({
          initRule: {
            ...TEST_RULE,
            containsHiddenGroups: true,
          },
        });
      });

      it('shows approvers and hidden group', () => {
        const list = findApproversList();

        expect(list.props('value')).toEqual([
          ...TEST_RULE.groups.map(addType(TYPE_GROUP)),
          ...TEST_RULE.users.map(addType(TYPE_USER)),
          { type: TYPE_HIDDEN_GROUPS },
        ]);
      });

      it('on submit, does not remove hidden groups', async () => {
        await findForm().trigger('submit');

        expect(actions.putRule).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({
            removeHiddenGroups: false,
          }),
        );
      });

      describe('and hidden groups removed', () => {
        beforeEach(() => {
          findApproversList().vm.$emit(
            'input',
            findApproversList()
              .props('value')
              .filter((x) => x.type !== TYPE_HIDDEN_GROUPS),
          );
        });

        it('on submit, removes hidden groups', async () => {
          await findForm().trigger('submit');

          expect(actions.putRule).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({
              removeHiddenGroups: true,
            }),
          );
        });
      });
    });

    describe('with removed hidden groups rule', () => {
      beforeEach(() => {
        createComponent({
          initRule: {
            ...TEST_RULE,
            containsHiddenGroups: true,
            removeHiddenGroups: true,
          },
        });
      });

      it('does not add hidden groups in approvers', () => {
        expect(
          findApproversList()
            .props('value')
            .every((x) => x.type !== TYPE_HIDDEN_GROUPS),
        ).toBe(true);
      });
    });

    describe('with approval suggestions', () => {
      describe.each`
        defaultRuleName     | expectedDisabledAttribute
        ${'Coverage-Check'} | ${true}
        ${'Foo Bar Baz'}    | ${false}
      `(
        'with defaultRuleName set to $defaultRuleName',
        ({ defaultRuleName, expectedDisabledAttribute }) => {
          beforeEach(() => {
            createComponent({
              initRule: null,
              isMrEdit: false,
              defaultRuleName,
            });
          });

          it(`it ${
            expectedDisabledAttribute ? 'disables' : 'does not disable'
          } the name text field`, () => {
            expect(findNameInput().props('disabled')).toBe(expectedDisabledAttribute);
          });
        },
      );
    });

    describe('with read-only rule name', () => {
      describe.each(READONLY_NAMES)('with new %s rule', (ruleName) => {
        beforeEach(() => {
          createComponent({
            initRule: { ...TEST_RULE, id: null, name: ruleName },
          });
        });

        it('does not disable the name text field', () => {
          expect(findNameInput().props('disabled')).toBe(false);
        });
      });

      describe.each(READONLY_NAMES)('with editing the %s rule', (ruleName) => {
        beforeEach(() => {
          createComponent({
            initRule: { ...TEST_RULE, name: ruleName },
          });
        });

        it('disables the name text field', () => {
          expect(findNameInput().props('disabled')).toBe(true);
        });
      });
    });
  });

  describe('when allow only single rule', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = false;
    });

    describe('with locked rule name', () => {
      beforeEach(() => {
        store.state.settings.lockedApprovalsRuleName = TEST_LOCKED_RULE_NAME;
        createComponent();
      });

      it('does not render the approval-rule name input', () => {
        expect(findNameInput().exists()).toBe(false);
      });
    });

    describe.each`
      lockedRuleName           | expectedNameSubmitted
      ${TEST_LOCKED_RULE_NAME} | ${TEST_LOCKED_RULE_NAME}
      ${null}                  | ${'Default'}
    `('with no init rule', ({ lockedRuleName, expectedNameSubmitted }) => {
      beforeEach(() => {
        store.state.settings.lockedApprovalsRuleName = lockedRuleName;
        createComponent();
        findApprovalsRequiredInput().vm.$emit('input', TEST_APPROVALS_REQUIRED);
      });

      describe('with approvers selected', () => {
        beforeEach(() => {
          findApproversList().vm.$emit('input', TEST_APPROVERS);
          findForm().trigger('submit');
        });

        it('posts new rule', () => {
          expect(actions.postRule).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({
              name: expectedNameSubmitted,
              approvalsRequired: TEST_APPROVALS_REQUIRED,
              users: TEST_APPROVERS.map((x) => x.id),
            }),
          );
        });
      });

      describe('without approvers', () => {
        beforeEach(() => {
          findForm().trigger('submit');
        });

        it('puts fallback rule', () => {
          expect(actions.putFallbackRule).toHaveBeenCalledWith(expect.anything(), {
            approvalsRequired: TEST_APPROVALS_REQUIRED,
          });
        });
      });
    });

    describe.each`
      lockedRuleName           | inputName | expectedNameSubmitted
      ${TEST_LOCKED_RULE_NAME} | ${'Foo'}  | ${TEST_LOCKED_RULE_NAME}
      ${null}                  | ${'Foo'}  | ${'Foo'}
    `('with init rule', ({ lockedRuleName, inputName, expectedNameSubmitted }) => {
      beforeEach(() => {
        store.state.settings.lockedApprovalsRuleName = lockedRuleName;
      });

      describe('with empty name and empty approvers', () => {
        beforeEach(() => {
          createComponent({
            initRule: { ...TEST_RULE, name: '' },
          });
          findApprovalsRequiredInput().vm.$emit('input', TEST_APPROVALS_REQUIRED);
          findApproversList().vm.$emit('input', []);

          findForm().trigger('submit');
        });

        it('deletes rule', () => {
          expect(actions.deleteRule).toHaveBeenCalledWith(expect.anything(), TEST_RULE.id);
        });

        it('puts fallback rule', () => {
          expect(actions.putFallbackRule).toHaveBeenCalledWith(expect.anything(), {
            approvalsRequired: TEST_APPROVALS_REQUIRED,
          });
        });
      });

      describe('with name and approvers', () => {
        beforeEach(() => {
          createComponent({
            initRule: { ...TEST_RULE, name: inputName },
          });
          findApprovalsRequiredInput().vm.$emit('input', TEST_APPROVALS_REQUIRED);
          findApproversList().vm.$emit('input', TEST_APPROVERS);

          findForm().trigger('submit');
        });

        it('puts rule', () => {
          expect(actions.putRule).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({
              id: TEST_RULE.id,
              name: expectedNameSubmitted,
              approvalsRequired: TEST_APPROVALS_REQUIRED,
              users: TEST_APPROVERS.map((x) => x.id),
            }),
          );
        });
      });
    });
  });
});
