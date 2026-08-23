/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,

  // Голият адрес води на българската версия. Постоянно пренасочване, за да не
  // се раздвоява тежестта в търсачките между `/` и `/bg`.
  async redirects() {
    return [{ source: "/", destination: "/bg", permanent: true }];
  },
};

export default nextConfig;
