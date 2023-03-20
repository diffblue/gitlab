import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RunnerTags from 'ee/on_demand_scans_form/components/runner_tags.vue';
import { createMockApolloProvider } from 'ee_jest/vue_shared/components/runner_tags_dropdown/mocks/apollo_mock';

describe('RunnersTag', () => {
  let wrapper;

  const createComponent = (propsData = {}, handlers) => {
    const { apolloProvider } = createMockApolloProvider({ handlers });

    wrapper = mountExtended(RunnerTags, {
      apolloProvider,
      propsData: {
        projectPath: 'gitlab-org/testPath',
        ...propsData,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findEmptyPlaceholder = () => wrapper.findByTestId('listbox-no-results-text');

  const toggleDropdown = (event = 'shown') => {
    findDropdown().vm.$emit(event);
  };

  beforeEach(async () => {
    createComponent();
    await waitForPromises();
  });

  describe('error handling', () => {
    it.each`
      mockedValue                     | expectedResult
      ${new Error()}                  | ${'Unable to fetch runner tags. Try reloading the page.'}
      ${{ message: 'error message' }} | ${'error message'}
    `('should emit error event', async ({ mockedValue, expectedResult }) => {
      createComponent(
        {},
        {
          projectRequestHandler: jest.fn().mockRejectedValue(mockedValue),
        },
      );

      toggleDropdown();

      toggleDropdown();
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[expectedResult]]);
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

    beforeEach(async () => {
      createComponent({ value: savedOnBackendTags });
      await waitForPromises();
    });

    it('select additional tags', async () => {
      await findDropdown().vm.$emit('select', ['development, linux', 'macos']);
      expect(wrapper.emitted('input')).toEqual([[['development, linux', 'macos']]]);
    });
  });

  describe('editing rights for regular users', () => {
    it.each`
      canEditRunnerTags | expectedResult
      ${false}          | ${true}
      ${true}           | ${false}
    `(
      'should be disabled for non-administrative users',
      async ({ canEditRunnerTags, expectedResult }) => {
        createComponent({ canEditRunnerTags });
        await waitForPromises();

        expect(findDropdown().props('disabled')).toBe(expectedResult);
      },
    );
  });
});
