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
  icon: 'https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/network-topology.png',
  author: 'MOS Community',
  homepage: 'https://github.com/netoptimizer/nethogs',
  translations,
  commands: [
    {
      name: 'mos-nethogs-install',
      executable: '/usr/bin/plugins/mos-nethogs-install',
      description: 'Install Nethogs and network monitoring tools',
    },
  ],
};
