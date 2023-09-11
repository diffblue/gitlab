import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '@sentry/browser';
import addOnPurchaseQuery from 'ee/usage_quotas/add_on/graphql/get_add_on_purchase.query.graphql';
import CodeSuggestionsIntro from 'ee/usage_quotas/code_suggestions/components/code_suggestions_intro.vue';
import CodeSuggestionsUsage from 'ee/usage_quotas/code_suggestions/components/code_suggestions_usage.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { noAssignedAddonData, noPurchasedAddonData, purchasedAddonFuzzyData } from '../mock_data';

Vue.use(VueApollo);

jest.mock('@sentry/browser');

describe('Code Suggestions Usage', () => {
  let wrapper;

  const error = new Error('Something went wrong');
  const fullPath = 'namespace/full-path';
  const setTag = jest.fn();

  Sentry.withScope.mockImplementation((fn) => {
    const scope = { setTag };
    fn(scope);
  });

  const noAssignedAddonDataHandler = jest.fn().mockResolvedValue(noAssignedAddonData);
  const noPurchasedAddonDataHandler = jest.fn().mockResolvedValue(noPurchasedAddonData);
  const purchasedAddonFuzzyDataHandler = jest.fn().mockResolvedValue(purchasedAddonFuzzyData);
  const purchasedAddonErrorHandler = jest.fn().mockRejectedValue(error);

  const createMockApolloProvider = (handler = noPurchasedAddonDataHandler) =>
    createMockApollo([[addOnPurchaseQuery, handler]]);

  const findCodeSuggestionsIntro = () => wrapper.findComponent(CodeSuggestionsIntro);

  const createComponent = ({ handler } = {}) => {
    wrapper = shallowMount(CodeSuggestionsUsage, {
      provide: { fullPath },
      apolloProvider: createMockApolloProvider(handler),
    });

    return waitForPromises();
  };

  describe('with no code suggestions data', () => {
    beforeEach(() => {
      return createComponent();
    });

    it('renders code suggestions intro', () => {
      expect(findCodeSuggestionsIntro().exists()).toBe(true);
    });
  });

  describe('with code suggestions data', () => {
    beforeEach(() => {
      return createComponent({ handler: noAssignedAddonDataHandler });
    });

    it('does not render code suggestions intro', () => {
      expect(findCodeSuggestionsIntro().exists()).toBe(false);
    });
  });

  describe('with fuzzy code suggestions data', () => {
    beforeEach(() => {
      return createComponent({ handler: purchasedAddonFuzzyDataHandler });
    });

    it('renders code suggestions intro', () => {
      expect(findCodeSuggestionsIntro().exists()).toBe(true);
    });
  });

  describe('with errors', () => {
    beforeEach(() => {
      return createComponent({ handler: purchasedAddonErrorHandler });
    });

    it('renders code suggestions intro', () => {
      expect(findCodeSuggestionsIntro().exists()).toBe(true);
    });

    it('captures the error', () => {
      expect(Sentry.withScope).toHaveBeenCalled();
      expect(setTag).toHaveBeenCalledWith('vue_component', wrapper.vm.$options.name);
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });
});
