import { GlButton, GlPopover, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RunnerTagsList from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/runner_tags_list.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { createMockApolloProvider } from 'ee_jest/vue_shared/components/runner_tags_dropdown/mocks/apollo_mock';
import {
  POLICY_ACTION_TAG_MODE_SPECIFIC_TAG_KEY,
  POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';

describe('RunnerTagsList', () => {
  let wrapper;

  const createComponent = (propsData = {}, apolloOptions = { handlers: undefined }) => {
    const { apolloProvider } = createMockApolloProvider(apolloOptions);

    wrapper = mountExtended(RunnerTagsList, {
      apolloProvider,
      propsData: {
        namespacePath: 'gitlab-org/testPath',
        ...propsData,
      },
    });
  };

  const findTagsModeSwitcher = () => wrapper.findByTestId('runner-tags-switcher');
  const findTagsList = () => wrapper.findByTestId('runner-tags-list');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverLink = () => wrapper.findComponent(GlPopover).findComponent(GlLink);

  beforeEach(async () => {
    createComponent();
    await waitForPromises();
  });

  describe('error handling', () => {
    it('should emit error event', async () => {
      createComponent({}, { handlers: jest.fn().mockRejectedValue({ error: new Error() }) });
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

    it('select additional tags', async () => {
      createComponent({ value: savedOnBackendTags });
      await waitForPromises();

      await findTagsList().vm.$emit('input', ['development, linux', 'macos']);
      expect(wrapper.emitted('input')).toEqual([[['development, linux', 'macos']]]);
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

      expect(findTagsList().props('value')).toMatchObject(['macos']);

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

      createComponent({
        value: savedOnBackendTags,
      });
      await waitForPromises();
      await findTagsList().vm.$emit('tags-loaded', []);
    });

    it('should have disabled listbox', () => {
      expect(findTagsList().exists()).toBe(false);
    });

    it('should have default label text and title', () => {
      expect(findTagsModeSwitcher().props('disabled')).toBe(true);
      expect(findTagsModeSwitcher().findComponent(GlButton).text()).toBe('selected automatically');
    });
  });

  describe('popover', () => {
    it('should not have popover if runner tags exist', () => {
      expect(findPopover().exists()).toBe(false);
    });

    it.each`
      namespaceType              | expectedLink
      ${NAMESPACE_TYPES.PROJECT} | ${'http://test.host/gitlab-org/testPath/-/runners'}
      ${NAMESPACE_TYPES.GROUP}   | ${'http://test.host/groups/gitlab-org/testPath/-/runners'}
    `('popover should exist when no tags exist', async ({ namespaceType, expectedLink }) => {
      createComponent({ namespaceType });
      await findTagsList().vm.$emit('tags-loaded', []);

      expect(findPopover().exists()).toBe(true);
      expect(findPopoverLink().attributes('href')).toBe(expectedLink);
      expect(findPopover().props('title')).toBe(
        RunnerTagsList.i18n.runnersDisabledStatePopoverTitle,
      );
      expect(findPopover().text()).toMatchInterpolatedText(
        RunnerTagsList.i18n.runnersDisabledStatePopoverContent,
      );
    });
  });
});
