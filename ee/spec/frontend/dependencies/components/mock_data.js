export const containerImagePath = {
  ancestors: null,
  top_level: null,
  blob_path: 'test.link',
  path: 'container-image:nginx:1.17',
  image: 'nginx:1.17',
};

export const longPath = {
  ancestors: [
    {
      name: 'swell',
      version: '1.2',
    },
    {
      name: 'emmajsq',
      version: '10.11',
    },
    {
      name: 'zeb',
      version: '12.1',
    },
    {
      name: 'post',
      version: '2.5',
    },
    {
      name: 'core',
      version: '1.0',
    },
  ],
  top_level: false,
  blob_path: 'test.link',
  path: 'package.json',
};

export const shortPath = {
  ancestors: [
    {
      name: 'swell',
      version: '1.2',
    },
    {
      name: 'emmajsq',
      version: '10.11',
    },
  ],
  top_level: false,
  blob_path: 'test.link',
  path: 'package.json',
};

export const noPath = {
  ancestors: [],
  top_level: false,
  blob_path: 'test.link',
  path: 'package.json',
};

export const topLevelPath = {
  ancestors: [],
  top_level: true,
  blob_path: 'test.link',
  path: 'package.json',
};
