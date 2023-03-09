import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Component, { i18n } from 'ee/vue_shared/security_reports/components/create_jira_issue.vue';
import vulnerabilityExternalIssueLinkCreate from 'ee/vue_shared/security_reports/graphql/vulnerability_external_issue_link_create.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { vulnerabilityExternalIssueLinkCreateMockFactory } from './apollo_mocks';

describe('create_jira_issue', () => {
  let wrapper;

  const defaultProps = {
    vulnerabilityId: 1,
  };

  const findButton = () => wrapper.findComponent(GlButton);

  const clickOnButton = async () => {
    await findButton().trigger('click');
    return waitForPromises();
  };

  const successHandler = jest
    .fn()
    .mockResolvedValue(vulnerabilityExternalIssueLinkCreateMockFactory());
  const errorHandler = jest.fn().mockResolvedValue(
    vulnerabilityExternalIssueLinkCreateMockFactory({
      errors: ['foo'],
    }),
  );
  const pendingHandler = jest.fn().mockReturnValue(new Promise(() => {}));

  function createMockApolloProvider(handler) {
    Vue.use(VueApollo);
    const requestHandlers = [[vulnerabilityExternalIssueLinkCreate, handler]];

    return createMockApollo(requestHandlers);
  }

  const createComponent = (options = {}) => {
    wrapper = mount(Component, {
      apolloProvider: options.mockApollo,
      propsData: {
        ...defaultProps,
        ...options.propsData,
      },
    });
  };

  it('should render button with correct text in default variant', () => {
    createComponent();

    expect(findButton().exists()).toBe(true);
    expect(findButton().text()).toBe(i18n.createNewIssueLinkText);
  });

  it('should render button in correct variant as passed in as props', () => {
    createComponent({ propsData: { variant: 'info' } });

    expect(findButton().props().variant).toBe('info');
  });

  describe('given a pending response', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider(pendingHandler);

      createComponent({ mockApollo });
    });

    it('renders spinner correctly', async () => {
      const button = findButton();

      expect(button.props('loading')).toBe(false);

      await clickOnButton();

      expect(button.props('loading')).toBe(true);
    });
  });

  describe('given an error response', () => {
    beforeEach(async () => {
      const mockApollo = createMockApolloProvider(errorHandler);

      createComponent({ mockApollo });

      await clickOnButton();
    });

    it('show throw createJiraIssueError event with correct message', () => {
      expect(wrapper.emitted('create-jira-issue-error')).toEqual([['foo']]);
    });
  });

  describe('given an successful response', () => {
    beforeEach(async () => {
      const mockApollo = createMockApolloProvider(successHandler);

      createComponent({ mockApollo });

      await clickOnButton();
    });

    it('should emit mutated event', () => {
      expect(wrapper.emitted('mutated')).not.toBe(undefined);
    });
  });
});
