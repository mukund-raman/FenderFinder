const { admin, db } = require('./firebase');
const { body, validationResult } = require('express-validator');
const { GeoFirestore } = require('geofirestore');

// Create a GeoFirestore reference
const geofirestore = new GeoFirestore(db);
const crashReports = geofirestore.collection('crashReports');

exports.validate = (method) => {
  switch (method) {
    case 'addCrashReport': {
      return [
        body('latitude', 'Invalid latitude').exists().isFloat({ min: -90, max: 90 }),
        body('longitude', 'Invalid longitude').exists().isFloat({ min: -180, max: 180 }),
        body('userReport', 'Invalid user report').exists().isString()
      ];
    }
  }
};

exports.addCrashReport = (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  const { latitude, longitude, userReport } = req.body;

  crashReports.add({
    coordinates: new admin.firestore.GeoPoint(latitude, longitude),
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    userReport: userReport
  })
  .then(docRef => res.status(200).json({ message: `Report added with ID: ${docRef.id}` }))
  .catch(error => {
    console.error("Error adding report:", error); // Log the error to the console
    res.status(500).json({ error: `Error adding report: ${error.message}` }); // Include the error message in the response
  });
};

exports.getNearbyCrashReports = (req, res) => {
  const { latitude, longitude, radius } = req.query;

  crashReports.near({ center: new db.GeoPoint(latitude, longitude), radius: radius })
    .get()
    .then((snapshot) => {
      let nearbyReports = [];
      snapshot.forEach((doc) => {
        nearbyReports.push(doc.data());
      });
      res.status(200).json(nearbyReports);
    })
    .catch(error => res.status(500).json({ error: `Error getting nearby crashes: ${error}` }));
};