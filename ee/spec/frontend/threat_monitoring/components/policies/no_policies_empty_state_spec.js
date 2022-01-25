import { nextTick } from 'vue';
import NoPoliciesEmptyState from 'ee/threat_monitoring/components/policies/no_policies_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('NoPoliciesEmptyState component', () => {
  let wrapper;

  const findEmptyFilterState = () => wrapper.findByTestId('empty-filter-state');
  const findEmptyListState = () => wrapper.findByTestId('empty-list-state');

  const factory = (hasExistingPolicies = false) => {
    wrapper = shallowMountExtended(NoPoliciesEmptyState, {
      propsData: {
        hasExistingPolicies,
      },
      provide: {
        emptyFilterSvgPath: 'path/to/filter/svg',
        emptyListSvgPath: 'path/to/list/svg',
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
    ${'does not display the empty filter state'} | ${findEmptyFilterState} | ${true}  | ${() => factory(true)}
    ${'does display the empty list state'}       | ${findEmptyListState}   | ${false} | ${() => factory(true)}
  `('$title', async ({ factoryFn, findComponent, state }) => {
    factoryFn();
    await nextTick();
    expect(findComponent().exists()).toBe(state);
  });
});
