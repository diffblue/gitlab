import { GlSorting, GlSortingItem } from '@gitlab/ui';
import { nextTick } from 'vue';
import DependenciesActions from 'ee/dependencies/components/dependencies_actions.vue';
import createStore from 'ee/dependencies/store';
import { DEPENDENCY_LIST_TYPES } from 'ee/dependencies/store/constants';
import { SORT_FIELDS } from 'ee/dependencies/store/modules/list/constants';
import { TEST_HOST } from 'helpers/test_constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('DependenciesActions component', () => {
  let store;
  let wrapper;
  const { namespace } = DEPENDENCY_LIST_TYPES.all;

  const factory = ({ propsData, featureFlags = {} } = {}) => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMountExtended(DependenciesActions, {
      store,
      propsData: { ...propsData },
      stubs: {
        GlSortingItem,
      },
      provide: {
        glFeatures: {
          ...featureFlags,
        },
      },
    });
  };

  const findExportButton = () => wrapper.findByTestId('export');
  const findSorting = () => wrapper.findComponent(GlSorting);

  beforeEach(async () => {
    factory({
      propsData: { namespace },
    });
    store.state[namespace].endpoint = `${TEST_HOST}/dependencies.json`;
    await nextTick();
  });

  it('dispatches the right setSortField action on clicking each item in the dropdown', () => {
    const sortingItems = wrapper.findAllComponents(GlSortingItem).wrappers;

    sortingItems.forEach((item) => {
      // trigger() does not work on stubbed/shallow mounted components
      // https://github.com/vuejs/vue-test-utils/issues/919
      item.vm.$emit('click');
    });

    expect(store.dispatch.mock.calls).toEqual(
      expect.arrayContaining(
        Object.keys(SORT_FIELDS).map((field) => [`${namespace}/setSortField`, field]),
      ),
    );
  });

  it('dispatches the toggleSortOrder action on clicking the sort order button', () => {
    findSorting().vm.$emit('sortDirectionChange');
    expect(store.dispatch).toHaveBeenCalledWith(`${namespace}/toggleSortOrder`);
  });

  it('has a button to perform an async export of the dependency list', () => {
    expect(findExportButton().attributes('icon')).toBe('export');

    findExportButton().vm.$emit('click');

    expect(store.dispatch).toHaveBeenCalledWith(`${namespace}/fetchExport`);
  });

  describe('with fetching in progress', () => {
    beforeEach(async () => {
      store.state[namespace].fetchingInProgress = true;
      await nextTick;
    });

    it('sets the icon to match the loading icon', () => {
      const exportButton = findExportButton();

      expect(exportButton.attributes('icon')).toBe('');
      expect(exportButton.attributes('loading')).toBe('true');
    });
  });
});
