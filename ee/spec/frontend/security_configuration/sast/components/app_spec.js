import { GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { merge } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import SASTConfigurationApp, { i18n } from 'ee/security_configuration/sast/components/app.vue';
import ConfigurationForm from 'ee/security_configuration/sast/components/configuration_form.vue';
import sastCiConfigurationQuery from 'ee/security_configuration/sast/graphql/sast_ci_configuration.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { sastCiConfigurationQueryResponse } from '../mock_data';
import { specificErrorMessage, technicalErrorMessage } from '../constants';

Vue.use(VueApollo);

const sastDocumentationPath = '/help/sast';
const projectPath = 'namespace/project';

describe('SAST Configuration App', () => {
  let wrapper;

  const pendingHandler = () => new Promise(() => {});
  const successHandler = () => sastCiConfigurationQueryResponse;
  // Prefixed with window.gon.uf_error_prefix as used in lib/gitlab/utils/error_message.rb to indicate a user facing error
  const failureHandlerSpecific = () => ({
    errors: [{ message: `${window.gon.uf_error_prefix} ${specificErrorMessage}` }],
  });
  const failureHandlerGeneric = () => ({
    errors: [{ message: technicalErrorMessage }],
  });
  const createMockApolloProvider = (handler) =>
    createMockApollo([[sastCiConfigurationQuery, handler]]);

  const createComponent = (options) => {
    wrapper = shallowMountExtended(
      SASTConfigurationApp,
      merge(
        {
          // Use a function reference here so it's lazily initialized, and can
          // be replaced with other handlers in certain tests without
          // initialising twice.
          apolloProvider: () => createMockApolloProvider(successHandler),
          provide: {
            sastDocumentationPath,
            projectPath,
          },
        },
        options,
      ),
    );
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
        stubs: { GlSprintf, ConfigurationPageLayout },
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
        stubs: { GlSprintf, ConfigurationPageLayout },
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
      createComponent({
        apolloProvider: createMockApolloProvider(pendingHandler),
      });
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

  describe('when loading failed with Error Message including user facing keyword', () => {
    beforeEach(() => {
      createComponent({
        apolloProvider: createMockApolloProvider(failureHandlerSpecific),
      });
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

    it('shows specific error message without keyword and with link when defined', () => {
      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain('some specific error');
      expect(findErrorAlert().html()).toContain('<a href="#" rel="noopener">error</a>');
    });
  });

  describe('when loading failed with Error Message without user facing keyword', () => {
    beforeEach(() => {
      createComponent({
        apolloProvider: createMockApolloProvider(failureHandlerGeneric),
      });
      return waitForPromises();
    });

    it('shows generic error message when no specific message is defined', () => {
      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain(i18n.genericErrorText);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent();
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
