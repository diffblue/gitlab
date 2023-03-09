import { shallowMount } from '@vue/test-utils';
import MergeTrainFailedPipelineConfirmationDialog from 'ee/vue_merge_request_widget/components/merge_train_failed_pipeline_confirmation_dialog.vue';
import { trimText } from 'helpers/text_helper';

describe('MergeTrainFailedPipelineConfirmationDialog', () => {
  let wrapper;

  const hideDropdown = jest.fn();

  const GlModal = {
    template: `
      <div>
        <slot></slot>
        <slot name="modal-footer"></slot>
      </div>
    `,
    methods: {
      hide: hideDropdown,
    },
  };

  const createComponent = () => {
    wrapper = shallowMount(MergeTrainFailedPipelineConfirmationDialog, {
      propsData: {
        visible: true,
      },
      stubs: {
        GlModal,
      },
      attachTo: document.body,
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findStartMergeTrainBtn = () => wrapper.find('[data-testid="start-merge-train"]');
  const findCancelBtn = () => wrapper.findComponent({ ref: 'cancelButton' });

  beforeEach(() => {
    createComponent();
  });

  it('should render informational text explaining why merging immediately can be dangerous', () => {
    expect(trimText(wrapper.text())).toContain(
      'The latest pipeline for this merge request has failed. Are you sure you want to attempt to merge?',
    );
  });

  it('should emit the startMergeTrain event', () => {
    findStartMergeTrainBtn().vm.$emit('click');

    expect(wrapper.emitted('startMergeTrain')).toHaveLength(1);
  });

  it('when the cancel button is clicked should emit cancel and call hide', () => {
    findCancelBtn().vm.$emit('click');

    expect(wrapper.emitted('cancel')).toHaveLength(1);
    expect(hideDropdown).toHaveBeenCalled();
  });

  it('should emit cancel when the hide event is emitted', () => {
    findModal().vm.$emit('hide');

    expect(wrapper.emitted('cancel')).toHaveLength(1);
  });

  it('when modal is shown it will focus the cancel button', () => {
    findCancelBtn().element.focus = jest.fn();

    findModal().vm.$emit('shown');

    expect(findCancelBtn().element.focus).toHaveBeenCalled();
  });
});
