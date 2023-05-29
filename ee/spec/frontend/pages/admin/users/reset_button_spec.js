import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import ResetButton from 'ee/pages/admin/users/pipeline_minutes/reset_button.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_SERVICE_UNAVAILABLE } from '~/lib/utils/http_status';

const defaultProps = { resetMinutesPath: '/adming/reset_minutes' };
const $toast = {
  show: jest.fn(),
};

describe('Reset compute usage button', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    wrapper = mount(ResetButton, {
      provide: {
        ...defaultProps,
      },
      mocks: {
        $toast,
      },
    });

    mock = new MockAdapter(axios);
  });

  const findResetButton = () => wrapper.findComponent(GlButton);

  it('should contain a button with the "Reset compute usage" text', () => {
    const button = findResetButton();

    expect(button.text()).toBe('Reset compute usage');
  });

  describe('when the api is available', () => {
    beforeEach(() => {
      mock.onPost(defaultProps.resetMinutesPath).reply(HTTP_STATUS_OK, { status: HTTP_STATUS_OK });
    });

    afterEach(() => {
      mock.restore();
    });

    it('should create a network request when the reset button is clicked', async () => {
      const axiosSpy = jest.spyOn(axios, 'post');

      const button = findResetButton();

      button.vm.$emit('click');
      await nextTick();

      expect(button.props('loading')).toBe(true);

      await axios.waitForAll();

      expect(axiosSpy).toHaveBeenCalled();
      expect($toast.show).toHaveBeenCalledWith('Successfully reset compute usage for namespace.');
      expect(button.props('loading')).toBe(false);
    });
  });

  describe('when the api is not available', () => {
    beforeEach(() => {
      mock.onPost(defaultProps.resetMinutesPath).reply(HTTP_STATUS_SERVICE_UNAVAILABLE, {
        status: HTTP_STATUS_SERVICE_UNAVAILABLE,
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('should show a toast error message', async () => {
      const axiosSpy = jest.spyOn(axios, 'post');

      const button = findResetButton();

      button.vm.$emit('click');

      await axios.waitForAll();

      expect(axiosSpy).toHaveBeenCalled();
      expect($toast.show).toHaveBeenCalledWith(
        'An error occurred while resetting the compute usage.',
      );
    });
  });
});
