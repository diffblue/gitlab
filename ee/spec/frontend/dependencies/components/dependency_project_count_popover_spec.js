import { GlButton, GlPopover, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DependencyProjectCountPopover from 'ee/dependencies/components/dependency_project_count_popover.vue';

describe('DependencyProjectCountPopover component', () => {
  let wrapper;

  const TARGET_ID = 'target-id';
  const TARGET_TEXT = 'target-text';

  const factory = () => {
    wrapper = shallowMount(DependencyProjectCountPopover, {
      propsData: { targetId: TARGET_ID, targetText: TARGET_TEXT },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findTargetButton = () => wrapper.findComponent(GlButton);
  const findPopover = () => wrapper.findComponent(GlPopover);

  beforeEach(() => {
    factory();
  });

  it('renders target related components', () => {
    expect(findTargetButton().attributes('id')).toBe(TARGET_ID);
    expect(findTargetButton().text()).toBe(TARGET_TEXT);
  });

  it('renders popover related components', () => {
    expect(findPopover().props('title')).toBe('Project list unavailable');
    expect(findPopover().text()).toContain(
      'This group exceeds the maximum number of sub-groups of 600. We cannot accurately display a project list at this time. Please access a sub-group dependency list to view this information or see the',
    );
  });
});
