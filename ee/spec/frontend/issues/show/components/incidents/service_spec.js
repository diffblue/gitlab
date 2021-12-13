import Api from 'ee/api';
import { getMetricImages, uploadMetricImage } from 'ee/issues/show/components/incidents/service';
import { fileList, fileListRaw } from './mock_data';

jest.mock('ee/api', () => ({
  fetchIssueMetricImages: jest.fn(),
  uploadIssueMetricImage: jest.fn(),
}));

describe('Incidents service', () => {
  it('fetches metric images', async () => {
    Api.fetchIssueMetricImages.mockResolvedValue({ data: fileListRaw });
    const result = await getMetricImages();

    expect(Api.fetchIssueMetricImages).toHaveBeenCalled();
    expect(result).toEqual(fileList);
  });

  it('uploads a metric image', async () => {
    Api.uploadIssueMetricImage.mockResolvedValue({ data: fileListRaw[0] });
    const result = await uploadMetricImage();

    expect(Api.uploadIssueMetricImage).toHaveBeenCalled();
    expect(result).toEqual(fileList[0]);
  });
});
