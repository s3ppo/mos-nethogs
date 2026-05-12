export default {
  name: 'mos-wifi',
  displayName: 'WiFi Treiber für MOS',
  description: 'Installiert WiFi-Firmware und Treiber im MOS-Container',
  version: '0.0.1',
  icon: 'https://raw.githubusercontent.com/s3ppo/mos_wifi/main/page/assets/wifi-icon.svg',
  category: ['Driver'],
  architecture: ['amd64'],
  driver: true,
  author: 's3ppo',
  homepage: 'https://github.com/s3ppo/mos_wifi',
  repository: 'https://github.com/s3ppo/mos_wifi',
  support: 'https://github.com/s3ppo/mos_wifi/issues',
  commands: [
    {
      name: 'mos-wifi-driver-install',
      executable: '/usr/bin/plugins/mos-wifi-driver-install',
      description: 'Installiere WiFi-Treiber und Firmware',
    },
  ],
};
