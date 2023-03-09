import { GlLink, GlPopover, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MergeTrainHelperIcon from 'ee/vue_merge_request_widget/components/merge_train_helper_icon.vue';

describe('MergeTrainHelperIcon', () => {
  let wrapper;

  const helpLink = '/help/ci/pipelines/merge_trains.md#add-a-merge-request-to-a-merge-train';

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = () => {
    wrapper = shallowMount(MergeTrainHelperIcon);
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays the correct icon', () => {
    expect(findIcon().props('name')).toBe('question-o');
  });

  it('displays the correct help link', () => {
    expect(findLink().attributes('href')).toBe(helpLink);
  });

  it('displays the correct popover title', () => {
    expect(findPopover().props('title')).toBe('What is a merge train?');
  });

  it('displays the correct popover content', () => {
    expect(wrapper.text()).toContain(
      'A merge train is a queued list of merge requests waiting to be merged into the target branch. The changes in each merge request are combined with the changes in earlier merge requests and tested before merge',
    );
  });
});
