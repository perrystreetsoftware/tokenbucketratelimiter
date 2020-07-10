# TokenBucketRateLimiter

This package implements a token bucket rate limiter, as originally described at http://code.activestate.com/recipes/511490-implementation-of-the-token-bucket-algorithm/

A token bucket rate limiter is discussed at: https://en.wikipedia.org/wiki/Token_bucket

Also: https://medium.com/smyte/rate-limiter-df3408325846

The industry standard algorithm for rate limiting is called a token bucket, sometimes called a “leaky bucket”. Each bucket has a string key and initially contains the maximum number of tokens. Every time an event occurs, you check if the bucket contains enough tokens and reduce the number of tokens in the bucket by the requested amount. After a period of time called the refill time, the number of tokens in the bucket is increased by the refill amount. Over time, these refills will fill up the bucket to the maximum number of tokens.

