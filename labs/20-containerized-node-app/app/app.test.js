import test from 'node:test'
import assert from 'node:assert'
import { buildApp } from './app.js'

test('GET /health repond 200 avec {ok:true}', async () => {
  const app = await buildApp()
  const response = await app.inject({ method: 'GET', url: '/health' })
  assert.strictEqual(response.statusCode, 200)
  assert.deepStrictEqual(response.json(), { ok: true })
  await app.close()
})

test('POST /quotes avec un texte vide redirige vers /', async () => {
  const app = await buildApp()
  const response = await app.inject({
    method: 'POST',
    url: '/quotes',
    payload: 'author=test&text=',
    headers: { 'content-type': 'application/x-www-form-urlencoded' }
  })
  assert.strictEqual(response.statusCode, 302)
  assert.strictEqual(response.headers.location, '/')
  await app.close()
})
