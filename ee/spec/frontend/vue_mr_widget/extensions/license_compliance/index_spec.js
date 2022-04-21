import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import licenseComplianceExtension from 'ee/vue_merge_request_widget/extensions/license_compliance';
import httpStatusCodes from '~/lib/utils/http_status';
import {
  licenseComplianceSuccess,
  licenseComplianceRemovedLicenses,
  licenseComplianceNewAndRemovedLicenses,
  licenseComplianceEmpty,
} from './mock_data';

describe('License Compliance extension', () => {
  let wrapper;
  let mock;

  registerExtension(licenseComplianceExtension);

  const endpoint = '/group-name/project-name/-/merge_requests/78/license_scanning_reports';

  const mockApi = (statusCode, data) => {
    mock.onGet(endpoint).reply(statusCode, data);
  };

  const findToggleCollapsedButton = () => wrapper.findByTestId('toggle-button');
  const findAllExtensionListItems = () => wrapper.findAllByTestId('extension-list-item');

  const createComponent = () => {
    wrapper = mountExtended(extensionsContainer, {
      propsData: {
        mr: {
          licenseCompliance: {
            license_scanning_comparison_path: endpoint,
            api_approvals_path: endpoint,
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
      mockApi(httpStatusCodes.OK, licenseComplianceSuccess);

      createComponent();

      expect(wrapper.text()).toBe('License Compliance test metrics results are being parsed');
    });

    it('displays failed loading text', async () => {
      mockApi(httpStatusCodes.INTERNAL_SERVER_ERROR);

      createComponent();

      await waitForPromises();
      expect(wrapper.text()).toBe('License Compliance failed loading results');
    });

    it('displays no licenses', async () => {
      mockApi(httpStatusCodes.OK, licenseComplianceEmpty);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('License Compliance detected no new licenses');
    });

    it('displays new licenses count', async () => {
      mockApi(httpStatusCodes.OK, licenseComplianceSuccess);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('License Compliance detected 3 new licenses');
    });

    it('displays removed licenses count', async () => {
      mockApi(httpStatusCodes.OK, licenseComplianceRemovedLicenses);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('License Compliance detected 3 removed licenses');
    });

    it('displays new and removed licenses count', async () => {
      mockApi(httpStatusCodes.OK, licenseComplianceNewAndRemovedLicenses);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe(
        'License Compliance detected 3 new licenses and 3 removed licenses',
      );
    });
  });

  describe('expanded data', () => {
    describe('with new licesnes', () => {
      beforeEach(async () => {
        mockApi(httpStatusCodes.OK, licenseComplianceSuccess);

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
