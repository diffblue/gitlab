import { shallowMount } from '@vue/test-utils';

import Status from 'ee/compliance_dashboard/components/merge_requests/status.vue';
import Approval from 'ee/compliance_dashboard/components/merge_requests/statuses/approval.vue';
import Pipeline from 'ee/compliance_dashboard/components/merge_requests/statuses/pipeline.vue';

describe('Status component', () => {
  let wrapper;

  const createComponent = (status) => {
    return shallowMount(Status, {
      propsData: { status },
    });
  };

  const checkStatusComponentExists = (status, exists) => {
    switch (status.type) {
      case 'approval':
        return expect(wrapper.findComponent(Approval).exists()).toBe(exists);
      case 'pipeline':
        return expect(wrapper.findComponent(Pipeline).exists()).toBe(exists);
      default:
        throw new Error(`Unknown status type: ${status.type}`);
    }
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it.each`
      type          | data
      ${'approval'} | ${null}
      ${'approval'} | ${''}
      ${'pipeline'} | ${{}}
    `('does not render if given the status $value', (status) => {
      wrapper = createComponent(status);

      checkStatusComponentExists(status, false);
    });

    it.each`
      type          | data
      ${'approval'} | ${'success'}
      ${'pipeline'} | ${{ group: 'warning' }}
    `('renders if given the status $value', (status) => {
      wrapper = createComponent(status);

      checkStatusComponentExists(status, true);
    });
  });
});
