import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import MRRulesHiddenInputs from 'ee/approvals/components/mr_edit/mr_rules_hidden_inputs.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import MREditModule from 'ee/approvals/stores/modules/mr_edit';
import { createMRRule } from '../../mocks';

Vue.use(Vuex);

const {
  INPUT_ID,
  INPUT_SOURCE_ID,
  INPUT_NAME,
  INPUT_APPROVALS_REQUIRED,
  INPUT_USER_IDS,
  INPUT_GROUP_IDS,
  INPUT_DELETE,
  INPUT_REMOVE_HIDDEN_GROUPS,
  INPUT_FALLBACK_APPROVALS_REQUIRED,
} = MRRulesHiddenInputs;
const TEST_USERS = [{ id: 1 }, { id: 10 }];
const TEST_GROUPS = [{ id: 2 }, { id: 4 }];
const TEST_FALLBACK_APPROVALS_REQUIRED = 3;

describe('EE Approvlas MRRulesHiddenInputs', () => {
  let wrapper;
  let store;

  const factory = () => {
    wrapper = shallowMount(MRRulesHiddenInputs, {
      store: new Vuex.Store(store),
    });
  };

  beforeEach(() => {
    store = createStoreOptions({ approvals: MREditModule() });
    store.modules.approvals.state = {
      rules: [],
      rulesToDelete: [],
      fallbackApprovalsRequired: TEST_FALLBACK_APPROVALS_REQUIRED,
    };
  });

  const findHiddenInputs = () =>
    wrapper.findAll('input[type=hidden]').wrappers.map((x) => ({
      name: x.attributes('name'),
      value: x.element.value,
    }));

  describe('cannot edit', () => {
    beforeEach(() => {
      store.state.settings = { canEdit: false };
    });

    it('is empty', () => {
      factory();

      expect(wrapper.html()).toBe('');
    });
  });

  describe('can edit', () => {
    it('is not empty', () => {
      factory();

      expect(wrapper.html()).not.toBeUndefined();
    });

    describe('with no rules', () => {
      it('renders fallback rules', () => {
        factory();

        expect(findHiddenInputs()).toEqual([
          {
            name: INPUT_FALLBACK_APPROVALS_REQUIRED,
            value: TEST_FALLBACK_APPROVALS_REQUIRED.toString(),
          },
        ]);
      });
    });

    describe('with rules to delete', () => {
      beforeEach(() => {
        store.modules.approvals.state.rulesToDelete = [4, 7];
      });

      it('renders delete inputs', () => {
        factory();

        expect(findHiddenInputs()).toEqual(
          expect.arrayContaining([
            { name: INPUT_ID, value: '4' },
            { name: INPUT_DELETE, value: '1' },
            { name: INPUT_ID, value: '7' },
            { name: INPUT_DELETE, value: '1' },
          ]),
        );
      });
    });

    describe('with rules', () => {
      let rule;

      beforeEach(() => {
        rule = {
          ...createMRRule(),
          users: TEST_USERS,
          groups: TEST_GROUPS,
        };
        store.modules.approvals.state.rules = [rule];
      });

      it('renders hidden fields for each row', () => {
        factory();

        expect(findHiddenInputs()).toEqual([
          { name: INPUT_ID, value: rule.id.toString() },
          { name: INPUT_APPROVALS_REQUIRED, value: rule.approvalsRequired.toString() },
          { name: INPUT_NAME, value: rule.name },
          ...TEST_USERS.map(({ id }) => ({ name: INPUT_USER_IDS, value: id.toString() })),
          ...TEST_GROUPS.map(({ id }) => ({ name: INPUT_GROUP_IDS, value: id.toString() })),
        ]);
      });

      describe('with empty users', () => {
        beforeEach(() => {
          rule.users = [];
        });

        it('renders empty users input', () => {
          factory();

          expect(findHiddenInputs().filter((x) => x.name === INPUT_USER_IDS)).toEqual([
            { name: INPUT_USER_IDS, value: '' },
          ]);
        });
      });

      describe('with empty groups', () => {
        beforeEach(() => {
          rule.groups = [];
        });

        it('renders empty groups input', () => {
          factory();

          expect(findHiddenInputs().filter((x) => x.name === INPUT_GROUP_IDS)).toEqual([
            { name: INPUT_GROUP_IDS, value: '' },
          ]);
        });
      });

      describe('with new rule', () => {
        beforeEach(() => {
          rule.isNew = true;
        });

        it('does render id input', () => {
          factory();

          expect(findHiddenInputs().map((x) => x.name)).toContain(INPUT_ID);
        });

        describe('with source', () => {
          beforeEach(() => {
            rule.hasSource = true;
            rule.sourceId = 22;
          });

          it('renders source id input', () => {
            factory();

            expect(findHiddenInputs()).toEqual(
              expect.arrayContaining([
                {
                  name: INPUT_SOURCE_ID,
                  value: rule.sourceId.toString(),
                },
              ]),
            );
          });
        });
      });

      describe('with remove hidden groups', () => {
        beforeEach(() => {
          rule.removeHiddenGroups = true;
        });

        it('renders input to remove hidden groups', () => {
          factory();

          expect(findHiddenInputs()).toEqual(
            expect.arrayContaining([
              {
                name: INPUT_REMOVE_HIDDEN_GROUPS,
                value: 'true',
              },
            ]),
          );
        });
      });
    });
  });
});
