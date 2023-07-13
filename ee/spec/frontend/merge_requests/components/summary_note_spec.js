import { shallowMount } from '@vue/test-utils';
import SummaryNote from 'ee/merge_requests/components/summary_note.vue';
import SummaryNoteWrapper from 'ee/merge_requests/components/summary_note_wrapper.vue';

let wrapper;

function createComponent(summary) {
  wrapper = shallowMount(SummaryNote, {
    stubs: { SummaryNoteWrapper },
    propsData: { summary, type: 'summary' },
  });
}

describe('Merge request summary note component', () => {
  it('renders summary note', () => {
    createComponent({
      createdAt: 'created-at',
      content: 'AI content',
    });

    expect(wrapper.html()).toMatchSnapshot();
  });

  it('renders review note', () => {
    createComponent({
      createdAt: 'created-at',
      content: 'AI content',
      reviewLlmSummaries: [{ content: 'review', createdAt: 'created-at' }],
    });

    expect(wrapper.html()).toMatchSnapshot();
  });
});
