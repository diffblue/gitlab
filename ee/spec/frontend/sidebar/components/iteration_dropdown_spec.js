import {
  GlDropdownDivider,
  GlDropdownItem,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import IterationDropdown from 'ee/sidebar/components/iteration_dropdown.vue';
import groupIterationsQuery from 'ee/sidebar/queries/iterations.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';

Vue.use(VueApollo);

const TEST_SEARCH = 'search';
const TEST_FULL_PATH = 'gitlab-test/test';
const TEST_ITERATIONS = [
  {
    id: '11',
    title: 'Test Title',
    startDate: '2021-10-01',
    dueDate: '2021-10-05',
    webUrl: '',
    state: '',
    iterationCadence: {
      id: '111',
      title: 'My Cadence',
    },
  },
  {
    id: '22',
    title: 'Another Test Title',
    startDate: '2021-10-06',
    dueDate: '2021-10-10',
    webUrl: '',
    state: '',
    iterationCadence: {
      id: '222',
      title: 'My Second Cadence',
    },
  },
  {
    id: '33',
    title: 'Yet Another Test Title',
    startDate: '2021-10-11',
    dueDate: '2021-10-15',
    webUrl: '',
    state: '',
    iterationCadence: {
      id: '333',
      title: 'My Cadence',
    },
  },
];

describe('IterationDropdown', () => {
  let wrapper;
  let fakeApollo;
  let groupIterationsSpy;

  beforeEach(() => {
    groupIterationsSpy = jest.fn().mockResolvedValue({
      data: {
        group: {
          id: '1',
          iterations: {
            nodes: TEST_ITERATIONS,
          },
        },
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const waitForDebounce = async () => {
    await wrapper.vm.$nextTick();
    jest.runOnlyPendingTimers();
  };
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemWithText = (text) =>
    findDropdownItems().wrappers.find((x) => x.text() === text);
  const findDropdownItemsData = () =>
    findDropdownItems().wrappers.map((x) => ({
      isCheckItem: x.props('isCheckItem'),
      isChecked: x.props('isChecked'),
      text: x.text(),
    }));
  const selectDropdownItemAndWait = async (text) => {
    const item = findDropdownItemWithText(text);

    item.vm.$emit('click');

    await wrapper.vm.$nextTick();
  };
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const showDropdownAndWait = async () => {
    findDropdown().vm.$emit('show');

    await waitForDebounce();
  };
  const isLoading = () => wrapper.findComponent(GlLoadingIcon).exists();

  const createComponent = ({ mountFn = shallowMount, iterationCadences = false } = {}) => {
    fakeApollo = createMockApollo([[groupIterationsQuery, groupIterationsSpy]]);

    wrapper = mountFn(IterationDropdown, {
      apolloProvider: fakeApollo,
      propsData: {
        fullPath: TEST_FULL_PATH,
      },
      provide: {
        glFeatures: {
          iterationCadences,
        },
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not show loading', () => {
      expect(isLoading()).toBe(false);
    });

    it('shows gl-dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
      expect(findDropdown().element).toMatchSnapshot();
    });
  });

  describe('when dropdown opens and query is loading', () => {
    beforeEach(async () => {
      // return promise that doesn't resolve to force loading state
      groupIterationsSpy.mockReturnValue(new Promise(() => {}));

      createComponent();

      await showDropdownAndWait();
    });

    it('shows loading', () => {
      expect(isLoading()).toBe(true);
    });

    it('calls groupIterations query', () => {
      expect(groupIterationsSpy).toHaveBeenCalledTimes(1);
      expect(groupIterationsSpy).toHaveBeenCalledWith({
        fullPath: TEST_FULL_PATH,
        state: 'opened',
        title: '',
      });
    });
  });

  describe('when dropdown opens and query responds', () => {
    beforeEach(async () => {
      createComponent();

      await showDropdownAndWait();
    });

    it('does not show loading', () => {
      expect(isLoading()).toBe(false);
    });

    it('shows dropdown items', () => {
      const result = [IterationDropdown.noIteration].concat(TEST_ITERATIONS);

      expect(findDropdownItemsData()).toEqual(
        result.map((x) => ({
          isCheckItem: true,
          isChecked: false,
          text: x.title,
        })),
      );
    });

    it('does not re-query if opened again', async () => {
      groupIterationsSpy.mockClear();
      await showDropdownAndWait();

      expect(groupIterationsSpy).not.toHaveBeenCalled();
    });

    describe.each([0, 1, 2])('when item %s is selected', (index) => {
      const allIterations = [IterationDropdown.noIteration].concat(TEST_ITERATIONS);
      const selected = allIterations[index];
      const asNotChecked = ({ title }) => ({ isCheckItem: true, isChecked: false, text: title });

      beforeEach(async () => {
        await selectDropdownItemAndWait(selected.title);
      });

      it('shows item as checked', () => {
        const prevSelected = allIterations.slice(0, index);
        const afterSelected = allIterations.slice(index + 1);

        expect(findDropdownItemsData()).toEqual([
          ...prevSelected.map(asNotChecked),
          {
            isCheckItem: true,
            isChecked: true,
            text: selected.title,
          },
          ...afterSelected.map(asNotChecked),
        ]);
      });

      it('emits event', () => {
        expect(wrapper.emitted('onIterationSelect')).toEqual([[selected]]);
      });

      describe('when item is clicked again', () => {
        beforeEach(async () => {
          await selectDropdownItemAndWait(selected.title);
        });

        it('shows item as unchecked', () => {
          expect(findDropdownItemsData()).toEqual(allIterations.map(asNotChecked));
        });

        it('emits event', () => {
          expect(wrapper.emitted('onIterationSelect').length).toBe(2);
          expect(wrapper.emitted('onIterationSelect')[1]).toEqual([null]);
        });
      });
    });
  });

  describe('when dropdown opens and search is set', () => {
    beforeEach(async () => {
      createComponent();

      await showDropdownAndWait();

      groupIterationsSpy.mockClear();

      wrapper.findComponent(GlSearchBoxByType).vm.$emit('input', TEST_SEARCH);

      await waitForDebounce();
    });

    it('adds the search to the query', () => {
      expect(groupIterationsSpy).toHaveBeenCalledWith({
        fullPath: TEST_FULL_PATH,
        state: 'opened',
        title: `"${TEST_SEARCH}"`,
      });
    });
  });

  describe('when iteration_cadences feature flag is on', () => {
    beforeEach(async () => {
      createComponent({ iterationCadences: true, mountFn: mount });

      await showDropdownAndWait();
    });

    it('shows dropdown items grouped by iteration cadence', () => {
      const dropdownItems = wrapper.findAll('li');

      expect(dropdownItems.at(0).text()).toBe('Assign Iteration');
      expect(dropdownItems.at(1).text()).toContain('No iteration');
      expect(dropdownItems.at(2).findComponent(GlDropdownDivider).exists()).toBe(true);
      expect(dropdownItems.at(3).findComponent(GlDropdownSectionHeader).text()).toBe('My Cadence');
      expect(dropdownItems.at(4).text()).toContain('Test Title');
      expect(dropdownItems.at(4).text()).toContain('Oct 1, 2021 - Oct 5, 2021');
      expect(dropdownItems.at(5).text()).toContain('Yet Another Test Title');
      expect(dropdownItems.at(5).text()).toContain('Oct 11, 2021 - Oct 15, 2021');
      expect(dropdownItems.at(6).findComponent(GlDropdownDivider).exists()).toBe(true);
      expect(dropdownItems.at(7).findComponent(GlDropdownSectionHeader).text()).toBe(
        'My Second Cadence',
      );
      expect(dropdownItems.at(8).text()).toContain('Another Test Title');
      expect(dropdownItems.at(8).text()).toContain('Oct 6, 2021 - Oct 10, 2021');
    });
  });
});
