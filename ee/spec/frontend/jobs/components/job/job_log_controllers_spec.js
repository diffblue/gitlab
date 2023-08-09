import { mount } from '@vue/test-utils';
import EEJobLogControllers from 'ee/jobs/components/job/job_log_controllers.vue';
import JobLogControllers from '~/jobs/components/job/job_log_controllers.vue';
import { mockJobLog } from './mock_data';

describe('EE JobLogController', () => {
  let wrapper;

  const defaultProps = {
    rawPath: '/raw',
    size: 511952,
    isScrollTopDisabled: false,
    isScrollBottomDisabled: false,
    isScrollingDown: true,
    isJobLogSizeVisible: true,
    isComplete: true,
    jobLog: mockJobLog,
  };

  const createComponent = (props) => {
    wrapper = mount(EEJobLogControllers, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        aiRootCauseAnalysisAvailable: true,
      },
    });
  };

  const findJobLogController = () => wrapper.findComponent(JobLogControllers);

  describe('when the underlying event is triggered', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      eventName               | parameter
      ${'scrollJobLogTop'}    | ${undefined}
      ${'scrollJobLogBottom'} | ${undefined}
      ${'searchResults'}      | ${'searchResults'}
    `('should re-trigger events', ({ eventName, parameter }) => {
      findJobLogController().vm.$emit(eventName, parameter);

      expect(wrapper.emitted(eventName)[0][0]).toBe(parameter);
    });
  });
});
