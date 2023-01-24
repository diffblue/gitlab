import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createApolloProvider from 'helpers/mock_apollo_helper';
import RunnerTags from 'ee/on_demand_scans_form/components/runner_tags.vue';
import getAllProjectRunners from 'ee/on_demand_scans_form/graphql/all_runners.query.graphql';
import { getUniqueTagListFromEdges } from 'ee/on_demand_scans_form/utils';
import { RUNNER_TAG_LIST_MOCK } from '../../on_demand_scans/mocks';

describe('RunnersTag', () => {
  let wrapper;
  let requestHandlers;
  const projectId = 'gid://gitlab/Project/20';

  const defaultHandlerValue = jest.fn().mockResolvedValue({
    data: {
      project: {
        id: projectId,
        runners: {
          nodes: RUNNER_TAG_LIST_MOCK,
        },
      },
    },
  });
  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);

    requestHandlers = handlers;
    return createApolloProvider([[getAllProjectRunners, requestHandlers]]);
  };

  const createComponent = (propsData = {}, handlers = defaultHandlerValue) => {
    wrapper = mountExtended(RunnerTags, {
      apolloProvider: createMockApolloProvider(handlers),
      propsData: {
        projectPath: 'gitlab-org/testPath',
        ...propsData,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDropdownItems = () => wrapper.findAllComponents(GlListboxItem);
  const findEmptyPlaceholder = () => wrapper.findByTestId('listbox-no-results-text');
  const findSearchBox = () => wrapper.findByTestId('listbox-search-input');

  const toggleDropdown = (event = 'shown') => {
    findDropdown().vm.$emit(event);
  };

  beforeEach(() => {
    createComponent();
  });

  it('should load data only when dropdown is opened for the first time', () => {
    toggleDropdown();

    expect(requestHandlers).toHaveBeenCalledTimes(1);

    toggleDropdown('hidden');
    toggleDropdown();

    expect(requestHandlers).toHaveBeenCalledTimes(1);
  });

  it('should select tags', async () => {
    expect(findDropdown().props('toggleText')).toBe('Select runner tags');

    toggleDropdown();
    await waitForPromises();

    findDropdownItems().at(0).vm.$emit('select', ['macos']);
    await nextTick();
    findDropdownItems().at(2).vm.$emit('select', ['docker']);
    await nextTick();

    expect(findDropdown().props('toggleText')).toBe('macos, docker');
  });

  it.each`
    query       | expectedLength | expectedTagText
    ${'macos'}  | ${1}           | ${'macos'}
    ${'docker'} | ${1}           | ${'docker'}
    ${'ma'}     | ${1}           | ${'macos'}
  `('should filter out results by search', async ({ query, expectedLength, expectedTagText }) => {
    toggleDropdown();
    await waitForPromises();

    expect(findDropdownItems()).toHaveLength(
      getUniqueTagListFromEdges(RUNNER_TAG_LIST_MOCK).length,
    );

    findSearchBox().vm.$emit('input', query);
    await nextTick();

    expect(findDropdownItems()).toHaveLength(expectedLength);
    expect(findDropdownItems().at(0).text()).toBe(expectedTagText);
  });

  it('should render selected tags on top after re-open', async () => {
    toggleDropdown();
    await waitForPromises();

    expect(findDropdownItems().at(3).text()).toEqual('backup');
    expect(findDropdownItems().at(4).text()).toEqual('development');

    findDropdownItems().at(3).vm.$emit('select', ['backup']);
    await nextTick();
    findDropdownItems().at(4).vm.$emit('select', ['development']);

    /**
     * close - open dropdown
     */
    toggleDropdown('hidden');
    await nextTick();
    toggleDropdown();

    expect(findDropdownItems().at(0).text()).toEqual('development');
    expect(findDropdownItems().at(1).text()).toEqual('backup');
  });

  it('should emit select event', async () => {
    toggleDropdown();

    await waitForPromises();

    findDropdownItems().at(0).trigger('click');

    expect(wrapper.emitted('input')).toHaveLength(1);
  });

  describe('error handling', () => {
    it.each`
      mockedValue                     | expectedResult
      ${new Error()}                  | ${'Unable to fetch runner tags. Try reloading the page.'}
      ${{ message: 'error message' }} | ${'error message'}
    `('should emit error event', async ({ mockedValue, expectedResult }) => {
      createComponent({}, jest.fn().mockRejectedValue(mockedValue));

      toggleDropdown();

      toggleDropdown();
      await waitForPromises();

      const [[errorPayload]] = wrapper.emitted('error');
      expect(errorPayload).toBe(expectedResult);
    });
  });

  describe('no tags found', () => {
    beforeEach(() => {
      createComponent({}, jest.fn().mockResolvedValue([]));
    });

    it('should display empty placeholder if no tags found', () => {
      expect(findEmptyPlaceholder().text()).toBe('No matching results');
    });
  });

  describe('selected tags', () => {
    const savedOnBackendTags = ['linux', 'macos'];

    beforeEach(() => {
      createComponent({ value: savedOnBackendTags });
    });

    it('should render saved on backend selected tags', async () => {
      toggleDropdown();
      await waitForPromises();

      expect(findDropdownItems().at(0).text()).toBe('linux');
      expect(findDropdownItems().at(1).text()).toBe('macos');

      expect(findDropdownItems().at(0).props('isSelected')).toBe(true);
      expect(findDropdownItems().at(1).props('isSelected')).toBe(true);
    });
  });
});
