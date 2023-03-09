import { mountExtended } from 'helpers/vue_test_utils_helper';
import EnvironmentForm from '~/environments/components/environment_form.vue';

jest.mock('~/lib/utils/csrf');

const DEFAULT_PROPS = {
  environment: { name: '', externalUrl: '' },
  title: 'environment',
  cancelPath: '/cancel',
};

const PROVIDE = { protectedEnvironmentSettingsPath: '/projects/not_real/settings/ci_cd' };

describe('~/environments/components/form.vue', () => {
  let wrapper;

  const createWrapper = (propsData = {}) =>
    mountExtended(EnvironmentForm, {
      provide: PROVIDE,
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
    });

  describe('when an existing environment is being edited', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        environment: {
          id: 1,
          name: 'test',
          externalUrl: 'https://example.com',
        },
      });
    });

    it('does show protected environment documentation', () => {
      expect(wrapper.findByRole('link', { name: 'Protected environments' }).exists()).toBe(true);
    });
  });
});
