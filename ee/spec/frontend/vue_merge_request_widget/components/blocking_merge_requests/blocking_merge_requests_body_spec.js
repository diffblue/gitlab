import { shallowMount } from '@vue/test-utils';
import BlockingMergeRequestBody from 'ee/vue_merge_request_widget/components/blocking_merge_requests/blocking_merge_request_body.vue';
import RelatedIssuableItem from '~/issuable/components/related_issuable_item.vue';

describe('BlockingMergeRequestBody', () => {
  it('shows hidden merge request text if hidden MRs exist', () => {
    const wrapper = shallowMount(BlockingMergeRequestBody, {
      propsData: {
        issue: { hiddenCount: 10000000, id: 10 },
        status: 'string',
        isNew: true,
      },
    });

    expect(wrapper.html()).toContain("merge requests that you don't have access to");
  });

  it('does not show hidden merge request if hidden MRs do not exist', () => {
    const wrapper = shallowMount(BlockingMergeRequestBody, {
      propsData: {
        issue: { id: 10, reference: '#123' },
        status: 'string',
        isNew: true,
      },
    });

    expect(wrapper.html()).not.toContain("merge requests that you don't have access to");
    expect(wrapper.findComponent(RelatedIssuableItem).exists()).toBe(true);
  });
});
