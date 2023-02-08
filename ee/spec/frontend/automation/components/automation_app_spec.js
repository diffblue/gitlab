import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Automation from 'ee/automation/automation_app.vue';

describe('ee/automation/automation_app.vue', () => {
  let wrapper;

  const createWrapper = (data = {}) => {
    wrapper = shallowMountExtended(Automation, {
      data() {
        return {
          ...data,
        };
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render', () => {
      expect(wrapper.exists()).toBe(true);
    });
  });
});
