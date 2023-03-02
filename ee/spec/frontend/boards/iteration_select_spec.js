import { GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import IterationSelect from 'ee/boards/components/iteration_select.vue';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { boardObj } from 'jest/boards/mock_data';

import searchIterationQuery from 'ee/issues/list/queries/search_iterations.query.graphql';
import { ANY_ITERATION, CURRENT_ITERATION, IterationFilterType } from 'ee/boards/constants';
import { WORKSPACE_GROUP } from '~/issues/constants';
import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';
import { mockIterationsResponse, mockIterations, mockIterationCadence } from './mock_data';

Vue.use(VueApollo);
Vue.use(Vuex);

describe('Iteration select component', () => {
  let wrapper;
  let fakeApollo;

  const mockAnyIterationInCadence = {
    id: ANY_ITERATION.id,
    title: IterationFilterType.any,
    iterationCadenceId: mockIterationCadence.id,
    cadenceTitle: mockIterationCadence.title,
  };

  const mockCurrentIterationInCadence = {
    id: CURRENT_ITERATION.id,
    title: IterationFilterType.current,
    iterationCadenceId: mockIterationCadence.id,
    cadenceTitle: mockIterationCadence.title,
  };

  const selectedText = () => wrapper.findByTestId('selected-iteration').text();
  const findEditButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(DropdownWidget);

  const iterationsQueryHandlerSuccess = jest.fn().mockResolvedValue(mockIterationsResponse);

  const createStore = () => {
    return new Vuex.Store({
      actions: {
        setError: jest.fn(),
      },
    });
  };

  const createComponent = ({ props = {} } = {}) => {
    const store = createStore();
    fakeApollo = createMockApollo([[searchIterationQuery, iterationsQueryHandlerSuccess]]);
    wrapper = shallowMountExtended(IterationSelect, {
      store,
      apolloProvider: fakeApollo,
      propsData: {
        board: boardObj,
        canEdit: true,
        ...props,
      },
      provide: {
        fullPath: 'gitlab-org',
        boardType: WORKSPACE_GROUP,
        isGroupBoard: true,
        isProjectBoard: false,
      },
      stubs: {
        GlDropdown,
        GlDropdownItem,
        DropdownWidget: stubComponent(DropdownWidget, {
          methods: { showDropdown: jest.fn() },
        }),
      },
    });
  };

  afterEach(() => {
    fakeApollo = null;
  });

  describe('when not editing', () => {
    beforeEach(() => {
      createComponent();
    });

    it('defaults to Any iteration', () => {
      expect(selectedText()).toContain('Any iteration');
    });

    it('skips the queries and does not render dropdown', () => {
      expect(iterationsQueryHandlerSuccess).not.toHaveBeenCalled();
      expect(findDropdown().isVisible()).toBe(false);
    });

    it('renders selected iteration', async () => {
      findEditButton().vm.$emit('click');

      findDropdown().vm.$emit('set-option', mockIterations[1]);
      await nextTick();

      expect(selectedText()).toContain(mockIterations[1].title);
    });

    it('shows Edit button if canEdit is true', () => {
      expect(findEditButton().exists()).toBe(true);
    });

    it('renders cadence when Any in cadence is selected', async () => {
      findEditButton().vm.$emit('click');

      findDropdown().vm.$emit('set-option', mockAnyIterationInCadence);
      await nextTick();

      expect(selectedText()).toBe(`Any iteration in ${mockIterationCadence.title}`);
    });

    it('renders cadence when Current in cadence is selected', async () => {
      findEditButton().vm.$emit('click');

      findDropdown().vm.$emit('set-option', mockCurrentIterationInCadence);
      await nextTick();

      expect(selectedText()).toBe(`Current iteration in ${mockIterationCadence.title}`);
    });
  });

  describe('when editing', () => {
    beforeEach(() => {
      createComponent();
    });

    it('trigger query and renders dropdown with passed iterations', async () => {
      findEditButton().vm.$emit('click');
      await waitForPromises();
      expect(iterationsQueryHandlerSuccess).toHaveBeenCalled();

      expect(findDropdown().isVisible()).toBe(true);
    });
  });

  describe('canEdit', () => {
    beforeEach(() => {
      createComponent({ props: { canEdit: false } });
    });

    it('hides Edit button if false', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });
});
