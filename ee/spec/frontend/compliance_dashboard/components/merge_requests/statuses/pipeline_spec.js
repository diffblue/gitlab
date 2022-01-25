import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import Pipeline from 'ee/compliance_dashboard/components/merge_requests/statuses/pipeline.vue';
import { createPipelineStatus } from '../../../mock_data';

describe('Pipeline component', () => {
  let wrapper;

  const findCiIcon = () => wrapper.find('.ci-icon');
  const findCiLink = () => wrapper.findComponent(GlLink);

  const createComponent = (status) => {
    return shallowMount(Pipeline, {
      propsData: { status },
      stubs: {
        CiIcon: {
          props: { status: Object },
          template: `<div class="ci-icon">{{ status.group }}</div>`,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with a pipeline', () => {
    const pipeline = createPipelineStatus('success');

    beforeEach(() => {
      wrapper = createComponent(pipeline);
    });

    it('links to the pipeline', () => {
      expect(findCiLink().attributes('href')).toEqual(pipeline.details_path);
    });

    it('renders a CI icon with the pipeline status', () => {
      expect(findCiIcon().text()).toEqual(pipeline.group);
    });
  });
});
