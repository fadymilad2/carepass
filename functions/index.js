const admin = require("firebase-admin");
admin.initializeApp();

Object.assign(exports,
  require("./src/account_deletion"),
  require("./src/ai"),
  require("./src/payments"),
  require("./src/expresspay"),
  require("./src/maps"),
  require("./src/notifications"),
  require("./src/health_checks"),
);
