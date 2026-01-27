module.exports = {
  apps: [
    {
      name: "aptigo-backend",
      // Option 1: Run compiled binary (Recommended for Production)
      // command: "./server",

      // Option 2: Run with Dart VM (Easier for development/testing on VPS)
      script: "dart",
      args: "run bin/server.dart",

      cwd: ".", // Run from the current directory (where ecosystem.config.js is)
      watch: false, // Set to true if you want auto-restart on file changes
      env: {
        APP_ENV: "production",
        // PORT: 8080 // You can override port if needed
      },
    },
  ],
};
