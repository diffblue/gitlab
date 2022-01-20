import { GlLink, GlButton } from '@gitlab/ui';
import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import GeoReplicableItem from 'ee/geo_replicable/components/geo_replicable_item.vue';
import { ACTION_TYPES } from 'ee/geo_replicable/constants';
import { getStoreConfig } from 'ee/geo_replicable/store';
import { MOCK_BASIC_FETCH_DATA_MAP, MOCK_REPLICABLE_TYPE } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoReplicableItem', () => {
  let wrapper;
  const mockReplicable = MOCK_BASIC_FETCH_DATA_MAP[0];

  const actionSpies = {
    initiateReplicableSync: jest.fn(),
  };

  const defaultProps = {
    name: mockReplicable.name,
    projectId: mockReplicable.projectId,
    syncStatus: mockReplicable.state,
    lastSynced: mockReplicable.lastSyncedAt,
    lastVerified: null,
    lastChecked: null,
  };

  const createComponent = (props = {}) => {
    const fakeStore = new Vuex.Store({
      ...getStoreConfig({ replicableType: MOCK_REPLICABLE_TYPE, graphqlFieldName: null }),
      actions: actionSpies,
    });

    wrapper = mount(GeoReplicableItem, {
      localVue,
      store: fakeStore,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findCard = () => wrapper.find('.card');
  const findGlLink = () => findCard().findComponent(GlLink);
  const findGlButton = () => findCard().findComponent(GlButton);
  const findCardHeader = () => findCard().find('.card-header');
  const findTextTitle = () => findCardHeader().find('span');
  const findCardBody = () => findCard().find('.card-body');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders card', () => {
      expect(findCard().exists()).toBe(true);
    });

    it('renders card header', () => {
      expect(findCardHeader().exists()).toBe(true);
    });

    it('renders card body', () => {
      expect(findCardBody().exists()).toBe(true);
    });

    describe('with projectId', () => {
      it('GlLink renders correctly', () => {
        expect(findGlLink().exists()).toBe(true);
        expect(findGlLink().text()).toBe(mockReplicable.name);
      });

      describe('ReSync Button', () => {
        it('renders', () => {
          expect(findGlButton().exists()).toBe(true);
        });

        it('calls initiateReplicableSync when clicked', () => {
          findGlButton().trigger('click');
          expect(actionSpies.initiateReplicableSync).toHaveBeenCalledWith(expect.any(Object), {
            projectId: mockReplicable.projectId,
            name: mockReplicable.name,
            action: ACTION_TYPES.RESYNC,
          });
        });
      });
    });

    describe('without projectId', () => {
      beforeEach(() => {
        createComponent({ projectId: null });
      });

      it('Text title renders correctly', () => {
        expect(findTextTitle().exists()).toBe(true);
        expect(findTextTitle().text()).toBe(mockReplicable.name);
      });

      it('GlLink does not render', () => {
        expect(findGlLink().exists()).toBe(false);
      });

      it('ReSync Button does not render', () => {
        expect(findGlButton().exists()).toBe(false);
      });
    });
  });
});
