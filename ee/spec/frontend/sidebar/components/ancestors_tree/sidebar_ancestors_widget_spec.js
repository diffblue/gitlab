import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Ancestors from 'ee_component/sidebar/components/ancestors_tree/ancestors_tree.vue';
import SidebarAncestorsWidget from 'ee_component/sidebar/components/ancestors_tree/sidebar_ancestors_widget.vue';
import epicAncestorsQuery from 'ee_component/sidebar/queries/epic_ancestors.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { epicAncestorsResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('Sidebar Ancestors Widget', () => {
  let wrapper;
  let fakeApollo;

  const findAncestors = () => wrapper.findComponent(Ancestors);

  const createComponent = ({
    ancestorsQueryHandler = jest.fn().mockResolvedValue(epicAncestorsResponse()),
  } = {}) => {
    fakeApollo = createMockApollo([[epicAncestorsQuery, ancestorsQueryHandler]]);

    wrapper = shallowMount(SidebarAncestorsWidget, {
      apolloProvider: fakeApollo,
      propsData: {
        fullPath: 'group',
        iid: '1',
        issuableType: 'epic',
      },
    });
  };

  afterEach(() => {
    fakeApollo = null;
  });

  it('passes a `isFetching` prop as true to child component when query is loading', () => {
    createComponent();

    expect(findAncestors().props('isFetching')).toBe(true);
  });

  describe('when ancestors are loaded', () => {
    beforeEach(() => {
      createComponent({
        ancestorsQueryHandler: jest.fn().mockResolvedValue(epicAncestorsResponse()),
      });
      return waitForPromises();
    });

    it('passes a `isFetching` prop as false to editable item', () => {
      expect(findAncestors().props('isFetching')).toBe(false);
    });

    it('passes ancestors to child component', () => {
      expect(findAncestors().props('ancestors')).toEqual(
        epicAncestorsResponse().data.workspace.issuable.ancestors.nodes,
      );
    });
  });

  describe('when error occurs', () => {
    it('emits error event with correct parameters', async () => {
      const mockError = new Error('mayday');

      createComponent({
        ancestorsQueryHandler: jest.fn().mockRejectedValue(mockError),
      });

      await waitForPromises();

      const [
        [
          {
            message,
            error: { networkError },
          },
        ],
      ] = wrapper.emitted('fetch-error');
      expect(message).toBe(wrapper.vm.$options.i18n.fetchingError);
      expect(networkError).toEqual(mockError);
    });
  });
});
