import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import PipelineStatusBadge from 'ee/security_dashboard/components/shared/pipeline_status_badge.vue';

describe('Pipeline status badge', () => {
  let wrapper;

  const securityBuildsFailedPath = '/some/path/to/failed/jobs';

  const findGlBadge = () => wrapper.findComponent(GlBadge);

  const createProps = (securityBuildsFailedCount) => ({ pipeline: { securityBuildsFailedCount } });

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(PipelineStatusBadge, {
      propsData: merge({ pipeline: { securityBuildsFailedPath } }, props),
    });
  };

  describe.each`
    failedCount | expectedMessage
    ${7}        | ${'7 failed security jobs'}
    ${1}        | ${'1 failed security job'}
  `('when there are failed jobs ($failedCount)', ({ failedCount, expectedMessage }) => {
    beforeEach(() => {
      createWrapper(createProps(failedCount));
    });

    it('displays correct message', () => {
      expect(wrapper.text()).toBe(expectedMessage);
    });

    it('links to the correct path', () => {
      expect(findGlBadge().attributes('href')).toBe(securityBuildsFailedPath);
    });
  });

  describe('when there are not more than 0 failed jobs', () => {
    it('does not display when there are 0 failed jobs', () => {
      createWrapper(createProps(0));
      expect(findGlBadge().exists()).toBe(false);
    });

    it('does not display when there is no failed jobs count', () => {
      createWrapper();
      expect(findGlBadge().exists()).toBe(false);
    });
  });
});
