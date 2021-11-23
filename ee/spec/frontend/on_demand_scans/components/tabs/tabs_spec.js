import { shallowMount } from '@vue/test-utils';
import AllTab from 'ee/on_demand_scans/components/tabs/all.vue';
import RunningTab from 'ee/on_demand_scans/components/tabs/running.vue';
import FinishedTab from 'ee/on_demand_scans/components/tabs/finished.vue';
import BaseTab from 'ee/on_demand_scans/components/tabs/base_tab.vue';
import onDemandScansQuery from 'ee/on_demand_scans/graphql/on_demand_scans.query.graphql';
import { BASE_TABS_TABLE_FIELDS, LEARN_MORE_TEXT } from 'ee/on_demand_scans/constants';

describe.each`
  tab           | component      | queryVariables           | emptyTitle                        | emptyText
  ${'All'}      | ${AllTab}      | ${{}}                    | ${undefined}                      | ${undefined}
  ${'Running'}  | ${RunningTab}  | ${{ scope: 'RUNNING' }}  | ${'There are no running scans.'}  | ${LEARN_MORE_TEXT}
  ${'Finished'} | ${FinishedTab} | ${{ scope: 'FINISHED' }} | ${'There are no finished scans.'} | ${LEARN_MORE_TEXT}
`('$tab tab', ({ tab, component, queryVariables, emptyTitle, emptyText }) => {
  let wrapper;

  // Finders
  const findBaseTab = () => wrapper.findComponent(BaseTab);

  const createComponent = (propsData) => {
    wrapper = shallowMount(component, {
      propsData,
    });
  };

  beforeEach(() => {
    createComponent({
      isActive: true,
      itemsCount: 12,
    });
  });

  it('renders the base tab with the correct props', () => {
    expect(findBaseTab().props('title')).toBe(tab);
    expect(findBaseTab().props('itemsCount')).toBe(12);
    expect(findBaseTab().props('query')).toBe(onDemandScansQuery);
    expect(findBaseTab().props('queryVariables')).toEqual(queryVariables);
    expect(findBaseTab().props('emptyStateTitle')).toBe(emptyTitle);
    expect(findBaseTab().props('emptyStateText')).toBe(emptyText);
    expect(findBaseTab().props('fields')).toBe(BASE_TABS_TABLE_FIELDS);
  });
});
