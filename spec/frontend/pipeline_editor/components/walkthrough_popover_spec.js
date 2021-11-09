import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import WalkthroughPopover from '~/pipeline_editor/components/walkthrough_popover.vue';
import pipelineEditorEventHub from '~/pipeline_editor/event_hub';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.config.ignoredElements = ['gl-emoji'];

describe('WalkthroughPopover component', () => {
  let wrapper;

  const createComponent = (mountFn = shallowMount) => {
    return extendedWrapper(mountFn(WalkthroughPopover));
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('CTA button clicked', () => {
    beforeEach(async () => {
      jest.spyOn(pipelineEditorEventHub, '$emit');
      wrapper = createComponent(mount);
      await wrapper.findByTestId('ctaBtn').trigger('click');
    });

    it('emits "walkthroughPopoverCtaClicked" event on Pipeline Editor eventHub', async () => {
      expect(pipelineEditorEventHub.$emit).toHaveBeenCalledWith('walkthroughPopoverCtaClicked');
    });
  });
});
