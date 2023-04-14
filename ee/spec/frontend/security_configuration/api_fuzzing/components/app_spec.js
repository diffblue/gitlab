import { GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import App from 'ee/security_configuration/api_fuzzing/components/app.vue';
import ConfigurationForm from 'ee/security_configuration/api_fuzzing/components/configuration_form.vue';
import apiFuzzingCiConfigurationQuery from 'ee/security_configuration/api_fuzzing/graphql/api_fuzzing_ci_configuration.query.graphql';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { apiFuzzingConfigurationQueryResponse } from '../mock_data';

Vue.use(VueApollo);

describe('EE - ApiFuzzingConfigurationApp', () => {
  let wrapper;
  const projectFullPath = 'namespace/project';
  const pendingHandler = jest.fn(() => new Promise(() => {}));
  const successHandler = jest.fn(() => apiFuzzingConfigurationQueryResponse);
  const createMockApolloProvider = (handler) =>
    createMockApollo([[apiFuzzingCiConfigurationQuery, handler]]);

  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findConfigurationForm = () => wrapper.findComponent(ConfigurationForm);

  const createWrapper = (options) => {
    wrapper = shallowMount(
      App,
      merge(
        {
          apolloProvider: () => createMockApolloProvider(successHandler),
          stubs: {
            GlSprintf,
            ConfigurationPageLayout,
          },
          provide: {
            fullPath: projectFullPath,
            apiFuzzingDocumentationPath: '/api_fuzzing/documentation/path',
          },
          data() {
            return {
              apiFuzzingCiConfiguration: {},
            };
          },
        },
        options,
      ),
    );
  };

  it('shows a loading spinner while fetching the configuration from the API', () => {
    createWrapper({
      apolloProvider: createMockApolloProvider(pendingHandler),
    });

    expect(pendingHandler).toHaveBeenCalledWith({ fullPath: projectFullPath });
    expect(findLoadingSpinner().exists()).toBe(true);
    expect(findConfigurationForm().exists()).toBe(false);
  });

  describe('configuration fetched successfully', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows the form once the configuration has loaded', () => {
      expect(findConfigurationForm().exists()).toBe(true);
      expect(findLoadingSpinner().exists()).toBe(false);
    });

    it('passes the configuration to the form', () => {
      expect(findConfigurationForm().props('apiFuzzingCiConfiguration')).toEqual(
        apiFuzzingConfigurationQueryResponse.data.project.apiFuzzingCiConfiguration,
      );
    });

    it('includes a link to API fuzzing documentation', () => {
      const link = wrapper.findComponent(GlLink);
      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe('/api_fuzzing/documentation/path');
    });
  });
});
