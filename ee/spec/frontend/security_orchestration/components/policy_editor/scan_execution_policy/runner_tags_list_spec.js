import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlListboxItem } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createApolloProvider from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RunnerTagsList from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/runner_tags_list.vue';
import projectRunnerTags from 'ee/security_orchestration/graphql/queries/get_project_runner_tags.query.graphql';
import groupRunnerTags from 'ee/security_orchestration/graphql/queries/get_group_runner_tags.query.graphql';
import { getUniqueTagListFromEdges } from 'ee/on_demand_scans_form/utils';
import {
  POLICY_ACTION_TAG_MODE_SPECIFIC_TAG_KEY,
  POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';
import { RUNNER_TAG_LIST_MOCK } from '../../../../on_demand_scans/mocks';

describe('RunnerTagsList', () => {
  let wrapper;
  let requestHandlers;
  const projectId = 'gid://gitlab/Project/20';

  const defaultHandlerValue = (type = 'project') =>
    jest.fn().mockResolvedValue({
      data: {
        [type]: {
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
    return createApolloProvider([
      [projectRunnerTags, requestHandlers],
      [groupRunnerTags, requestHandlers],
    ]);
  };

  const createComponent = (propsData = {}, handlers = defaultHandlerValue()) => {
    wrapper = mountExtended(RunnerTagsList, {
      apolloProvider: createMockApolloProvider(handlers),
      propsData: {
        namespacePath: 'gitlab-org/testPath',
        ...propsData,
      },
    });
  };

  const findTagsModeSwitcher = () => wrapper.findByTestId('runner-tags-switcher');
  const findTagsList = () => wrapper.findByTestId('runner-tags-list');
  const findDropdownItems = () => findTagsList().findAllComponents(GlListboxItem);
  const findSearchBox = () => wrapper.findByTestId('listbox-search-input');

  const toggleDropdown = (event = 'shown') => {
    findTagsList().vm.$emit(event);
  };

  beforeEach(async () => {
    createComponent();
    await waitForPromises();
  });

  it('should load data', () => {
    expect(requestHandlers).toHaveBeenCalledTimes(1);
    expect(findDropdownItems()).toHaveLength(5);
  });

  it('should select tags', async () => {
    expect(findTagsList().props('toggleText')).toBe('Select runner tags');

    toggleDropdown();
    await waitForPromises();

    findDropdownItems().at(0).vm.$emit('select', ['macos']);
    await nextTick();
    findDropdownItems().at(2).vm.$emit('select', ['docker']);
    await nextTick();

    expect(findTagsList().props('toggleText')).toBe('macos, docker');
    expect(wrapper.emitted('input')).toHaveLength(2);
  });

  it.each`
    query       | expectedLength | expectedTagText
    ${'macos'}  | ${1}           | ${'macos'}
    ${'docker'} | ${1}           | ${'docker'}
    ${'ma'}     | ${1}           | ${'macos'}
  `('should filter out results by search', async ({ query, expectedLength, expectedTagText }) => {
    toggleDropdown();

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

    findDropdownItems().at(0).trigger('click');

    expect(wrapper.emitted('input')).toHaveLength(1);
  });

  describe('error handling', () => {
    it('should emit error event', async () => {
      createComponent({}, jest.fn().mockRejectedValue({ error: new Error() }));
      await waitForPromises();

      expect(wrapper.emitted('error')).toHaveLength(1);
    });

    it('should emit error when invalid tag is provided or saved', async () => {
      createComponent({
        value: ['invalid tag'],
      });
      await waitForPromises();

      expect(wrapper.emitted('error')).toHaveLength(1);
    });
  });

  describe('selected tags', () => {
    const savedOnBackendTags = ['linux', 'macos'];

    beforeEach(async () => {
      createComponent({ value: savedOnBackendTags });
      await waitForPromises();
    });

    it('should render saved on backend selected tags', () => {
      toggleDropdown();

      expect(findDropdownItems().at(0).text()).toBe('linux');
      expect(findDropdownItems().at(1).text()).toBe('macos');

      expect(findDropdownItems().at(0).props('isSelected')).toBe(true);
      expect(findDropdownItems().at(1).props('isSelected')).toBe(true);
    });
  });

  describe('switch mode', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('should have specific tag mode by default', () => {
      expect(findTagsModeSwitcher().props('selected')).toBe(
        POLICY_ACTION_TAG_MODE_SPECIFIC_TAG_KEY,
      );
      expect(findTagsModeSwitcher().props('toggleText')).toBe('has specific tag');
      expect(findTagsList().exists()).toBe(true);
    });

    it('should hide tags list for automatic mode', async () => {
      await findTagsModeSwitcher().vm.$emit(
        'select',
        POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
      );

      expect(findTagsModeSwitcher().props('selected')).toBe(
        POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
      );
      expect(findTagsModeSwitcher().props('toggleText')).toBe('selected automatically');
      expect(findTagsList().exists()).toBe(false);
    });

    it('resets selected tags when switched to automatically mode', async () => {
      createComponent({ value: ['macos'] });
      await waitForPromises();

      expect(findTagsList().props('selected')).toMatchObject(['macos']);

      await findTagsModeSwitcher().vm.$emit(
        'select',
        POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
      );

      expect(wrapper.emitted('input')).toMatchObject([[[]]]);
    });
  });

  describe('No runners', () => {
    beforeEach(async () => {
      const savedOnBackendTags = ['docker', 'node'];

      createComponent(
        {
          value: savedOnBackendTags,
        },
        jest.fn().mockResolvedValue({
          data: {
            project: {
              id: projectId,
              runners: {
                nodes: [],
              },
            },
          },
        }),
      );
      await waitForPromises();
    });

    it('should have disabled listbox', () => {
      expect(findTagsList().exists()).toBe(false);
    });

    it('should have default label text and title', () => {
      expect(findTagsModeSwitcher().props('disabled')).toBe(true);
      expect(findTagsModeSwitcher().findComponent(GlButton).text()).toBe('selected automatically');
      expect(findTagsModeSwitcher().attributes('title')).toBe(
        'Scan will automatically choose a runner to run on because there are no tags exist on runners',
      );
    });
  });
});
