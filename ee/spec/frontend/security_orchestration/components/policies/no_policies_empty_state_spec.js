import { nextTick } from 'vue';
import NoPoliciesEmptyState from 'ee/security_orchestration/components/policies/no_policies_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('NoPoliciesEmptyState component', () => {
  let wrapper;

  const projectNamespace = 'project';
  const groupNamespace = 'group';

  const findEmptyFilterState = () => wrapper.findByTestId('empty-filter-state');
  const findEmptyListState = () => wrapper.findByTestId('empty-list-state');

  const factory = ({ hasExistingPolicies = false, namespaceType = projectNamespace } = {}) => {
    wrapper = shallowMountExtended(NoPoliciesEmptyState, {
      propsData: {
        hasExistingPolicies,
      },
      provide: {
        emptyFilterSvgPath: 'path/to/filter/svg',
        emptyListSvgPath: 'path/to/list/svg',
        namespaceType,
        newPolicyPath: 'path/to/new/policy',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    title                                        | findComponent           | state    | factoryFn
    ${'does display the empty filter state'}     | ${findEmptyFilterState} | ${false} | ${factory}
    ${'does not display the empty list state'}   | ${findEmptyListState}   | ${true}  | ${factory}
    ${'does not display the empty filter state'} | ${findEmptyFilterState} | ${true}  | ${() => factory({ hasExistingPolicies: true })}
    ${'does display the empty list state'}       | ${findEmptyListState}   | ${false} | ${() => factory({ hasExistingPolicies: true })}
  `('$title', async ({ factoryFn, findComponent, state }) => {
    factoryFn();
    await nextTick();
    expect(findComponent().exists()).toBe(state);
  });

  it.each`
    title                                                   | namespaceType
    ${'does display the correct description for a project'} | ${projectNamespace}
    ${'does display the correct description for a group'}   | ${groupNamespace}
  `('$title', async ({ namespaceType }) => {
    factory({ namespaceType });
    await nextTick();
    expect(findEmptyListState().text()).toContain(namespaceType);
  });
});
