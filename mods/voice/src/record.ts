import Verb from './verb'
import events from './events'

const objectid = require('objectid')

interface RecordOptions {
  beep?: boolean
  maxDuration?: number
  finishOnKey?: string
  offset?: number
  format?: string
}

const validateMaxDuration = (maxDuration: number) => {
  if (maxDuration && maxDuration < 1)
    throw `${maxDuration} is not an acceptable maxDuration value. Must be a number greater than 1. Default is 3600 (1 hour)`
}

const validateBeep = (beep: boolean) => {
  if (beep && typeof beep !== 'boolean')
    throw `${beep} is not an acceptable value. Must be a true or false`
}

class Record extends Verb {
  constructor (channel: any, config: any) {
    super(channel, config)
  }

  private getFileURLWhenReady (name: string, bucket: string): string {
    const sleep = require('sync').sleep
    let cnt = 40 // 40 * 100 is 4 seconds
    while (true) {
      try {
        const result = this.config.storage.getObjectURLSync({ name, bucket })
        return result
      } catch (e) {
        if (cnt <= 0) return
        sleep(100)
        cnt--
      }
    }
  }

  run (callDetailRecord: any, options: RecordOptions = {}) {
    let {
      beep = true,
      maxDuration = 3600,
      finishOnKey = '1234567890#*',
      offset = 0,
      format = 'wav'
    } = options
    validateMaxDuration(maxDuration)
    validateBeep(beep)

    const filename = objectid()
    const res = this.channel.recordFile(
      `/tmp/${filename}`,
      format,
      finishOnKey,
      maxDuration * 1000,
      offset,
      beep
    )

    if (res.code !== 200) throw new Error(res.rawReply)

    events.sendToQ('RECORDING_CREATED', {
      filename: `${filename}.${format}`
    })

    const recordingUri = this.getFileURLWhenReady(
      `${filename}.${format}`,
      this.config.bucket
    )

    return {
      keyPressed: res.attributes.result,
      recordingUri,
      filename,
      format,
      callRef: callDetailRecord.ref
    }
  }
}

export { Record as default, RecordOptions }
