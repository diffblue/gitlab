import { shallowMount } from '@vue/test-utils';
import SummaryNote from 'ee/merge_requests/components/summary_note.vue';

let wrapper;

function createComponent(summary) {
  wrapper = shallowMount(SummaryNote, {
    propsData: { summary },
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
});
