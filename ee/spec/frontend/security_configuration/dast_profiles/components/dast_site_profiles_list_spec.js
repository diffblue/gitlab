import { within } from '@testing-library/dom';
import Vue, { nextTick } from 'vue';
import { merge } from 'lodash';
import { GlButton, GlTable } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import ProfilesList from 'ee/security_configuration/dast_profiles/components/dast_profiles_list.vue';
import Component from 'ee/security_configuration/dast_profiles/components/dast_site_profiles_list.vue';
import { updateSiteProfilesStatuses } from 'ee/security_configuration/dast_profiles/graphql/cache_utils';
import {
  DAST_SITE_VALIDATION_STATUS,
  DAST_SITE_VALIDATION_MODAL_ID,
  DAST_SITE_VALIDATION_REVOKE_MODAL_ID,
} from 'ee/security_configuration/dast_site_validation/constants';
import dastSiteValidationsQuery from 'ee/security_configuration/dast_site_validation/graphql/dast_site_validations.query.graphql';
import createApolloProvider from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as responses from '../mocks/apollo_mock';
import { siteProfiles } from '../mocks/mock_data';

jest.mock('ee/security_configuration/dast_profiles/graphql/cache_utils', () => ({
  updateSiteProfilesStatuses: jest.fn(),
}));

describe('EE - DastSiteProfileList', () => {
  let wrapper;
  let requestHandlers;
  let apolloProvider;

  const defaultProps = {
    profiles: [],
    tableLabel: 'Site profiles',
    fields: [{ key: 'profileName' }, { key: 'targetUrl' }, { key: 'validationStatus' }],
    profilesPerPage: 10,
    noProfilesMessage: 'no site profiles created yet',
    errorMessage: '',
    errorDetails: [],
    fullPath: '/namespace/project',
    hasMoreProfilesToLoad: false,
    isLoading: false,
  };

  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);
    requestHandlers = handlers;
    return createApolloProvider([[dastSiteValidationsQuery, requestHandlers.dastSiteValidations]]);
  };

  const wrapperFactory = (mountFn = shallowMount) => (options = {}, handlers) => {
    apolloProvider = handlers && createMockApolloProvider(handlers);
    wrapper = mountFn(
      Component,
      merge(
        {
          propsData: defaultProps,
        },
        { ...options, apolloProvider },
      ),
    );
  };
  const createComponent = wrapperFactory();
  const createFullComponent = wrapperFactory(mount);

  const withinComponent = () => within(wrapper.element);
  const getTable = () => withinComponent().getByRole('table', { name: /profiles/i });
  const getAllRowGroups = () => within(getTable()).getAllByRole('rowgroup');
  const getTableBody = () => {
    // first item is the table head
    const [, tableBody] = getAllRowGroups();
    return tableBody;
  };
  const getAllTableRows = () => within(getTableBody()).getAllByRole('row');
  const getTableRowForProfile = (profile) => getAllTableRows()[siteProfiles.indexOf(profile)];

  const findProfileList = () => wrapper.findComponent(ProfilesList);
  const findButtons = (f) => wrapper.findAllComponents(GlButton).filter(f);
  const findSetProfileButtons = () =>
    findButtons((b) => b.attributes('data-testid') === 'set-profile-button');
  const findDastSiteValidationModal = () =>
    wrapper.findComponent({ ref: DAST_SITE_VALIDATION_MODAL_ID });
  const findDastSiteValidationRevokeModal = () =>
    wrapper.findComponent({ ref: DAST_SITE_VALIDATION_REVOKE_MODAL_ID });
  const getCell = (trIdx, tdIdx) => {
    return wrapper
      .findComponent(GlTable)
      .find('tbody')
      .findAll('tr')
      .at(trIdx)
      .findAll('td')
      .at(tdIdx);
  };

  afterEach(() => {
    apolloProvider = null;
  });

  it('renders profile list properly', () => {
    createComponent({
      propsData: { profiles: siteProfiles },
    });

    expect(findProfileList().exists()).toBe(true);
  });

  it('passes down the props properly', () => {
    createFullComponent();

    expect(findProfileList().props()).toEqual(defaultProps);
  });

  it('sets listeners on profile list component', () => {
    const inputHandler = jest.fn();
    createComponent({
      listeners: {
        input: inputHandler,
      },
    });
    findProfileList().vm.$emit('input');

    expect(inputHandler).toHaveBeenCalled();
  });

  describe('site validation', () => {
    const [pendingValidation, inProgressValidation] = siteProfiles;
    const urlsPendingValidation = [
      pendingValidation.normalizedTargetUrl,
      inProgressValidation.normalizedTargetUrl,
    ];

    beforeEach(() => {
      createFullComponent(
        { propsData: { profiles: siteProfiles } },
        {
          dastSiteValidations: jest.fn().mockResolvedValue(
            responses.dastSiteValidations([
              {
                normalizedTargetUrl: pendingValidation.normalizedTargetUrl,
                status: DAST_SITE_VALIDATION_STATUS.FAILED,
                validationStartedAt: '2022-10-31T15:47:21Z',
              },
              {
                normalizedTargetUrl: inProgressValidation.normalizedTargetUrl,
                status: DAST_SITE_VALIDATION_STATUS.PASSED,
                validationStartedAt: new Date(Date.now() - 1000 * 60 * 30),
              },
            ]),
          ),
        },
      );
    });

    describe.each`
      status           | statusEnum                                | statusLabel            | buttonLabel            | isBtnDisabled
      ${'no'}          | ${DAST_SITE_VALIDATION_STATUS.NONE}       | ${''}                  | ${'Validate'}          | ${false}
      ${'pending'}     | ${DAST_SITE_VALIDATION_STATUS.PENDING}    | ${'Validating...'}     | ${'Validate'}          | ${true}
      ${'in-progress'} | ${DAST_SITE_VALIDATION_STATUS.INPROGRESS} | ${'Validating...'}     | ${'Validate'}          | ${true}
      ${'passed'}      | ${DAST_SITE_VALIDATION_STATUS.PASSED}     | ${'Validated'}         | ${'Revoke validation'} | ${false}
      ${'failed'}      | ${DAST_SITE_VALIDATION_STATUS.FAILED}     | ${'Validation failed'} | ${'Retry validation'}  | ${false}
    `(
      'profile with $status validation',
      ({ statusEnum, statusLabel, buttonLabel, isBtnDisabled }) => {
        const profile = siteProfiles.find(
          ({ validationStatus }) => validationStatus === statusEnum,
        );

        it(`should have correct status label`, () => {
          const validationStatusCell = getTableRowForProfile(profile).cells[2];
          expect(validationStatusCell.innerText).toContain(statusLabel);
        });

        it('show have correct button label', () => {
          const actionsCell = getTableRowForProfile(profile).cells[3];
          const validateButton = within(actionsCell).queryByRole('button', {
            name: buttonLabel,
          });
          expect(validateButton).not.toBe(null);
        });

        it(`should ${isBtnDisabled ? '' : 'not '}disable ${buttonLabel} button`, () => {
          const actionsCell = getTableRowForProfile(profile).cells[3];
          const validateButton = within(actionsCell).queryByRole('button', {
            name: buttonLabel,
          });

          expect(validateButton.hasAttribute('disabled')).toBe(isBtnDisabled);
        });
      },
    );

    describe('Actions', () => {
      beforeEach(() => {
        jest.clearAllMocks();
      });

      const VALIDATE_BUTTON_COL_INDEX = 3;

      it('validate button should open correct modal', async () => {
        expect(findDastSiteValidationModal().exists()).toBe(false);
        const profile = siteProfiles.find(
          ({ validationStatus }) => validationStatus === DAST_SITE_VALIDATION_STATUS.NONE,
        );

        const rowIndex = siteProfiles.indexOf(profile);
        getCell(rowIndex, VALIDATE_BUTTON_COL_INDEX).findComponent(GlButton).vm.$emit('click');
        await nextTick();

        expect(findDastSiteValidationModal().exists()).toBe(true);
      });

      it('revoke validation button should open correct modal', async () => {
        expect(findDastSiteValidationRevokeModal().exists()).toBe(false);
        const profile = siteProfiles.find(
          ({ validationStatus }) => validationStatus === DAST_SITE_VALIDATION_STATUS.PASSED,
        );

        const rowIndex = siteProfiles.indexOf(profile);
        getCell(rowIndex, VALIDATE_BUTTON_COL_INDEX).findComponent(GlButton).vm.$emit('click');
        await nextTick();

        expect(findDastSiteValidationRevokeModal().exists()).toBe(true);
      });
    });

    it('fetches validation statuses for all profiles that are being validated and updates the cache', async () => {
      await waitForPromises();

      expect(requestHandlers.dastSiteValidations).toHaveBeenCalledWith({
        fullPath: defaultProps.fullPath,
        urls: urlsPendingValidation,
      });
      expect(updateSiteProfilesStatuses).toHaveBeenCalledTimes(2);
    });

    it.each`
      nthCall | normalizedTargetUrl                         | status
      ${1}    | ${pendingValidation.normalizedTargetUrl}    | ${DAST_SITE_VALIDATION_STATUS.FAILED}
      ${2}    | ${inProgressValidation.normalizedTargetUrl} | ${DAST_SITE_VALIDATION_STATUS.PASSED}
    `(
      'in the local cache, profile with normalized URL $normalizedTargetUrl has its status set to $status',
      async ({ nthCall, normalizedTargetUrl, status }) => {
        await waitForPromises();

        expect(updateSiteProfilesStatuses).toHaveBeenNthCalledWith(nthCall, {
          fullPath: defaultProps.fullPath,
          normalizedTargetUrl,
          status,
          store: apolloProvider.defaultClient,
        });
      },
    );
  });

  describe('site validation stuck validation', () => {
    describe.each`
      timeElapsedMin | statusEnum                                | statusLabel            | buttonLabel           | isBtnDisabled
      ${30}          | ${DAST_SITE_VALIDATION_STATUS.PENDING}    | ${'Validating...'}     | ${'Validate'}         | ${true}
      ${62}          | ${DAST_SITE_VALIDATION_STATUS.PENDING}    | ${'Validation failed'} | ${'Retry validation'} | ${false}
      ${null}        | ${DAST_SITE_VALIDATION_STATUS.PENDING}    | ${'Validating...'}     | ${'Validate'}         | ${true}
      ${null}        | ${DAST_SITE_VALIDATION_STATUS.PENDING}    | ${'Validating...'}     | ${'Validate'}         | ${true}
      ${30}          | ${DAST_SITE_VALIDATION_STATUS.INPROGRESS} | ${'Validating...'}     | ${'Validate'}         | ${true}
      ${62}          | ${DAST_SITE_VALIDATION_STATUS.INPROGRESS} | ${'Validation failed'} | ${'Retry validation'} | ${false}
      ${30}          | ${DAST_SITE_VALIDATION_STATUS.PASSED}     | ${'Validated'}         | ${'Validate'}         | ${true}
      ${62}          | ${DAST_SITE_VALIDATION_STATUS.PASSED}     | ${'Validated'}         | ${'Validate'}         | ${true}
    `(
      'profile with $statusEnum validation',
      ({ timeElapsedMin, statusEnum, statusLabel, buttonLabel, isBtnDisabled }) => {
        const siteProfilesCopy = [...siteProfiles];

        it(`should have correct status label`, async () => {
          /**
           * Set up time difference nad mock Date.now()
           */
          const dateNowMock = jest
            .spyOn(Date, 'now')
            .mockImplementation(() => new Date('2022-10-31T15:47:21Z').getTime());
          const validationStartedAt = new Date(dateNowMock() - 1000 * 60 * timeElapsedMin);

          const siteProfile = siteProfilesCopy[0];
          siteProfile.validationStartedAt = validationStartedAt;
          siteProfile.validationStatus = statusEnum;
          createFullComponent({ propsData: { profiles: siteProfilesCopy } });
          await waitForPromises();
          const validationStatusCell = getTableRowForProfile(siteProfile).cells[2];

          expect(validationStatusCell.innerText).toContain(statusLabel);
          expect(findSetProfileButtons().at(0).text()).toBe(buttonLabel);
          expect(findSetProfileButtons().at(0).props('disabled')).toBe(isBtnDisabled);
        });
      },
    );
  });
});
