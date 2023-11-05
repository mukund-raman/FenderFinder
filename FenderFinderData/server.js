require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const crashReportController = require('./crashReportController');

const app = express();
const port = process.env.PORT || 3000;

app.use(bodyParser.json());

app.post('/reportCrash', crashReportController.validate('addCrashReport'), crashReportController.addCrashReport);

app.get('/nearbyCrashes', crashReportController.getNearbyCrashReports);

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

module.exports = app;