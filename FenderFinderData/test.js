const request = require('supertest');
const app = require('./server');
const chaiHttp = require('chai-http');
const chai = require('chai');
const expect = chai.expect;
const sinon = require('sinon');
// const { _, db } = require('./firebase');
const crashReportController = require('./crashReportController');

describe('POST /reportCrash', function() {
  it('responds with json and status 200 when passed valid data', function(done) {
    request(app)
      .post('/reportCrash')
      .send({ latitude: 40.7128, longitude: -74.0060, userReport: 'Test crash report' })
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(200)
      .end(function(err, res) {
        if (err) return done(err);
        expect(res.body).to.be.an('object');
        done();
      });
  });

  it('responds with status 422 when passed invalid data', function(done) {
    request(app)
      .post('/reportCrash')
      .send({ latitude: 'not-a-latitude', longitude: -74.0060, userReport: 'Test crash report' })
      .set('Accept', 'application/json')
      .expect(422, done);
  });
});

chai.use(chaiHttp);
describe('Crash Report Tests', () => {
  afterEach(() => {
    sinon.restore();
  });

  // Success Case
  it('should return 200 and a success message for a valid crash report', (done) => {
    const report = {
      latitude: 40.7128,
      longitude: -74.0060,
      userReport: 'Crash observed'
    };

    chai.request(app)
        .post('/reportCrash')
        .send(report)
        .end((err, res) => {
        expect(res).to.have.status(200);
        expect(res.body.message).to.include('Report added with ID:'); // Check that the message includes this string
        done();
        });
  });

  // Client Error Cases
  it('should return 422 when required fields are missing', (done) => {
    const report = {
      latitude: 40.7128,
      // longitude is missing
      userReport: 'Crash observed'
    };

    chai.request(app)
      .post('/reportCrash')
      .send(report)
      .end((err, res) => {
        expect(res).to.have.status(422);
        done();
      });
  });

  // Server Error Case
  it('should return 500 if there is a server error', (done) => {
    // Stub the database method that's called by the endpoint to throw an error
    // sinon.stub(db, 'addCrashReport').callsFake(() => {
    //     throw new Error('Database error');
    // });
    afterEach(() => {
        sinon.restore(); // This will restore all stubs
    });

    let stub = sinon.stub(crashReportController, 'addCrashReport').callsFake((req, res) => {
        return res.status(500).json({ error: 'Fake server error' });
    });

    const report = {
      latitude: 40.7128,
      longitude: -74.0060,
      userReport: 'Crash observed'
    };

    chai.request(app)
      .post('/reportCrash')
      .send(report)
      .end((err, res) => {
        expect(res).to.have.status(500);
        expect(res.body).to.have.property('error').eql('Internal Server Error');

        // Check that the stub was called
        sinon.assert.calledOnce(stub);
        done();
    });
  });
});