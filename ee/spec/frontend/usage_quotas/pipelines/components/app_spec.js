import { GlButton } from '@gitlab/ui';
import { pushEECproductAddToCartEvent } from '~/google_tag_manager';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineUsageApp from 'ee/usage_quotas/pipelines/components/app.vue';
import { LABEL_BUY_ADDITIONAL_MINUTES } from 'ee/usage_quotas/pipelines/constants';
import { defaultProvide } from '../mock_data';

jest.mock('~/google_tag_manager');

describe('PipelineUsageApp', () => {
  let wrapper;

  const findBuyAdditionalMinutesButton = () =>
    wrapper.findByTestId('buy-additional-minutes-button');

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(PipelineUsageApp, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        GlButton,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Buy additional minutes Button', () => {
    it('calls pushEECproductAddToCartEvent on click', async () => {
      findBuyAdditionalMinutesButton().trigger('click');
      expect(pushEECproductAddToCartEvent).toHaveBeenCalledTimes(1);
    });

    describe('Gitlab SaaS: valid data for buyAdditionalMinutesPath and buyAdditionalMinutesTarget', () => {
      it('renders the button to buy additional minutes', () => {
        expect(findBuyAdditionalMinutesButton().exists()).toBe(true);
        expect(findBuyAdditionalMinutesButton().text()).toBe(LABEL_BUY_ADDITIONAL_MINUTES);
      });
    });

    describe('Gitlab Self-Managed: buyAdditionalMinutesPath and buyAdditionalMinutesTarget not provided', () => {
      beforeEach(() => {
        createComponent({
          provide: {
            buyAdditionalMinutesPath: undefined,
            buyAdditionalMinutesTarget: undefined,
          },
        });
      });

      it('does not render the button to buy additional minutes', () => {
        expect(findBuyAdditionalMinutesButton().exists()).toBe(false);
      });
    });
  });
});
