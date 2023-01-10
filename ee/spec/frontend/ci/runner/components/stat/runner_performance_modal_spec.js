import { GlCard, GlSprintf, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { __ } from '~/locale';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import RunnerPerformanceModal from 'ee_component/ci/runner/components/stat/runner_performance_modal.vue';
import runnersJobsQueueDurationQuery from 'ee/ci/runner/graphql/list/runners_jobs_queue_duration.query.graphql';

import { INSTANCE_TYPE } from '~/ci/runner/constants';

Vue.use(VueApollo);

const MOCK_MODAL_ID = 'mock-modal-id';

describe('RunnerPerformanceModal', () => {
  let wrapper;
  let runnersJobsQueueDurationHandler;

  const findModal = () => wrapper.findComponent(GlModal);

  const createComponent = ({ props, ...options } = {}) => {
    wrapper = shallowMount(RunnerPerformanceModal, {
      propsData: {
        modalId: MOCK_MODAL_ID,
        ...props,
      },
      stubs: {
        GlCard,
        GlSprintf,
      },
      apolloProvider: createMockApollo([
        [runnersJobsQueueDurationQuery, runnersJobsQueueDurationHandler],
      ]),
      ...options,
    });
  };

  beforeEach(() => {
    runnersJobsQueueDurationHandler = jest.fn();
  });

  it('modal is shown', () => {
    createComponent();

    expect(findModal().props()).toMatchObject({
      actionCancel: { text: __('Cancel') },
      modalId: MOCK_MODAL_ID,
      noFocusOnShow: true,
      size: 'sm',
    });
  });

  it('does not load data when modal is not shown', () => {
    createComponent();
    expect(runnersJobsQueueDurationHandler).not.toHaveBeenCalled();

    expect(wrapper.text()).toContain('- seconds');
  });

  describe.each`
    p50     | text
    ${0}    | ${'0 seconds'}
    ${1}    | ${'1 second'}
    ${5}    | ${'5 seconds'}
    ${9999} | ${'9,999 seconds'}
    ${null} | ${'- seconds'}
  `('Renders a "$text" value', ({ p50, text }) => {
    beforeEach(() => {
      runnersJobsQueueDurationHandler = jest.fn().mockResolvedValue({
        data: {
          runners: {
            jobsStatistics: {
              queuedDuration: {
                p50,
              },
            },
          },
        },
      });

      createComponent();
      findModal().vm.$emit('shown');
    });

    it('shows a loading state', () => {
      expect(wrapper.text()).toEqual(expect.stringContaining('- seconds'));
    });

    it('requests job duration stats', () => {
      expect(runnersJobsQueueDurationHandler).toHaveBeenCalledTimes(1);
      expect(runnersJobsQueueDurationHandler).toHaveBeenCalledWith({ type: INSTANCE_TYPE });
    });

    it('shows result', async () => {
      await waitForPromises();

      expect(wrapper.text()).toContain(text);
    });
  });
});
