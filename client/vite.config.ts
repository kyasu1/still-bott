import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";
import replace from "@rollup/plugin-replace";

export default defineConfig({
  server: {
    port: 3001,
    host: "127.0.0.1",
  },
  build: {
    outDir: "../dist",
    emptyOutDir: true,
  },
  plugins: [
    elmPlugin({ debug: true }),
    replace({
      preventAssignment: true,
      // 'process.env.NODE_ENV': JSON.stringify('production'),
      __BUILD_DATE__: () => JSON.stringify(new Date()),
      __HASURA_ENDPOINT__: process.env.HASURA_GRAPHQL_ENDPOINT,
      __BACKEND_ENDPOINT__: process.env.BACKEND_ENDPOINT,
    }),
  ],
});
