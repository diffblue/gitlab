import { GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import SASTConfigurationApp, { i18n } from 'ee/security_configuration/sast/components/app.vue';
import ConfigurationForm from 'ee/security_configuration/sast/components/configuration_form.vue';
import sastCiConfigurationQuery from 'ee/security_configuration/sast/graphql/sast_ci_configuration.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { sastCiConfigurationQueryResponse } from '../mock_data';
import { specificErrorMessage } from '../constants';

Vue.use(VueApollo);

const sastDocumentationPath = '/help/sast';
const projectPath = 'namespace/project';

describe('SAST Configuration App', () => {
  let wrapper;

  const pendingHandler = () => new Promise(() => {});
  const successHandler = () => sastCiConfigurationQueryResponse;
  const failureHandler = jest.fn().mockRejectedValue(new Error('Error'));
  const failureHandlerGraphQL = () => ({ errors: [{ message: specificErrorMessage }] });

  const createMockApolloProvider = (handler) => {
    return createMockApollo([[sastCiConfigurationQuery, handler]]);
  };

  const createComponent = ({ options, customMock } = {}) => {
    wrapper = mountExtended(SASTConfigurationApp, {
      apolloProvider: customMock || createMockApolloProvider(successHandler),
      provide: {
        sastDocumentationPath,
        projectPath,
      },
      options,
    });
    return waitForPromises();
  };

  const findHeader = () => wrapper.find('header');
  const findSubHeading = () => findHeader().find('p');
  const findLink = (container = wrapper) => container.findComponent(GlLink);
  const findConfigurationForm = () => wrapper.findComponent(ConfigurationForm);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findErrorAlert = () => wrapper.findByTestId('error-alert');
  const findFeedbackAlert = () => wrapper.findByTestId('configuration-page-alert');

  describe('feedback alert', () => {
    beforeEach(() => {
      createComponent({
        options: { stubs: { GlSprintf, ConfigurationPageLayout } },
      });
    });

    it('should be displayed', () => {
      expect(findFeedbackAlert().exists()).toBe(true);
    });

    it('links to the feedback issue', () => {
      const link = findFeedbackAlert().findComponent(GlLink);
      expect(link.attributes()).toMatchObject({
        href: SASTConfigurationApp.feedbackIssue,
        target: '_blank',
      });
    });
  });

  describe('header', () => {
    beforeEach(() => {
      createComponent({
        options: { stubs: { GlSprintf, ConfigurationPageLayout } },
      });
    });

    it('displays a link to sastDocumentationPath', () => {
      expect(findLink(findHeader()).attributes('href')).toBe(sastDocumentationPath);
    });

    it('displays the subheading', () => {
      expect(findSubHeading().text()).toMatchInterpolatedText(SASTConfigurationApp.i18n.helpText);
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({ customMock: createMockApolloProvider(pendingHandler) });
    });

    it('displays a loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not display the configuration form', () => {
      expect(findConfigurationForm().exists()).toBe(false);
    });

    it('does not display an alert message', () => {
      expect(findErrorAlert().exists()).toBe(false);
    });
  });

  describe('when loading failed with a GraphQl error', () => {
    beforeEach(() => {
      createComponent({ customMock: createMockApolloProvider(failureHandlerGraphQL) });
      return waitForPromises();
    });

    it('does not display a loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not display the configuration form', () => {
      expect(findConfigurationForm().exists()).toBe(false);
    });

    it('displays an alert message', () => {
      expect(findErrorAlert().exists()).toBe(true);
    });

    it('shows a specific error message with link when defined', () => {
      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain('some specific error');
      expect(findErrorAlert().html()).toContain('<a href="#" rel="noopener">error</a>');
    });
  });

  describe('when loading failed with a network error', () => {
    beforeEach(() => {
      createComponent({ customMock: createMockApolloProvider(failureHandler) });
      return waitForPromises();
    });

    it('shows generic error message when no specific message is defined', () => {
      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain(i18n.genericErrorText);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent({ customMock: createMockApolloProvider(successHandler) });
    });

    it('does not display a loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays the configuration form', () => {
      expect(findConfigurationForm().exists()).toBe(true);
    });

    it('passes the sastCiConfiguration to the sastCiConfiguration prop', () => {
      expect(findConfigurationForm().props('sastCiConfiguration')).toEqual(
        sastCiConfigurationQueryResponse.data.project.sastCiConfiguration,
      );
    });

    it('does not display an alert message', () => {
      expect(findErrorAlert().exists()).toBe(false);
    });
  });
});
