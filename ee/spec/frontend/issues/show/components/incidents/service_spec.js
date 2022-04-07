import { fileList, fileListRaw } from 'jest/vue_shared/components/metric_images/mock_data';
import Api from 'ee/api';
import {
  getMetricImages,
  uploadMetricImage,
  updateMetricImage,
  deleteMetricImage,
} from 'ee/issues/show/components/incidents/service';

jest.mock('ee/api');

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

  it('updates a metric image', async () => {
    Api.updateIssueMetricImage.mockResolvedValue({ data: fileListRaw[0] });
    const result = await updateMetricImage();

    expect(Api.updateIssueMetricImage).toHaveBeenCalled();
    expect(result).toEqual(fileList[0]);
  });

  it('deletes a metric image', async () => {
    Api.deleteMetricImage.mockResolvedValue({ data: '' });
    const result = await deleteMetricImage();

    expect(Api.deleteMetricImage).toHaveBeenCalled();
    expect(result).toEqual({});
  });
});
