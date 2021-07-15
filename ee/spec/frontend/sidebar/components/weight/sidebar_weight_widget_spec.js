import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import SidebarWeightWidget from 'ee_component/sidebar/components/weight/sidebar_weight_widget.vue';
import issueWeightQuery from 'ee_component/sidebar/queries/issue_weight.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { issueNoWeightResponse, issueWeightResponse } from '../../mock_data';

jest.mock('~/flash');

Vue.use(VueApollo);

describe('Sidebar Weight Widget', () => {
  let wrapper;
  let fakeApollo;

  const findEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findWeightValue = () => wrapper.findByTestId('sidebar-weight-value');

  const createComponent = ({
    weightQueryHandler = jest.fn().mockResolvedValue(issueNoWeightResponse()),
  } = {}) => {
    fakeApollo = createMockApollo([[issueWeightQuery, weightQueryHandler]]);

    wrapper = extendedWrapper(
      shallowMount(SidebarWeightWidget, {
        apolloProvider: fakeApollo,
        provide: {
          canUpdate: true,
        },
        propsData: {
          fullPath: 'group/project',
          iid: '1',
          issuableType: 'issue',
        },
        stubs: {
          SidebarEditableItem,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  it('passes a `loading` prop as true to editable item when query is loading', () => {
    createComponent();

    expect(findEditableItem().props('loading')).toBe(true);
  });

  describe('when issue has no weight', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('passes a `loading` prop as false to editable item', () => {
      expect(findEditableItem().props('loading')).toBe(false);
    });

    it('toggle is unchecked', () => {
      expect(findWeightValue().text()).toBe('None');
    });

    it('emits `weightUpdated` event with a `null` payload', () => {
      expect(wrapper.emitted('weightUpdated')).toEqual([[null]]);
    });
  });

  describe('when issue has weight', () => {
    beforeEach(() => {
      createComponent({
        weightQueryHandler: jest.fn().mockResolvedValue(issueWeightResponse(true)),
      });
      return waitForPromises();
    });

    it('passes a `loading` prop as false to editable item', () => {
      expect(findEditableItem().props('loading')).toBe(false);
    });

    it('toggle is checked', () => {
      expect(findWeightValue().text()).toBe('0');
    });

    it('emits `weightUpdated` event with a `true` payload', () => {
      expect(wrapper.emitted('weightUpdated')).toEqual([[0]]);
    });
  });

  it('displays a flash message when query is rejected', async () => {
    createComponent({
      weightQueryHandler: jest.fn().mockRejectedValue('Houston, we have a problem'),
    });
    await waitForPromises();

    expect(createFlash).toHaveBeenCalled();
  });
});
