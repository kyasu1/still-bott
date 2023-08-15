import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";
import replace from "@rollup/plugin-replace";

console.log(process.env.CLIENT_ENDPOINT);

export default defineConfig({
  server: {
    port: 3001,
    host: "127.0.0.1",
  },
  plugins: [
    elmPlugin({ debug: true }),
    replace({
      preventAssignment: true,
      // 'process.env.NODE_ENV': JSON.stringify('production'),
      // __buildDate__: () => JSON.stringify(new Date()),
      __HASURA_ENDPOINT__: process.env.HASURA_ENDPOINT,
      __BACKEND_ENDPOINT__: process.env.BACKEND_ENDPOINT,
    }),
  ],
});
