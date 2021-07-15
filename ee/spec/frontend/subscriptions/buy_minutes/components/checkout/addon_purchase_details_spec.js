import { GlAlert } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import { merge } from 'lodash';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import AddonPurchaseDetails from 'ee/subscriptions/buy_minutes/components/checkout/addon_purchase_details.vue';
import subscriptionsResolvers from 'ee/subscriptions/buy_minutes/graphql/resolvers';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import purchaseFlowResolvers from 'ee/vue_shared/purchase_flow/graphql/resolvers';
import { stateData as initialStateData } from 'ee_jest/subscriptions/buy_minutes/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('AddonPurchaseDetails', () => {
  const resolvers = { ...purchaseFlowResolvers, ...subscriptionsResolvers };
  let wrapper;

  const createMockApolloProvider = (stateData = {}) => {
    const mockApollo = createMockApollo([], resolvers);

    const data = merge({}, initialStateData, stateData);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: stateQuery,
      data,
    });

    return mockApollo;
  };

  const createComponent = (stateData = {}) => {
    const apolloProvider = createMockApolloProvider(stateData);

    return mount(AddonPurchaseDetails, {
      localVue,
      apolloProvider,
      stubs: {
        Step,
      },
    });
  };

  const findQuantity = () => wrapper.findComponent({ ref: 'quantity' });
  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findCiMinutesQuantityText = () => wrapper.find('[data-testid="ci-minutes-quantity-text"]');
  const isStepValid = () => wrapper.findComponent(Step).props('isValid');

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('sets the min quantity to 1', () => {
    expect(findQuantity().attributes('min')).toBe('1');
  });

  it('displays the alert', () => {
    expect(findGlAlert().isVisible()).toBe(true);
    expect(findGlAlert().text()).toMatchInterpolatedText(
      AddonPurchaseDetails.i18n.ciMinutesAlertText,
    );
  });

  it('displays the total CI minutes text', async () => {
    expect(findCiMinutesQuantityText().text()).toMatchInterpolatedText(
      'x 1,000 minutes per pack = 1,000 CI minutes',
    );
  });

  it('is valid', () => {
    expect(isStepValid()).toBe(true);
  });

  it('is invalid when quantity is less than 1', async () => {
    wrapper = createComponent({
      subscription: { namespaceId: 483, quantity: 0 },
    });

    await nextTick();

    expect(isStepValid()).toBe(false);
  });
});
