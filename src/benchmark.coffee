Table           = require 'cli-table'
SecondaryCache  = require 'secondary-cache'
LRUCache        = require 'lru-cache'
SimpleCache     = require 'simple-lru-cache'

random = Math.random
maxCap = 10000

benchmark = (run)->
  start = process.hrtime()
  sm = process.memoryUsage()
  run()
  diff = process.hrtime(start)
  em = process.memoryUsage()
  usedMem = em.rss - sm.rss
  heapTotal = em.heapTotal - sm.heapTotal
  heapUsed = em.heapUsed - sm.heapUsed
  ###
  console.log("Memory Used: " + (usedMem / 1024) + "KB")
  console.log("Heap Total: " + (heapTotal / 1024) + "KB")
  console.log("Heap Used: " + (heapUsed / 1024) + "KB")
  console.log("Time Cost: " + (diff[0]*1e3+diff[1] / 1e6) + " ms\n")
  ###
  memory: (usedMem / 1024 / 1024)
  heapTotal: (heapTotal / 1024 / 1024)
  heapUsed: (heapUsed / 1024 / 1024)
  time: (diff[0]*1e3+diff[1] / 1e6)


runBenchmark = (name, cache)->
  name: name
  add: benchmark ->
    for i in [0...maxCap]
      cache.set('test' + i, random())
    return
  update: benchmark ->
    for i in [0...maxCap]
      cache.set('test' + i, random())
    return
  get: benchmark ->
    for i in [0...maxCap]
      cache.get('test' + i)
    return

  del: benchmark ->
    for i in [0...maxCap]
      cache.del('test' + i)
    return

  clear: benchmark ->
    cache.clear()
    return

FixedCacheWrapper = (cache) ->
  cache.set = cache.__proto__.setFixed
  cache

LRUCacheWrapper = (cache) ->
  cache.clear = cache.__proto__.reset
  cache

lruCache = runBenchmark "lru-cache", LRUCacheWrapper(LRUCache(maxCap))
simpleCache = runBenchmark "simple-lru-cache", LRUCacheWrapper(new SimpleCache maxSize: maxCap)
sFixedCache = runBenchmark "Fixed Cache(seconday)", FixedCacheWrapper(SecondaryCache())
sLruCache = runBenchmark "LRU Cache(seconday)", SecondaryCache(maxCap)

allCaches = [sFixedCache, sLruCache, lruCache, simpleCache]
allTypes  = ['add', 'update', 'get', 'del', 'clear']

toArray = (item, type)->
  for i in allTypes
    item[i][type].toFixed(3)
toColumn = (cache, type)->
  result={}
  result[cache.name] = toArray(cache, type)
  result

toTable = (typeName, type, style)->
  style = 
    head:['blue']
    borader: ['grey'] if not style
  head = allTypes.slice()
  head.splice 0, 0, typeName
  result = new Table
    head: head
    style: style
  for i in allCaches
    result.push toColumn i, type
  result

table = toTable "Heap Total(MB)", "heapTotal"
console.log(table.toString())
table = toTable "Heap Used(MB)", "heapUsed"
console.log(table.toString())
table = toTable "Memory Used(MB)", "memory"
console.log(table.toString())

table = toTable "Time Cost(ms)", "time"
console.log(table.toString())

