/**
 * @author Pedro Sanders
 * @since v1
 *
 * Unit Test for the YAPSService class
 */
const logger = require('../dist/common/logger')
logger.transports.forEach(t => (t.silent = true))
const YAPSService = require('../dist/common/yaps_service')
const chai = require('chai')
const sinon = require('sinon')
const sinonChai = require('sinon-chai')
chai.use(sinonChai)
const expect = chai.expect
var sandbox = sinon.createSandbox()

describe('@yaps/core/service', () => {
  context('YAPSService constructor', () => {
    sinon.stub(require('path'), 'join').returns('/users/quijote/.yaps/access')

    it('should only have the default options', () => {
      const fs = sinon.stub(require('fs'), 'readFileSync').returns(
        JSON.stringify({
          accessKeyId: 'yaps',
          accessKeySecret: 'validjwtkey'
        })
      )
      const service = new YAPSService()
      expect(service.getOptions())
        .to.have.property('endpoint')
        .to.be.equal('localhost:50052')
      expect(service.getOptions())
        .to.have.property('bucket')
        .to.be.equal('default')
      expect(service.getOptions()).to.have.property('accessKeyId')
      fs.restore()
    })

    it('should merge defaultOptions with the ones in the access file', () => {
      const fs = sinon.stub(require('fs'), 'readFileSync').returns(
        JSON.stringify({
          endpoint: 'localhost:50051',
          accessKeyId: 'yaps',
          accessKeySecret: 'validjwtkey'
        })
      )
      const service = new YAPSService()
      expect(service.getOptions())
        .to.have.property('endpoint')
        .to.be.equal('localhost:50051')
      fs.restore()
    })

    it('should merge defaultOptions with the options parameter', () => {
      const fs = sinon.stub(require('fs'), 'readFileSync').returns(
        JSON.stringify({
          accessKeyId: 'yaps',
          accessKeySecret: 'validjwtkey'
        })
      )
      const service = new YAPSService(void 0, { endpoint: 'apiserver:50051' })
      expect(service.getOptions())
        .to.have.property('endpoint')
        .to.be.equal('apiserver:50051')
      fs.restore()
    })

    it('should merge defaultOptions with the options in ENV', () => {
      const fs = sinon.stub(require('fs'), 'readFileSync').returns(
        JSON.stringify({
          accessKeyId: 'yaps',
          accessKeySecret: 'validjwtkey'
        })
      )
      process.env.YAPS_ENDPOINT = 'apiserver:50053'
      const service = new YAPSService()
      expect(service.getOptions())
        .to.have.property('endpoint')
        .to.be.equal('apiserver:50053')
      fs.restore()
    })

    it('should merge throw and error inf no credentials are found', done => {
      const fs = sinon.stub(require('fs'), 'readFileSync').returns('{}')
      try {
        new YAPSService()
        done('not good')
      } catch (err) {
        expect(err.message).to.be.equal('Not valid credentials found')
        done()
      }
      fs.restore()
    })

    it('should fail if the access file is malformed', done => {
      sinon.stub(require('fs'), 'readFileSync').returns('{')
      try {
        new YAPSService()
        done('not good')
      } catch (err) {
        expect(err.message).to.be.equal(
          'Malformed access file found at: /users/quijote/.yaps/access'
        )
        done()
      }
    })
  })
})
