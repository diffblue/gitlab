import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import { resolvers } from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';
import { STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import Zuora from 'ee/vue_shared/purchase_flow/components/checkout/zuora.vue';
import { stateData as initialStateData } from 'ee_jest/subscriptions/buy_minutes/mock_data';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';
import axios from '~/lib/utils/axios_utils';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Zuora', () => {
  let axiosMock;
  let wrapper;

  const createComponent = (props = {}, data = {}, apolloLocalState = {}) => {
    const apolloProvider = createMockApolloProvider(STEPS, STEPS[1], {
      ...resolvers,
    });
    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: stateQuery,
      data: merge({}, initialStateData, apolloLocalState),
    });

    return shallowMount(Zuora, {
      propsData: {
        active: true,
        ...props,
      },
      data() {
        return { ...data };
      },
      localVue,
    });
  };

  const findLoading = () => wrapper.find(GlLoadingIcon);
  const findZuoraPayment = () => wrapper.find('#zuora_payment');

  beforeEach(() => {
    window.Z = {
      runAfterRender(fn) {
        return Promise.resolve().then(fn);
      },
      render() {},
    };

    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(`/-/subscriptions/payment_form`).reply(200, {});
  });

  afterEach(() => {
    delete window.Z;
    wrapper.destroy();
  });

  describe('when active', () => {
    beforeEach(async () => {
      wrapper = createComponent({}, { isLoading: false });
    });

    it('shows the loading icon', () => {
      expect(findLoading().exists()).toBe(true);
    });

    it('the zuora_payment selector should be hidden', () => {
      expect(findZuoraPayment().isVisible()).toBe(false);
    });

    describe('when toggling the loading indicator', () => {
      beforeEach(() => {
        wrapper = createComponent({}, { isLoading: true });
        wrapper.vm.zuoraScriptEl.onload();
      });

      it('shows the loading icon', () => {
        expect(findLoading().exists()).toBe(true);
      });

      it('the zuora_payment selector should not be visible', () => {
        expect(findZuoraPayment().isVisible()).toBe(false);
      });
    });
  });

  describe('when not active', () => {
    beforeEach(() => {
      wrapper = createComponent({ active: false });
    });

    it('the zuora_payment selector should not be visible', () => {
      expect(findZuoraPayment().isVisible()).toBe(false);
    });
  });
});
