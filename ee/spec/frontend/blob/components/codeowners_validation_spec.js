import {
  GlIcon,
  GlCollapse,
  GlLink,
  GlSkeletonLoader,
  GlAccordion,
  GlAccordionItem,
} from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { createAlert } from '~/alert';
import { CODEOWNERS_VALIDATION_I18N, COLLAPSE_ID, DOCS_URL } from 'ee/blob/constants';
import CodeownersValidation from 'ee/blob/components/codeowners_validation.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import validateCodeownerFileQuery from 'ee/blob/queries/validate_codeowner_file.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { propsMock, validateCodeownerFile, valdateCodeownerFileNoErrors } from '../mock_data';

jest.mock('~/alert');
describe('codeowners validation', () => {
  let wrapper;

  const createComponent = async ({
    props = {},
    isResolved = true,
    validateCodeownerFileData = validateCodeownerFile,
  } = {}) => {
    Vue.use(VueApollo);

    const project = {
      id: 5,
      repository: {
        validateCodeownerFile: validateCodeownerFileData,
        __typename: 'Repository',
      },
      __typename: 'Project',
    };

    const mockResolver = isResolved
      ? jest.fn().mockResolvedValue({ data: { project } })
      : jest.fn().mockRejectedValue('Error');

    wrapper = mountExtended(CodeownersValidation, {
      apolloProvider: createMockApollo([[validateCodeownerFileQuery, mockResolver]]),
      propsData: {
        ...propsMock,
        ...props,
      },
    });
    await waitForPromises();
  };

  const findValidMessage = () => wrapper.findByTestId('valid-syntax-text');
  const findInvalidMessage = () => wrapper.findByTestId('invalid-syntax-text');
  const findCollapse = () => wrapper.findComponent(GlCollapse);
  const findCollapseToggle = () => wrapper.findByTestId('collapse-toggle');
  const findDocsLink = () => wrapper.findByTestId('docs-link');
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findAccordion = () => wrapper.findComponent(GlAccordion);
  const linksToErrors = () => wrapper.findComponent(GlAccordion).findAllComponents(GlLink);
  const findAccordionItems = () => wrapper.findAllComponents(GlAccordionItem);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);

  describe('loading state', () => {
    beforeEach(() => {
      createComponent();
    });
    it('renders loading state', () => {
      expect(findLoader().exists()).toBe(true);
    });
  });

  describe('when syntax is valid', () => {
    beforeEach(async () => {
      await createComponent({ validateCodeownerFileData: valdateCodeownerFileNoErrors });
    });

    it('renders expected icon', () => {
      const iconName = 'check';
      expect(findIcon().props('name')).toBe(iconName);
    });

    it('renders syntax is valid message', () => {
      expect(findValidMessage().text()).toBe(CODEOWNERS_VALIDATION_I18N.syntaxValid);
    });
  });

  describe('when errors are present', () => {
    beforeEach(async () => {
      await createComponent();
    });
    it('renders the invalid syntax text', () => {
      expect(findInvalidMessage().text()).toBe(
        CODEOWNERS_VALIDATION_I18N.syntaxErrors(validateCodeownerFile.total),
      );
    });

    it('renders collapse toggle with expected text', () => {
      expect(findCollapseToggle().text()).toBe(CODEOWNERS_VALIDATION_I18N.show);
    });

    it('renders collapse with expected id', () => {
      expect(findCollapse().attributes('id')).toBe(COLLAPSE_ID);
    });

    it('renders accordion', () => {
      expect(findAccordion().exists()).toBe(true);
    });

    it('renders accordion items', () => {
      expect(findAccordionItems()).toHaveLength(validateCodeownerFile.validationErrors.length);
    });

    it('renders links to line with error', () => {
      const firstErrorLink = linksToErrors().at(0);

      expect(linksToErrors()).toHaveLength(6);
      expect(firstErrorLink.text()).toBe('Line 2');
      expect(firstErrorLink.attributes('href')).toBe('#L2');
    });

    it('renders link to doc', () => {
      expect(findDocsLink().text()).toBe(CODEOWNERS_VALIDATION_I18N.docsLink);
      expect(findDocsLink().attributes('href')).toBe(DOCS_URL);
    });
  });

  describe('error state', () => {
    beforeEach(async () => {
      await createComponent({ isResolved: false });
    });
    it('alert with error message', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: CODEOWNERS_VALIDATION_I18N.errorMessage,
      });
    });
  });
});
