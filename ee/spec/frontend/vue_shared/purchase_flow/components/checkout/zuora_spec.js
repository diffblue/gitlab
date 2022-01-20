import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { merge } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { gitLabResolvers } from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';
import { STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import Zuora from 'ee/vue_shared/purchase_flow/components/checkout/zuora.vue';
import { stateData as initialStateData } from 'ee_jest/subscriptions/mock_data';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';
import axios from '~/lib/utils/axios_utils';
import flushPromises from 'helpers/flush_promises';

Vue.use(VueApollo);

describe('Zuora', () => {
  let axiosMock;
  let wrapper;

  const createComponent = (props = {}, data = {}, apolloLocalState = {}) => {
    const apolloProvider = createMockApolloProvider(STEPS, STEPS[1], gitLabResolvers);
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
    });
  };

  const findLoading = () => wrapper.findComponent(GlLoadingIcon);
  const findZuoraPayment = () => wrapper.find('#zuora_payment');

  beforeEach(() => {
    window.Z = {
      runAfterRender(fn) {
        return Promise.resolve().then(fn);
      },
      render: jest.fn(),
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

  describe.each(['', '111111'])('when rendering the iframe with account id: %s', (id) => {
    beforeEach(() => {
      wrapper = createComponent({ accountId: id }, { isLoading: false });
      wrapper.vm.zuoraScriptEl.onload();
      return flushPromises();
    });

    it(`calls render with ${id}`, () => {
      expect(window.Z.render).toHaveBeenCalledWith(
        {
          field_accountId: id,
          retainValues: 'true',
          style: 'inline',
          submitEnabled: 'true',
        },
        {},
        expect.any(Function),
      );
    });
  });
});
