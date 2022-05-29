import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import actions from '~/vue_merge_request_widget/components/extensions/actions.vue';
import licenseComplianceExtension from 'ee/vue_merge_request_widget/extensions/license_compliance';
import httpStatusCodes from '~/lib/utils/http_status';
import {
  licenseComplianceNewLicenses,
  licenseComplianceSuccessExpanded,
  licenseComplianceRemovedLicenses,
  licenseComplianceNewAndRemovedLicenses,
  licenseComplianceNewDeniedLicenses,
  licenseComplianceNewDeniedLicensesAndExisting,
  licenseComplianceNewAndRemovedLicensesApprovalRequired,
  licenseComplianceNewDeniedLicensesAndExistingApprovalRequired,
  licenseComplianceEmpty,
  licenseComplianceEmptyExistingLicense,
  licenseComplianceExistingAndNewLicenses,
} from './mock_data';

describe('License Compliance extension', () => {
  let wrapper;
  let mock;

  registerExtension(licenseComplianceExtension);

  const licenseComparisonPath =
    '/group-name/project-name/-/merge_requests/78/license_scanning_reports';
  const licenseComparisonPathCollapsed =
    '/group-name/project-name/-/merge_requests/78/license_scanning_reports_collapsed';
  const fullReportPath = '/group-name/project-name/-/merge_requests/78/full_report';
  const settingsPath = '/group-name/project-name/-/licenses#licenses';
  const apiApprovalsPath = '/group-name/project-name/-/licenses#policies';

  const mockApi = (endpoint, statusCode, data) => {
    mock.onGet(endpoint).reply(statusCode, data);
  };

  const findToggleCollapsedButton = () => wrapper.findByTestId('toggle-button');
  const findAllExtensionListItems = () => wrapper.findAllByTestId('extension-list-item');
  const findActionButtons = () => wrapper.findComponent(actions);
  const findByHrefAttribute = (href) => wrapper.find(`[href="${href}"]`);
  const findLicenseScanningReport = () => findByHrefAttribute(settingsPath);
  const findFullReport = () => findByHrefAttribute(fullReportPath);
  const findSummary = () => wrapper.findByTestId('widget-extension-top-level-summary');

  const createComponent = () => {
    wrapper = mountExtended(extensionsContainer, {
      propsData: {
        mr: {
          licenseCompliance: {
            license_scanning_comparison_path: licenseComparisonPath,
            license_scanning_comparison_collapsed_path: licenseComparisonPathCollapsed,
            api_approvals_path: apiApprovalsPath,
            license_scanning: {
              settings_path: settingsPath,
              full_report_path: fullReportPath,
            },
          },
        },
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('summary', () => {
    it('displays loading text', () => {
      mockApi(licenseComparisonPathCollapsed, httpStatusCodes.OK, licenseComplianceNewLicenses);

      createComponent();

      expect(findSummary().text()).toBe('License Compliance test metrics results are being parsed');
    });

    it('displays failed loading text', async () => {
      mockApi(licenseComparisonPathCollapsed, httpStatusCodes.INTERNAL_SERVER_ERROR);

      createComponent();

      await waitForPromises();
      expect(findSummary().text()).toBe('License Compliance failed loading results');
    });

    it.each`
      scenario                                                            | response                                                         | isExpandable | message
      ${'licenseComplianceEmpty'}                                         | ${licenseComplianceEmpty}                                        | ${false}     | ${'License Compliance detected no licenses for the source branch only'}
      ${'licenseComplianceEmptyExistingLicense'}                          | ${licenseComplianceEmptyExistingLicense}                         | ${false}     | ${'License Compliance detected no new licenses'}
      ${'licenseComplianceNewLicenses'}                                   | ${licenseComplianceNewLicenses}                                  | ${true}      | ${'License Compliance detected 4 licenses for the source branch only'}
      ${'licenseComplianceRemovedLicenses'}                               | ${licenseComplianceRemovedLicenses}                              | ${false}     | ${'License Compliance detected no licenses for the source branch only'}
      ${'licenseComplianceNewAndRemovedLicenses'}                         | ${licenseComplianceNewAndRemovedLicenses}                        | ${true}      | ${'License Compliance detected 2 licenses for the source branch only'}
      ${'licenseComplianceNewAndRemovedLicensesApprovalRequired'}         | ${licenseComplianceNewAndRemovedLicensesApprovalRequired}        | ${true}      | ${'License Compliance detected 4 licenses and policy violations for the source branch only; approval required'}
      ${'licenseComplianceNewDeniedLicenses'}                             | ${licenseComplianceNewDeniedLicenses}                            | ${true}      | ${'License Compliance detected 4 licenses and policy violations for the source branch only'}
      ${'licenseComplianceNewDeniedLicensesAndExisting'}                  | ${licenseComplianceNewDeniedLicensesAndExisting}                 | ${true}      | ${'License Compliance detected 4 new licenses and policy violations'}
      ${'licenseComplianceNewDeniedLicensesAndExistingApprovalRequired '} | ${licenseComplianceNewDeniedLicensesAndExistingApprovalRequired} | ${true}      | ${'License Compliance detected 4 new licenses and policy violations; approval required'}
      ${'licenseComplianceExistingAndNewLicenses'}                        | ${licenseComplianceExistingAndNewLicenses}                       | ${true}      | ${'License Compliance detected 6 new licenses'}
    `(
      'the $scenario scenario expects the message to be "$message"',
      async ({ response, message, isExpandable }) => {
        mockApi(licenseComparisonPathCollapsed, httpStatusCodes.OK, response);
        createComponent();

        await waitForPromises();

        expect(findSummary().text()).toBe(message);
        expect(findToggleCollapsedButton().exists()).toBe(isExpandable);
      },
    );
  });

  describe('actions buttons', () => {
    it('displays manage licenses and full report links', async () => {
      mockApi(licenseComparisonPathCollapsed, httpStatusCodes.OK, licenseComplianceNewLicenses);

      createComponent();

      await waitForPromises();

      expect(findLicenseScanningReport().exists()).toBe(true);
      expect(findLicenseScanningReport().text()).toBe('Manage Licenses');

      expect(findFullReport().exists()).toBe(true);
      expect(findFullReport().text()).toBe('Full Report');

      expect(findActionButtons().exists()).toBe(true);
    });
  });

  describe('expanded data', () => {
    describe('with new licenses', () => {
      beforeEach(async () => {
        mockApi(licenseComparisonPathCollapsed, httpStatusCodes.OK, licenseComplianceNewLicenses);
        mockApi(licenseComparisonPath, httpStatusCodes.OK, licenseComplianceSuccessExpanded);

        createComponent();

        await waitForPromises();

        findToggleCollapsedButton().trigger('click');

        await waitForPromises();
      });

      it('displays denied licenses', async () => {
        expect(findAllExtensionListItems().at(0).element).toMatchSnapshot();
      });

      it('displays uncategorized licenses', async () => {
        expect(findAllExtensionListItems().at(1).element).toMatchSnapshot();
      });

      it('displays allowed licenses', async () => {
        expect(findAllExtensionListItems().at(2).element).toMatchSnapshot();
      });
    });
  });
});
