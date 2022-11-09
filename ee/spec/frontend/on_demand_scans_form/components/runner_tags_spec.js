import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createApolloProvider from 'helpers/mock_apollo_helper';
import RunnerTags from 'ee/on_demand_scans_form/components/runner_tags.vue';
import { getUniqueTagListFromEdges } from 'ee/on_demand_scans_form/utils';
import { RUNNER_TAG_LIST_MOCK } from '../../on_demand_scans/mocks';

Vue.use(VueApollo);

describe('RunnersTag', () => {
  let wrapper;
  let queryMock;

  const createComponent = (propsData = {}) => {
    wrapper = mountExtended(RunnerTags, {
      apolloProvider: createApolloProvider(),
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

  const toggleDropdown = async (event = 'shown') => {
    await findDropdown().vm.$emit(event);
    await nextTick();
  };

  beforeEach(() => {
    createComponent();
    queryMock = jest.spyOn(wrapper.vm.$apollo, 'query').mockResolvedValue(RUNNER_TAG_LIST_MOCK);
  });

  it('should load data only when dropdown is opened for the first time', async () => {
    await toggleDropdown();
    expect(queryMock).toHaveBeenCalledTimes(1);

    await toggleDropdown('hidden');
    await toggleDropdown();

    expect(queryMock).toHaveBeenCalledTimes(1);
  });

  it('should select tags', async () => {
    expect(findDropdown().props('toggleText')).toBe('Select runner tags');

    await toggleDropdown();
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
    ${'ma'}     | ${3}           | ${'macos'}
  `('should filter out results by search', async ({ query, expectedLength, expectedTagText }) => {
    await toggleDropdown();
    await waitForPromises();

    expect(findDropdownItems()).toHaveLength(
      getUniqueTagListFromEdges(RUNNER_TAG_LIST_MOCK.data.project.runners.nodes).length,
    );

    findSearchBox().vm.$emit('input', query);
    await nextTick();

    expect(findDropdownItems()).toHaveLength(expectedLength);
    expect(findDropdownItems().at(0).text()).toBe(expectedTagText);
  });

  it('should display empty placeholder if no tags found', async () => {
    jest.spyOn(wrapper.vm.$apollo, 'query').mockResolvedValue([]);

    await waitForPromises();

    expect(findEmptyPlaceholder().text()).toBe('No matching results');
  });

  it('should render selected tags on top after re-open', async () => {
    await toggleDropdown();
    await waitForPromises();

    expect(findDropdownItems().at(3).text()).toEqual('backup');
    expect(findDropdownItems().at(4).text()).toEqual('development');

    findDropdownItems().at(3).vm.$emit('select', ['backup']);
    await nextTick();
    findDropdownItems().at(4).vm.$emit('select', ['development']);
    await nextTick();

    /**
     * close - open dropdown
     */
    await toggleDropdown('hidden');
    await toggleDropdown();

    expect(findDropdownItems().at(0).text()).toEqual('development');
    expect(findDropdownItems().at(1).text()).toEqual('backup');
  });

  it('should emit select event', async () => {
    await toggleDropdown();

    await toggleDropdown();
    await waitForPromises();

    findDropdownItems().at(0).trigger('click');

    expect(wrapper.emitted('input')).toHaveLength(1);
  });

  it.each`
    mockedValue                     | expectedResult
    ${{}}                           | ${'Unable to fetch runner tags. Try reloading the page.'}
    ${null}                         | ${'Unable to fetch runner tags. Try reloading the page.'}
    ${{ message: 'error message' }} | ${'error message'}
  `('should emit error event', async ({ mockedValue, expectedResult }) => {
    jest.spyOn(wrapper.vm.$apollo, 'query').mockRejectedValue(mockedValue);

    await toggleDropdown();

    await toggleDropdown();
    await waitForPromises();

    const [[errorPayload]] = wrapper.emitted('error');
    expect(errorPayload).toBe(expectedResult);
  });

  describe('selected tags', () => {
    const savedOnBackendTags = ['macos', 'maven'];

    beforeEach(() => {
      createComponent({ value: savedOnBackendTags });
      queryMock = jest.spyOn(wrapper.vm.$apollo, 'query').mockResolvedValue(RUNNER_TAG_LIST_MOCK);
    });

    it('should render saved on backend selected tags', async () => {
      await toggleDropdown();
      await waitForPromises();

      expect(findDropdownItems().at(0).text()).toBe('maven');
      expect(findDropdownItems().at(1).text()).toBe('macos');

      expect(findDropdownItems().at(0).props('isSelected')).toBe(true);
      expect(findDropdownItems().at(1).props('isSelected')).toBe(true);
    });
  });
});
