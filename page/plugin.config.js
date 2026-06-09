const translations = {
  en: {
    displayName: 'Nethogs Network Monitor',
    description: 'Real-time network traffic monitoring tool',
  },
  de: {
    displayName: 'Nethogs Netzwerk-Monitor',
    description: 'Echtzeit-Netzwerküberwachungstool',
  },
};

export default {
  name: 'mos-nethogs',
  displayName: translations.en.displayName,
  description: translations.en.description,
  version: '0.0.1',
  icon: 'https://github.com/s3ppo/mos-nethogs/blob/8cf7cbc90b50887fd084a5fb1e614a3256844edf/page/assets/hogs.jpg?raw=true',
  author: 'MOS Community',
  homepage: 'https://github.com/netoptimizer/nethogs',
  category: ['Network'],
  architecture: ['amd64'],
  repository: 'https://github.com/s3ppo/mos-nethogs',
  support: 'https://github.com/s3ppo/mos-nethogs/issues',
  translations,
  commands: [
    {
      name: 'mos-nethogs-install',
      executable: '/usr/bin/plugins/mos-nethogs-install',
      description: 'Install Nethogs and network monitoring tools',
    },
    {
      name: 'mos-nethogs-query',
      executable: '/usr/bin/plugins/mos-nethogs-query',
      description: 'Query active nethogs processes as JSON',
    },
  ],
};