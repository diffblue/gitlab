import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MergeImmediatelyConfirmationDialog from 'ee/vue_merge_request_widget/components/merge_immediately_confirmation_dialog.vue';
import { trimText } from 'helpers/text_helper';

describe('MergeImmediatelyConfirmationDialog', () => {
  const docsUrl = 'path/to/merge/immediately/docs';
  let wrapper;

  beforeEach(async () => {
    wrapper = shallowMount(MergeImmediatelyConfirmationDialog, {
      propsData: { docsUrl },
      stubs: {
        GlSprintf,
      },
    });

    await nextTick();
  });

  it('should render informational text explaining why merging immediately can be dangerous', () => {
    expect(trimText(wrapper.text())).toContain(
      "Merging immediately isn't recommended as it may negatively impact the existing merge train. Read the documentation for more information. Are you sure you want to merge immediately?",
    );
  });

  it('should render a link to the documentation', () => {
    const docsLink = wrapper.findComponent(GlLink);

    expect(docsLink.exists()).toBe(true);
    expect(docsLink.attributes('href')).toBe(docsUrl);
    expect(trimText(docsLink.text())).toBe('documentation');
  });
});
