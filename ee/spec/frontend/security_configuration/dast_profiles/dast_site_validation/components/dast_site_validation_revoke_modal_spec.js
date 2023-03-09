import { GlAlert, GlModal } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { mount, shallowMount } from '@vue/test-utils';
import merge from 'lodash/merge';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import DastSiteValidationRevokeModal from 'ee/security_configuration/dast_site_validation/components/dast_site_validation_revoke_modal.vue';
import dastSiteValidationRevokeMutation from 'ee/security_configuration/dast_site_validation/graphql/dast_site_validation_revoke.mutation.graphql';
import createApolloProvider from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as responses from '../mock_data/apollo_mock';

Vue.use(VueApollo);

const fullPath = 'group/project';
const targetUrl = 'https://example.com/home';
const normalizedTargetUrl = 'https://example.com:443';
const profileCount = 3;

const defaultProps = {
  fullPath,
  targetUrl,
  normalizedTargetUrl,
  profileCount,
};

const defaultRequestHandlers = {
  dastSiteValidationRevoke: jest.fn().mockResolvedValue(responses.dastSiteValidationRevoke()),
};

describe('DastSiteValidationRevokeModal', () => {
  let wrapper;
  let requestHandlers;

  const componentFactory = (mountFn = shallowMount) => ({
    mountOptions = {},
    handlers = {},
  } = {}) => {
    requestHandlers = { ...defaultRequestHandlers, ...handlers };
    wrapper = mountFn(
      DastSiteValidationRevokeModal,
      merge(
        {},
        {
          propsData: defaultProps,
          attrs: {
            static: true,
            visible: true,
          },
        },
        mountOptions,
        {
          apolloProvider: createApolloProvider([
            [dastSiteValidationRevokeMutation, requestHandlers.dastSiteValidationRevoke],
          ]),
        },
      ),
    );
  };
  const createComponent = componentFactory();
  const createFullComponent = componentFactory(mount);

  const withinComponent = () => within(wrapper.findComponent(GlModal).element);
  const findByTestId = (id) => wrapper.find(`[data-testid="${id}"`);
  const findRevokeButton = () => findByTestId('revoke-validation-button');

  it("calls GlModal's show method when own show method is called", () => {
    const showMock = jest.fn();
    createComponent({
      mountOptions: {
        stubs: {
          GlModal: {
            render: () => {},
            methods: {
              show: showMock,
            },
          },
        },
      },
    });
    wrapper.vm.show();

    expect(showMock).toHaveBeenCalled();
  });

  describe('default state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders no alert', () => {
      expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
    });

    it('renders warning message', () => {
      expect(wrapper.text()).toBe('This will affect 3 other profiles targeting the same URL.');
    });
  });

  describe('actions', () => {
    describe('success', () => {
      beforeEach(() => {
        createFullComponent();
      });

      it('triggers the dastSiteValidationRevoke GraphQL mutation', () => {
        findRevokeButton().trigger('click');

        expect(requestHandlers.dastSiteValidationRevoke).toHaveBeenCalledWith({
          fullPath,
          normalizedTargetUrl,
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        createFullComponent({
          handlers: {
            dastSiteValidationRevoke: jest
              .fn()
              .mockRejectedValue(new Error('GraphQL Network Error')),
          },
        });
      });

      it('renders an alert when revocation failed', async () => {
        findRevokeButton().trigger('click');
        await waitForPromises();

        expect(wrapper.findComponent(GlAlert).exists()).toBe(true);
        expect(
          withinComponent().getByText('Could not revoke validation. Please try again.'),
        ).not.toBe(null);
      });
    });
  });
});
