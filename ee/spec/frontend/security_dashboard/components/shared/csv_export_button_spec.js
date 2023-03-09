import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import CsvExportButton from 'ee/security_dashboard/components/shared/csv_export_button.vue';
import { TEST_HOST } from 'helpers/test_constants';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import downloader from '~/lib/utils/downloader';
import {
  HTTP_STATUS_ACCEPTED,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';

jest.mock('~/alert');
jest.mock('~/lib/utils/downloader');

const mockReportDate = formatDate(new Date(), 'isoDateTime');
const vulnerabilitiesExportEndpoint = `${TEST_HOST}/vulnerability_findings.csv`;

describe('Csv Button Export', () => {
  let mock;
  let wrapper;

  const findCsvExportButton = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    return shallowMount(CsvExportButton, {
      provide: {
        vulnerabilitiesExportEndpoint,
      },
    });
  };

  const mockCsvExportRequest = (download, status = 'finished') => {
    mock
      .onPost(vulnerabilitiesExportEndpoint)
      .reply(HTTP_STATUS_ACCEPTED, { _links: { self: 'status/url' } });

    mock.onGet('status/url').reply(HTTP_STATUS_OK, { _links: { download }, status });
  };

  describe('when the user sees the button for the first time', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
      wrapper = createComponent();
    });

    it('renders correctly', () => {
      expect(findCsvExportButton().text()).toBe('Export');
    });

    it('will start the download when clicked', async () => {
      const url = 'download/url';
      mockCsvExportRequest(url);

      findCsvExportButton().vm.$emit('click');
      await axios.waitForAll();

      expect(mock.history.post).toHaveLength(1); // POST is the create report endpoint.
      expect(mock.history.get).toHaveLength(1); // GET is the poll endpoint.
      expect(downloader).toHaveBeenCalledTimes(1);
      expect(downloader).toHaveBeenCalledWith({
        fileName: `csv-export-${mockReportDate}.csv`,
        url,
      });
    });

    it('shows the alert error when the export job status is failed', async () => {
      mockCsvExportRequest('', 'failed');

      findCsvExportButton().vm.$emit('click');
      await axios.waitForAll();

      expect(downloader).not.toHaveBeenCalled();
      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was an error while generating the report.',
      });
    });

    it('shows the alert error when backend fails to generate the export', async () => {
      mock.onPost(vulnerabilitiesExportEndpoint).reply(HTTP_STATUS_NOT_FOUND, {});

      findCsvExportButton().vm.$emit('click');
      await axios.waitForAll();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was an error while generating the report.',
      });
    });

    it('displays the export icon when not loading and the loading icon when loading', async () => {
      expect(findCsvExportButton().props()).toMatchObject({
        icon: 'export',
        loading: false,
      });

      findCsvExportButton().vm.$emit('click');
      await nextTick();

      expect(findCsvExportButton().props()).toMatchObject({
        icon: '',
        loading: true,
      });
    });
  });
});
