import { GlCollapsibleListbox, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerTagsList from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_filters/runner_tags_list.vue';
import RunnerTagsDropdown from 'ee/vue_shared/components/runner_tags_dropdown/runner_tags_dropdown.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  ACTION_RUNNER_TAG_MODE_SPECIFIC_TAG_KEY,
  ACTION_RUNNER_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
} from 'ee/security_orchestration/components/policy_editor/scan_execution/constants';

describe('RunnerTagsList', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMountExtended(RunnerTagsList, {
      propsData: {
        namespacePath: 'gitlab-org/testPath',
        ...propsData,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findTagsModeSwitcher = () => wrapper.findComponent(GlCollapsibleListbox);
  const findTagsList = () => wrapper.findComponent(RunnerTagsDropdown);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverLink = () => wrapper.findComponent(GlPopover).findComponent(GlLink);

  const switchTagsMode = async (mode = 'specific') => {
    const newMode =
      mode === 'specific'
        ? ACTION_RUNNER_TAG_MODE_SPECIFIC_TAG_KEY
        : ACTION_RUNNER_TAG_MODE_SELECTED_AUTOMATICALLY_KEY;
    await findTagsModeSwitcher().vm.$emit('select', newMode);
  };

  describe('error handling', () => {
    it('should emit event when tags list emits an error', async () => {
      createComponent();
      await switchTagsMode();
      await findTagsList().vm.$emit('error');

      expect(wrapper.emitted('error')).toHaveLength(1);
    });
  });

  describe('selected tags', () => {
    it('select additional tags', async () => {
      const existingTags = ['linux', 'macos'];
      const newTags = 'development';

      createComponent({ selectedTags: existingTags });

      await findTagsList().vm.$emit('input', [...existingTags, newTags]);
      expect(wrapper.emitted('input')).toEqual([[[...existingTags, newTags]]]);
    });
  });

  describe('switch mode', () => {
    it('should not have popover by default', () => {
      createComponent();
      expect(findPopover().exists()).toBe(false);
    });

    it('should have automatically selected tag mode by default', () => {
      createComponent();

      expect(findTagsModeSwitcher().props('selected')).toBe(
        ACTION_RUNNER_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
      );
      expect(findTagsList().exists()).toBe(false);
    });

    it('should show the tags list for specific tags mode', async () => {
      createComponent();
      await switchTagsMode();

      expect(findTagsModeSwitcher().props('selected')).toBe(
        ACTION_RUNNER_TAG_MODE_SPECIFIC_TAG_KEY,
      );
      expect(findTagsList().exists()).toBe(true);
    });

    it('resets selected tags when switched to automatically mode', async () => {
      createComponent({ selectedTags: ['macos'] });

      expect(findTagsList().props('value')).toMatchObject(['macos']);
      await switchTagsMode('auto');
      expect(wrapper.emitted('input')).toMatchObject([[[]]]);
    });
  });

  describe('no runners tagged', () => {
    describe('dropdowns', () => {
      beforeEach(async () => {
        createComponent();
        await switchTagsMode();
        await findTagsList().vm.$emit('tags-loaded', []);
      });

      it('should have disabled listbox', () => {
        expect(findTagsList().exists()).toBe(false);
      });

      it('should have default label text and title', () => {
        expect(findTagsModeSwitcher().props('disabled')).toBe(true);
        expect(findTagsModeSwitcher().props('selected')).toBe(
          ACTION_RUNNER_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
        );
      });
    });

    describe('popover', () => {
      it.each`
        namespaceType              | expectedLink
        ${NAMESPACE_TYPES.PROJECT} | ${'http://test.host/gitlab-org/testPath/-/runners'}
        ${NAMESPACE_TYPES.GROUP}   | ${'http://test.host/groups/gitlab-org/testPath/-/runners'}
      `('popover should exist when no tags exist', async ({ namespaceType, expectedLink }) => {
        await createComponent({ namespaceType });
        await switchTagsMode();
        await findTagsList().vm.$emit('tags-loaded', []);

        expect(findPopover().exists()).toBe(true);
        expect(findPopoverLink().attributes('href')).toBe(expectedLink);
        expect(findPopover().props('title')).toBe('No tags available');
        expect(findPopover().text()).toMatchInterpolatedText(
          'Scan will automatically choose a runner to run on because there are no tags exist on runners. You can %{linkStart}create a new tag in settings%{linkEnd}.',
        );
      });
    });
  });
});
